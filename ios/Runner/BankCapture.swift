import AppIntents
import Flutter
import Foundation
import Security

// Bank-SMS capture on iPhone. Apps can't read SMS on iOS, so the user adds a
// Shortcuts automation ("When I get a message from CIB → Log Bank Message").
// The App Intent below posts the text to `POST /bank-sync/ingest` with the
// narrow ingest token — usually without Flutter starting at all.

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

  /// The server rejected the stored token; the app re-issues it on open.
  static var needsToken: Bool {
    get { defaults.bool(forKey: needsTokenKey) }
    set { defaults.set(newValue, forKey: needsTokenKey) }
  }

  static var token: String? {
    var query = baseQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data
    else { return nil }
    return String(data: data, encoding: .utf8)
  }

  /// `false` when the Keychain refused the write — the app must not believe
  /// capture is armed then.
  @discardableResult
  static func saveToken(_ token: String) -> Bool {
    SecItemDelete(baseQuery as CFDictionary)
    var item = baseQuery
    item[kSecValueData as String] = Data(token.utf8)
    item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
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

  static func clear() {
    SecItemDelete(baseQuery as CFDictionary)
    config = nil
    needsToken = false
  }

  private static var baseQuery: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: tokenAccount,
    ]
  }
}

// MARK: - Method channel

/// `money_time/bank_capture`: the app arms, updates and clears capture here.
/// iOS has no SMS inbox access, so `readInbox` is always empty.
enum BankCaptureChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "money_time/bank_capture", binaryMessenger: messenger)
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
        result(nil)
      case "status":
        result([
          "configured": BankCaptureStore.token != nil && BankCaptureStore.config != nil,
          "queued": 0,
          "needsToken": BankCaptureStore.needsToken,
        ])
      case "readInbox":
        result([])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

// MARK: - Ingest

enum BankIngestError: Error {
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

/// Posts one SMS. One Idempotency-Key per run; a timeout is retried once with
/// the same key and body, so a slow network never books a message twice.
enum BankIngestClient {
  static func send(sender: String, body: String) async throws {
    guard let config = BankCaptureStore.config, let token = BankCaptureStore.token,
      let url = URL(string: config.baseUrl + "/bank-sync/ingest")
    else { throw BankIngestError.notConnected }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = TimeZone(identifier: "UTC")
    let payload: [String: Any] = [
      "sender": sender.trimmingCharacters(in: .whitespacesAndNewlines),
      // The server's limit counts code points, not grapheme clusters.
      "body": String(String.UnicodeScalarView(body.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars.prefix(2000))),
      "received_at": formatter.string(from: Date()),
      "channel": "shortcut",
    ]

    var request = URLRequest(url: url, timeoutInterval: 8)
    request.httpMethod = "POST"
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
    request.setValue(config.language, forHTTPHeaderField: "Accept-Language")
    request.setValue("ios", forHTTPHeaderField: "X-Platform")
    request.setValue(BankCaptureStore.appVersion, forHTTPHeaderField: "X-App-Version")
    request.setValue(config.deviceId, forHTTPHeaderField: "X-Device-Id")

    for attempt in 1...2 {
      do {
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        try handle(status: status, data: data)
        return
      } catch let error as URLError where attempt == 1 && error.code == .timedOut {
        continue
      } catch is URLError {
        throw BankIngestError.network
      }
    }
  }

  private static func handle(status: Int, data: Data) throws {
    switch status {
    case 200..<300:
      return
    case 401:
      BankCaptureStore.needsToken = true
      throw BankIngestError.tokenRevoked
    case 409 where errorCode(data) == "NOT_CONNECTED":
      throw BankIngestError.notConnected
    case 500..<600:
      throw BankIngestError.network
    default:
      throw BankIngestError.rejected(errorMessage(data) ?? "HTTP \(status)")
    }
  }

  private static func envelope(_ data: Data) -> [String: Any]? {
    (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? [String: Any]
  }

  private static func errorCode(_ data: Data) -> String? { envelope(data)?["code"] as? String }

  private static func errorMessage(_ data: Data) -> String? { envelope(data)?["message"] as? String }
}

// MARK: - App Intent

@available(iOS 16.0, *)
struct LogBankMessageIntent: AppIntent {
  static var title: LocalizedStringResource = "Log Bank Message"
  static var description = IntentDescription(
    "Sends a bank SMS to Money Time. Use it in a Message automation: set Bank to the sender and Message to Shortcut Input.")
  static var openAppWhenRun = false

  @Parameter(title: "Bank", optionsProvider: BankSenderOptions())
  var sender: String

  @Parameter(title: "Message", inputOptions: String.IntentInputOptions(multiline: true))
  var message: String

  static var parameterSummary: some ParameterSummary {
    Summary("Log \(\.$message) from \(\.$sender)")
  }

  func perform() async throws -> some IntentResult {
    let language = BankCaptureStore.config?.language ?? "ar"
    do {
      try await BankIngestClient.send(sender: sender, body: message)
      return .result()
    } catch let error as BankIngestError {
      throw LogBankMessageFailure(message: error.message(language: language))
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
