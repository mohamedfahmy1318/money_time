import AppIntents
import Flutter
import Foundation
import Security

// Bank-SMS capture on iPhone. Apps can't read SMS on iOS, so the user adds a
// Shortcuts automation ("When I get a message containing جنيه → Log Bank
// Message"). The App Intent below posts the text to `POST /bank-sync/ingest`
// with the narrow ingest token — usually without Flutter starting at all.
//
// Shortcuts can't filter on the alphanumeric sender ids banks use (only on
// phone numbers), so the automation matches on a word in the text and the
// intent does the sender check here: anything not from a linked bank never
// leaves the phone.

// MARK: - Store

/// The ingest token lives in the Keychain (readable after first unlock, so an
/// automation can run while the phone is locked; never synced to other
/// devices). Non-secret config — base URL, headers, linked senders — sits in
/// user defaults. Both are written by the app through the method channel.
enum BankCaptureStore {
  struct Config: Codable {
    var baseUrl: String
    var senders: [String]
    var deviceId: String
    var appVersion: String
    var language: String
  }

  private static let service = "money_time.bank_capture"
  private static let tokenAccount = "ingest_token"
  private static let configKey = "money_time.bank_capture.config"
  private static let needsTokenKey = "money_time.bank_capture.needs_token"
  private static let defaults = UserDefaults.standard

  static var config: Config? {
    get {
      guard let data = defaults.data(forKey: configKey) else { return nil }
      return try? JSONDecoder().decode(Config.self, from: data)
    }
    set {
      if let newValue, let data = try? JSONEncoder().encode(newValue) {
        defaults.set(data, forKey: configKey)
      } else {
        defaults.removeObject(forKey: configKey)
      }
    }
  }

  /// The server rejected the stored token; the app decides what to do.
  static var needsToken: Bool {
    get { defaults.bool(forKey: needsTokenKey) }
    set { defaults.set(newValue, forKey: needsTokenKey) }
  }

  /// Where the token lives: the Keychain on devices, memory in unit tests.
  static var tokenStore: BankTokenStore = KeychainTokenStore(service: service, account: tokenAccount)

  static var token: String? { tokenStore.read() }

  /// `false` when the Keychain refused the write — the app must not believe
  /// capture is armed then.
  @discardableResult
  static func saveToken(_ token: String) -> Bool { tokenStore.write(token) }

  static func clear() {
    tokenStore.delete()
    config = nil
    needsToken = false
    BankCaptureQueue.shared.clear()
  }

  /// `X-App-Version` as the Flutter side sends it (`version+buildNumber`),
  /// read at request time so an update is never reported with the version
  /// that connected (the server's minimum-version check would answer 426).
  static var appVersion: String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? ""
    let build = info?["CFBundleVersion"] as? String ?? ""
    return version.isEmpty ? "" : "\(version)+\(build)"
  }

  /// Exact, trimmed, case-insensitive — the same match the server applies.
  static func isLinkedSender(_ sender: String, senders: [String]? = nil) -> Bool {
    let needle = sender.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !needle.isEmpty else { return false }
    return (senders ?? config?.senders ?? []).contains {
      $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == needle
    }
  }

}

protocol BankTokenStore {
  func read() -> String?
  func write(_ token: String) -> Bool
  func delete()
}

/// A generic-password item, readable after first unlock, never synced.
struct KeychainTokenStore: BankTokenStore {
  let service: String
  let account: String

  /// The last `SecItemAdd` status, for diagnostics.
  nonisolated(unsafe) static var lastWriteStatus: OSStatus = errSecSuccess

  func read() -> String? {
    var query = baseQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data
    else { return nil }
    return String(data: data, encoding: .utf8)
  }

  func write(_ token: String) -> Bool {
    SecItemDelete(baseQuery as CFDictionary)
    var item = baseQuery
    item[kSecValueData as String] = Data(token.utf8)
    item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let status = SecItemAdd(item as CFDictionary, nil)
    Self.lastWriteStatus = status
    return status == errSecSuccess
  }

  func delete() { SecItemDelete(baseQuery as CFDictionary) }

  private var baseQuery: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }
}

/// Unit tests only: the simulator's test host has no Keychain entitlement.
final class MemoryTokenStore: BankTokenStore {
  private var token: String?
  func read() -> String? { token }
  func write(_ token: String) -> Bool { self.token = token; return true }
  func delete() { token = nil }
}

// MARK: - Queue

/// One captured message waiting for delivery, with its own Idempotency-Key.
struct QueuedBankMessage: Codable, Equatable {
  var key: String
  var sender: String
  var body: String
  var receivedAt: Date
}

