import Flutter
import UIKit
import XCTest

@testable import Runner

/// Serves canned answers to `BankIngestClient` so every branch of the
/// integration guide's ingest table runs without a server.
final class StubURLProtocol: URLProtocol {
  struct Reply {
    var status: Int
    var body: String = "{}"
    var error: URLError.Code? = nil
  }

  nonisolated(unsafe) static var replies: [Reply] = []
  nonisolated(unsafe) static var requests: [URLRequest] = []

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    Self.requests.append(request)
    let reply = Self.replies.isEmpty ? Reply(status: 500) : Self.replies.removeFirst()
    if let code = reply.error {
      client?.urlProtocol(self, didFailWithError: URLError(code))
      return
    }
    let response = HTTPURLResponse(url: request.url!, statusCode: reply.status, httpVersion: nil, headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Data(reply.body.utf8))
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}

final class BankCaptureTests: XCTestCase {
  private let queue = BankCaptureQueue.shared

  override func setUp() {
    super.setUp()
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubURLProtocol.self]
    BankIngestClient.session = URLSession(configuration: config)
    StubURLProtocol.replies = []
    StubURLProtocol.requests = []
    BankCaptureStore.tokenStore = MemoryTokenStore()
    BankCaptureStore.clear()
    XCTAssertTrue(BankCaptureStore.saveToken("mti_test_token"))
    BankCaptureStore.config = .init(
      baseUrl: "https://example.test/v1", senders: ["CIB", "NBE", "BanK-AlAhly"],
      deviceId: "dev-1", appVersion: "", language: "ar")
  }

  override func tearDown() {
    BankCaptureStore.clear()
    super.tearDown()
  }

  private func message(_ body: String = "تم خصم مبلغ 64.50 جنيه", sender: String = "NBE") -> QueuedBankMessage {
    QueuedBankMessage(key: UUID().uuidString, sender: sender, body: body, receivedAt: Date())
  }

  // MARK: Store

  func testTokenRoundTripsThroughKeychainAndClearForgetsEverything() {
    XCTAssertEqual(BankCaptureStore.token, "mti_test_token")
    XCTAssertTrue(BankCaptureStore.isLinkedSender(" bank-alahly "))
    XCTAssertFalse(BankCaptureStore.isLinkedSender("+201001234567"))
    queue.add(message())
    BankCaptureStore.clear()
    XCTAssertNil(BankCaptureStore.token)
    XCTAssertNil(BankCaptureStore.config)
    XCTAssertEqual(queue.count, 0)
  }

  func testAppVersionIsReadFromTheBundleNotTheStoredConfig() {
    XCTAssertTrue(BankCaptureStore.appVersion.contains("+"))
  }

  func testKeychainStoreRoundTripsWhereTheHostIsEntitled() throws {
    let keychain = KeychainTokenStore(service: "money_time.bank_capture.tests", account: "t")
    keychain.delete()
    guard keychain.write("mti_keychain") else {
      throw XCTSkip("Keychain unavailable to the test host (status \(KeychainTokenStore.lastWriteStatus))")
    }
    XCTAssertEqual(keychain.read(), "mti_keychain")
    keychain.delete()
    XCTAssertNil(keychain.read())
  }

  // MARK: Queue

  func testQueueKeepsKeysUniqueBoundedAndFresh() {
    let item = message()
    queue.add(item)
    queue.add(item)
    XCTAssertEqual(queue.count, 1)
    var stale = message()
    stale.receivedAt = Date().addingTimeInterval(-BankCaptureQueue.maxAge - 60)
    queue.add(stale)
    XCTAssertEqual(queue.all().map(\.key), [item.key], "a 31-day-old message is purged")
    for _ in 0..<(BankCaptureQueue.maxItems + 5) { queue.add(message()) }
    XCTAssertEqual(queue.count, BankCaptureQueue.maxItems)
    queue.remove(key: item.key)
    XCTAssertFalse(queue.all().contains { $0.key == item.key })
  }

  // MARK: Routing

  func testSenderVariableDecidesAloneAndBankIsOnlyAFallback() {
    let linked = ["CIB", "BanK-AlAhly"]
    XCTAssertEqual(BankMessageRouting.resolve(sender: "BanK-AlAhly", bank: nil, linked: linked), .send(sender: "BanK-AlAhly"))
    XCTAssertEqual(BankMessageRouting.resolve(sender: "+201001234567", bank: "CIB", linked: linked), .skip,
                   "a friend's text that matched the keyword is never attributed to the picked bank")
    XCTAssertEqual(BankMessageRouting.resolve(sender: "", bank: "CIB", linked: linked), .send(sender: "CIB"))
    XCTAssertEqual(BankMessageRouting.resolve(sender: nil, bank: nil, linked: linked), .unconfigured)
    XCTAssertEqual(BankMessageRouting.clipped(String(repeating: "ي", count: 2500)).unicodeScalars.count, 2000)
  }

  // MARK: Ingest outcomes (the guide's table)

  func testOutcomeTableMatchesTheIntegrationGuide() {
    let notConnected = Data(#"{"error":{"code":"NOT_CONNECTED","message":"x"}}"#.utf8)
    let rejected = Data(#"{"error":{"code":"SENDER_NOT_LINKED","message":"البنك غير مربوط"}}"#.utf8)
    XCTAssertEqual(BankIngestClient.outcome(status: 202, data: Data()), .delivered)
    XCTAssertEqual(BankIngestClient.outcome(status: 401, data: Data()), .tokenRevoked)
    XCTAssertEqual(BankIngestClient.outcome(status: 409, data: notConnected), .notConnected)
    XCTAssertEqual(BankIngestClient.outcome(status: 422, data: rejected), .dropped("البنك غير مربوط"))
    XCTAssertEqual(BankIngestClient.outcome(status: 409, data: Data()), .dropped("HTTP 409"))
    XCTAssertEqual(BankIngestClient.outcome(status: 426, data: Data()), .retryLater)
    XCTAssertEqual(BankIngestClient.outcome(status: 429, data: Data()), .retryLater)
    XCTAssertEqual(BankIngestClient.outcome(status: 503, data: Data()), .retryLater)
  }

  func testDeliveredMessageSendsTheGuideHeadersAndBodyAndLeavesNothingQueued() async throws {
    StubURLProtocol.replies = [.init(status: 202, body: #"{"id":"1","status":"pending","duplicate":false}"#)]
    let item = message("Your CIB card was charged EGP 10", sender: "CIB")

    try await BankIngestClient.deliver(item)

    XCTAssertEqual(queue.count, 0)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.url?.absoluteString, "https://example.test/v1/bank-sync/ingest")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer mti_test_token")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Idempotency-Key"), item.key)
    XCTAssertEqual(request.value(forHTTPHeaderField: "X-Platform"), "ios")
    XCTAssertEqual(request.value(forHTTPHeaderField: "X-Device-Id"), "dev-1")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "ar")
    let body = try XCTUnwrap(request.httpBody ?? request.httpBodyStream.map { stream in
      stream.open(); defer { stream.close() }
      var data = Data(); var buffer = [UInt8](repeating: 0, count: 4096)
      while stream.hasBytesAvailable { let n = stream.read(&buffer, maxLength: buffer.count); if n <= 0 { break }; data.append(buffer, count: n) }
      return data
    })
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
    XCTAssertEqual(json["sender"] as? String, "CIB")
    XCTAssertEqual(json["channel"] as? String, "shortcut")
    XCTAssertTrue((json["received_at"] as? String ?? "").hasSuffix("Z"))
  }

  func testOfflineMessageIsQueuedWithoutAnErrorAndFlushedLater() async throws {
    StubURLProtocol.replies = [.init(status: 0, error: .notConnectedToInternet)]
    let item = message()

    try await BankIngestClient.deliver(item)
    XCTAssertEqual(queue.all().map(\.key), [item.key], "kept, not lost, and the automation shows no error")

    StubURLProtocol.replies = [.init(status: 202)]
    await BankIngestClient.flush()
    XCTAssertEqual(queue.count, 0)
    XCTAssertEqual(StubURLProtocol.requests.last?.value(forHTTPHeaderField: "Idempotency-Key"), item.key,
                   "the retry replays the same key")
  }

  func testTimeoutIsRetriedOnceWithTheSameKeyThenQueued() async throws {
    StubURLProtocol.replies = [.init(status: 0, error: .timedOut), .init(status: 0, error: .timedOut)]
    let item = message()

    try await BankIngestClient.deliver(item)

    XCTAssertEqual(StubURLProtocol.requests.count, 2)
    XCTAssertEqual(Set(StubURLProtocol.requests.compactMap { $0.value(forHTTPHeaderField: "Idempotency-Key") }), [item.key])
    XCTAssertEqual(queue.count, 1)
  }

  func testRevokedTokenKeepsTheMessageStopsSendingAndSurfacesAfterReissue() async throws {
    StubURLProtocol.replies = [.init(status: 401, body: #"{"error":{"code":"UNAUTHENTICATED","message":"x"}}"#)]
    let item = message()

    do {
      try await BankIngestClient.deliver(item)
      XCTFail("a revoked token must tell the user to open the app")
    } catch let error as BankIngestError {
      XCTAssertEqual(error, .tokenRevoked)
      XCTAssertTrue(error.message(language: "ar").contains("Money Time"))
    }
    XCTAssertTrue(BankCaptureStore.needsToken)
    XCTAssertEqual(queue.count, 1)

    // Nothing more goes out until the app re-issues the token…
    StubURLProtocol.replies = [.init(status: 202)]
    try? await BankIngestClient.deliver(message())
    XCTAssertEqual(StubURLProtocol.requests.count, 1)
    XCTAssertEqual(queue.count, 2)

    // …then the whole backlog drains.
    BankCaptureStore.needsToken = false
    StubURLProtocol.replies = [.init(status: 202), .init(status: 202)]
    await BankIngestClient.flush()
    XCTAssertEqual(queue.count, 0)
  }

  func testNotConnectedClearsEverythingAndRejectedDropsOnlyThatMessage() async throws {
    StubURLProtocol.replies = [.init(status: 409, body: #"{"error":{"code":"NOT_CONNECTED","message":"x"}}"#)]
    do {
      try await BankIngestClient.deliver(message())
      XCTFail()
    } catch let error as BankIngestError {
      XCTAssertEqual(error, .notConnected)
    }
    XCTAssertNil(BankCaptureStore.token)

    XCTAssertTrue(BankCaptureStore.saveToken("mti_again"))
    BankCaptureStore.config = .init(baseUrl: "https://example.test/v1", senders: ["CIB"], deviceId: "d", appVersion: "", language: "en")
    StubURLProtocol.replies = [.init(status: 422, body: #"{"error":{"code":"VALIDATION_FAILED","message":"Please check the highlighted fields."}}"#)]
    do {
      try await BankIngestClient.deliver(message())
      XCTFail()
    } catch let error as BankIngestError {
      XCTAssertEqual(error, .rejected("Please check the highlighted fields."))
    }
    XCTAssertEqual(queue.count, 0, "a request the server will never take is not kept")
  }

  func testFlushStopsAtTheFirstOutageAndKeepsTheRest() async {
    let first = message(); let second = message()
    queue.add(first); queue.add(second)
    StubURLProtocol.replies = [.init(status: 202), .init(status: 503)]

    await BankIngestClient.flush()

    XCTAssertEqual(queue.all().map(\.key), [second.key])
  }
}