/// Messages the intent could not deliver (offline, server down, token
/// revoked) wait here and go out on the next flush — from the next intent
/// run, or from the app when it opens. Bounded both ways: 500 items, 30 days.
/// Stored under Data Protection "complete until first unlock", like the token.
final class BankCaptureQueue {
  static let shared = BankCaptureQueue()

  static let maxItems = 500
  static let maxAge: TimeInterval = 30 * 24 * 60 * 60

  private let lock = NSLock()
  private let url: URL

  init(fileName: String = "bank_capture_queue.json") {
    let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
    url = support.appendingPathComponent(fileName)
  }

  func add(_ item: QueuedBankMessage) {
    lock.lock(); defer { lock.unlock() }
    var items = read()
    if !items.contains(where: { $0.key == item.key }) { items.append(item) }
    write(items)
  }

  func all() -> [QueuedBankMessage] {
    lock.lock(); defer { lock.unlock() }
    return read()
  }

  func remove(key: String) {
    lock.lock(); defer { lock.unlock() }
    write(read().filter { $0.key != key })
  }

  var count: Int { all().count }

  func clear() {
    lock.lock(); defer { lock.unlock() }
    try? FileManager.default.removeItem(at: url)
  }

  private func read() -> [QueuedBankMessage] {
    guard let data = try? Data(contentsOf: url),
      let items = try? JSONDecoder().decode([QueuedBankMessage].self, from: data)
    else { return [] }
    let oldest = Date().addingTimeInterval(-Self.maxAge)
    return items.filter { $0.receivedAt >= oldest }
  }

  private func write(_ items: [QueuedBankMessage]) {
    let kept = Array(items.suffix(Self.maxItems))
    guard let data = try? JSONEncoder().encode(kept) else { return }
    try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }
}

// MARK: - Method channel

/// `money_time/bank_capture`: the app arms, updates and clears capture here.
/// iOS has no SMS inbox access, so `readInbox` is always empty; `flush`
/// drains the queue of undelivered messages.
enum BankCaptureChannel {
  private static var channel: FlutterMethodChannel?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "money_time/bank_capture", binaryMessenger: messenger)
    self.channel = channel
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "configure":
        guard let token = args["ingestToken"] as? String, let baseUrl = args["baseUrl"] as? String
        else {
          result(FlutterError(code: "ARGS", message: "ingestToken and baseUrl are required", details: nil))
          return
        }
        guard BankCaptureStore.saveToken(token) else {
          result(FlutterError(code: "KEYSTORE_FAILED", message: "Keychain refused the token", details: nil))
          return
        }
        BankCaptureStore.config = .init(
          baseUrl: baseUrl.hasSuffix("/") ? String(baseUrl.dropLast()) : baseUrl,
          senders: args["senders"] as? [String] ?? [],
          deviceId: args["deviceId"] as? String ?? "",
          appVersion: BankCaptureStore.appVersion,
          language: args["language"] as? String ?? "ar")
        BankCaptureStore.needsToken = false
        // Anything held back by a revoked token goes out now.
        if BankCaptureQueue.shared.count > 0 { Task { await BankIngestClient.flush() } }
        result(nil)
      case "updateSenders":
        // Senders and UI language follow the app without a new token.
        if var config = BankCaptureStore.config {
          config.senders = args["senders"] as? [String] ?? []
          if let language = args["language"] as? String { config.language = language }
          BankCaptureStore.config = config
        }
        result(nil)
      case "clear":
        BankCaptureStore.clear()
        result(nil)
      case "flush":
        Task { await BankIngestClient.flush() }
        result(nil)
      case "status":
        result([
          "configured": BankCaptureStore.token != nil && BankCaptureStore.config != nil,
          "queued": BankCaptureQueue.shared.count,
          "needsToken": BankCaptureStore.needsToken,
        ])
      case "readInbox":
        result([])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Native → Dart, only while the app is running (the intent usually runs
  /// without it; then the app simply reloads on open).
  static func notifyCaptured() {
    DispatchQueue.main.async { channel?.invokeMethod("onCaptured", arguments: nil) }
  }

  static func notifyNeedsToken() {
    DispatchQueue.main.async { channel?.invokeMethod("onNeedsToken", arguments: nil) }
  }
}

// MARK: - Ingest

enum BankIngestError: Error, Equatable {
  case notConnected
  case tokenRevoked
  case rejected(String)
  case network

  func message(language: String) -> String {
    let arabic = language == "ar"
    switch self {
    case .notConnected:
      return arabic
        ? "افتح Money Time واربط بنكك أولًا."
        : "Open Money Time and connect your bank first."
    case .tokenRevoked:
      return arabic
        ? "افتح Money Time لتحديث ربط رسائل البنك."
        : "Open Money Time to refresh the bank-messages link."
    case .rejected(let serverMessage):
      return serverMessage
    case .network:
      return arabic
        ? "تعذّر الوصول إلى Money Time. تحقّق من الاتصال."
        : "Couldn't reach Money Time. Check your connection."
    }
  }
}

/// What one delivery attempt concluded.
enum BankIngestOutcome: Equatable {
  /// Stored (or already stored): forget the message.
  case delivered
  /// The server will never take this request: forget it, tell the user why.
  case dropped(String)
  /// Token revoked: keep the message, stop until the app re-issues it.
  case tokenRevoked
  /// No link any more: forget everything.
  case notConnected
  /// Unknown outcome (offline, 5xx, 429, timeout): keep the message.
  case retryLater
}

/// Posts messages to `POST /bank-sync/ingest`. One Idempotency-Key per
/// message, kept with it in the queue, so a retry is replayed, never stored
/// twice. The URLSession is injectable for tests.
enum BankIngestClient {
  static var session: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 8
    config.waitsForConnectivity = false
    return URLSession(configuration: config)
  }()

  /// Delivers [item] now, or queues it for later; throws only what the user
  /// should see in the Shortcuts banner.
  static func deliver(_ item: QueuedBankMessage) async throws {
    guard let config = BankCaptureStore.config, let token = BankCaptureStore.token
    else { throw BankIngestError.notConnected }
    if BankCaptureStore.needsToken {
      BankCaptureQueue.shared.add(item)
      throw BankIngestError.tokenRevoked
    }

    switch await post(item, config: config, token: token) {
    case .delivered:
      BankCaptureQueue.shared.remove(key: item.key)
      BankCaptureChannel.notifyCaptured()
      // Leftovers from an earlier outage ride along.
      if BankCaptureQueue.shared.count > 0 { await flush() }
    case .dropped(let message):
      BankCaptureQueue.shared.remove(key: item.key)
      throw BankIngestError.rejected(message)
    case .tokenRevoked:
      BankCaptureQueue.shared.add(item)
      BankCaptureStore.needsToken = true
      BankCaptureChannel.notifyNeedsToken()
      throw BankIngestError.tokenRevoked
    case .notConnected:
      BankCaptureStore.clear()
      throw BankIngestError.notConnected
    case .retryLater:
      // Not lost: the next intent run or app open sends it.
      BankCaptureQueue.shared.add(item)
    }
  }

  /// Sends what's queued, oldest first; stops at the first problem that a
  /// retry can't fix right now.
  static func flush() async {
    guard let config = BankCaptureStore.config, let token = BankCaptureStore.token,
      !BankCaptureStore.needsToken
    else { return }
    var delivered = 0
    for item in BankCaptureQueue.shared.all() {
      switch await post(item, config: config, token: token) {
      case .delivered:
        BankCaptureQueue.shared.remove(key: item.key)
        delivered += 1
      case .dropped:
        BankCaptureQueue.shared.remove(key: item.key)
      case .tokenRevoked:
        BankCaptureStore.needsToken = true
        BankCaptureChannel.notifyNeedsToken()
        if delivered > 0 { BankCaptureChannel.notifyCaptured() }
        return
      case .notConnected:
        BankCaptureStore.clear()
        return
      case .retryLater:
        if delivered > 0 { BankCaptureChannel.notifyCaptured() }
        return
      }
    }
    if delivered > 0 { BankCaptureChannel.notifyCaptured() }
  }

  /// One request, retried once on a timeout with the same key and body.
  static func post(_ item: QueuedBankMessage, config: BankCaptureStore.Config, token: String) async -> BankIngestOutcome {
    guard let url = URL(string: config.baseUrl + "/bank-sync/ingest") else { return .notConnected }
    let payload: [String: Any] = [
      "sender": item.sender,
      "body": item.body,
      "received_at": iso8601(item.receivedAt),
      "channel": "shortcut",
    ]
    guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return .dropped("Bad message") }

    var request = URLRequest(url: url, timeoutInterval: 8)
    request.httpMethod = "POST"
    request.httpBody = body
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(item.key, forHTTPHeaderField: "Idempotency-Key")
    request.setValue(config.language, forHTTPHeaderField: "Accept-Language")
    request.setValue("ios", forHTTPHeaderField: "X-Platform")
    request.setValue(BankCaptureStore.appVersion, forHTTPHeaderField: "X-App-Version")
    request.setValue(config.deviceId, forHTTPHeaderField: "X-Device-Id")

    for attempt in 1...2 {
      do {
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        return outcome(status: status, data: data)
      } catch let error as URLError where attempt == 1 && error.code == .timedOut {
        continue
      } catch {
        return .retryLater
      }
    }
    return .retryLater
  }

  /// The integration guide's table for `POST /bank-sync/ingest`.
  static func outcome(status: Int, data: Data) -> BankIngestOutcome {
    switch status {
    case 200..<300:
      return .delivered
    case 401:
      return .tokenRevoked
    case 409 where errorCode(data) == "NOT_CONNECTED":
      return .notConnected
    case 429, 500..<600:
      return .retryLater
    case 426:
      // Too old to talk to the server: keep the message for the updated app.
      return .retryLater
    default:
      // 400 / 409 mismatch / 413 / 422: resending the same request can't succeed.
      return .dropped(errorMessage(data) ?? "HTTP \(status)")
    }
  }

  static func iso8601(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter.string(from: date)
  }

  private static func envelope(_ data: Data) -> [String: Any]? {
    (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? [String: Any]
  }

  private static func errorCode(_ data: Data) -> String? { envelope(data)?["code"] as? String }

  private static func errorMessage(_ data: Data) -> String? { envelope(data)?["message"] as? String }
}

// MARK: - Routing

/// Which sender a run of the intent posts under, if any.
enum BankMessageRouting: Equatable {
  /// Post as this linked sender id.
  case send(sender: String)
  /// Not from a linked bank (a friend's text matched the keyword): stay quiet.
  case skip
  /// Neither the sender variable nor a bank was given.
  case unconfigured

  /// [sender] is what the automation passed from Shortcut Input (may be a
  /// phone number or empty); [bank] is the picker fallback. The sender,
  /// when given, decides alone: a friend's message is never attributed to
  /// the picked bank.
  static func resolve(sender: String?, bank: String?, linked: [String]) -> BankMessageRouting {
    let trimmedSender = sender?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !trimmedSender.isEmpty {
      return BankCaptureStore.isLinkedSender(trimmedSender, senders: linked) ? .send(sender: trimmedSender) : .skip
    }
    let trimmedBank = bank?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if trimmedBank.isEmpty { return .unconfigured }
    return .send(sender: trimmedBank)
  }

  /// The server's limit counts code points, not grapheme clusters.
  static func clipped(_ body: String) -> String {
    String(String.UnicodeScalarView(body.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars.prefix(2000)))
  }
}

// MARK: - App Intent

@available(iOS 16.0, *)
struct LogBankMessageIntent: AppIntent {
  static var title: LocalizedStringResource = "Log Bank Message"
  static var description = IntentDescription(
    "Sends a bank SMS to Money Time. In a Message automation: Message = Shortcut Input, Sender = Shortcut Input › Sender (or pick the Bank). Only messages from your linked banks are sent.")
  static var openAppWhenRun = false

  @Parameter(title: "Message", inputOptions: String.IntentInputOptions(multiline: true))
  var message: String

  @Parameter(title: "Sender", description: "From Shortcut Input › Sender. Messages from anyone but your linked banks are ignored.")
  var sender: String?

  @Parameter(title: "Bank", description: "Use when the automation can't pass the sender.", optionsProvider: BankSenderOptions())
  var bank: String?

  static var parameterSummary: some ParameterSummary {
    Summary("Log \(\.$message)") {
      \.$sender
      \.$bank
    }
  }

  func perform() async throws -> some IntentResult {
    let language = BankCaptureStore.config?.language ?? "ar"
    switch BankMessageRouting.resolve(sender: sender, bank: bank, linked: BankCaptureStore.config?.senders ?? []) {
    case .skip:
      return .result()
    case .unconfigured:
      throw LogBankMessageFailure(
        message: language == "ar"
          ? "اختر البنك أو مرّر المُرسِل من مُدخَل الاختصار."
          : "Pick the Bank or pass the Sender from Shortcut Input.")
    case .send(let resolved):
      let body = BankMessageRouting.clipped(message)
      guard !body.isEmpty else { return .result() }
      let item = QueuedBankMessage(key: UUID().uuidString, sender: resolved, body: body, receivedAt: Date())
      do {
        try await BankIngestClient.deliver(item)
        return .result()
      } catch let error as BankIngestError {
        throw LogBankMessageFailure(message: error.message(language: language))
      }
    }
  }
}

/// The linked banks' sender ids, as offered by the intent's "Bank" field.
@available(iOS 16.0, *)
struct BankSenderOptions: DynamicOptionsProvider {
  func results() async throws -> [String] {
    BankCaptureStore.config?.senders ?? []
  }
}

/// Shown by Shortcuts in its error banner.
@available(iOS 16.0, *)
struct LogBankMessageFailure: Error, CustomLocalizedStringResourceConvertible {
  let message: String

  var localizedStringResource: LocalizedStringResource {
    LocalizedStringResource(stringLiteral: message)
  }
}

@available(iOS 16.0, *)
struct MoneyTimeShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: LogBankMessageIntent(),
      phrases: ["Log a bank message in \(.applicationName)"])
  }
}
