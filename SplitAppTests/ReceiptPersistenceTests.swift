import XCTest
@testable import SplitApp

@MainActor
final class ReceiptPersistenceTests: XCTestCase {
    func testImageRetryDoesNotCreateAnotherReceipt() async throws {
        let receiptID = UUID()
        let eventID = UUID()
        ReceiptCreationURLProtocol.reset()
        TokenStore.shared.save(token: "test-access-token", validFor: 3_600)
        defer {
            TokenStore.shared.clear()
            ReceiptCreationURLProtocol.reset()
        }

        ReceiptCreationURLProtocol.handler = { request in
            if request.url?.path == "/api/events/\(eventID.uuidString.lowercased())/receipts" {
                return Self.response(
                    request,
                    statusCode: 200,
                    body: Self.receiptJSON(id: receiptID, eventID: eventID)
                )
            }
            return Self.response(request, statusCode: 500, body: #"{"detail":"upload failed"}"#)
        }

        let repository = makeRepository()
        let command = CreateReceiptCommand(
            payerId: UUID(),
            title: "Ужин",
            totalAmount: 1_200,
            items: [],
            receiptImageJPEGData: Data([0xFF, 0xD8, 0xFF])
        )

        let outcome = try await repository.createReceipt(eventId: eventID, command)
        XCTAssertNotNil(outcome.imageUploadFailure)

        _ = try? await repository.uploadReceiptImage(
            receiptId: outcome.receipt.id,
            imageJPEGData: Data([0xFF, 0xD8, 0xFF])
        )

        let creates = ReceiptCreationURLProtocol.requests.filter {
            $0.url?.path == "/api/events/\(eventID.uuidString.lowercased())/receipts"
        }
        XCTAssertEqual(creates.count, 1)
    }

    func testCreateReceiptRequestPropagatesValidationFailure() async {
        let eventID = UUID()
        ReceiptCreationURLProtocol.reset()
        TokenStore.shared.save(token: "test-access-token", validFor: 3_600)
        defer {
            TokenStore.shared.clear()
            ReceiptCreationURLProtocol.reset()
        }
        ReceiptCreationURLProtocol.handler = { request in
            Self.response(request, statusCode: 422, body: #"{"detail":"invalid receipt"}"#)
        }
        let repository = makeRepository()

        do {
            _ = try await repository.createReceipt(
                eventId: eventID,
                CreateReceiptRequest(payerId: UUID(), title: "Ошибка", totalAmount: 100, items: [])
            )
            XCTFail("Validation failure must not create a local receipt")
        } catch NetworkError.httpError(let statusCode, _) {
            XCTAssertEqual(statusCode, 422)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateReceiptCommandReusesItsIdempotencyKey() async {
        let eventID = UUID()
        ReceiptCreationURLProtocol.reset()
        TokenStore.shared.save(token: "test-access-token", validFor: 3_600)
        defer {
            TokenStore.shared.clear()
            ReceiptCreationURLProtocol.reset()
        }
        ReceiptCreationURLProtocol.handler = { request in
            Self.response(request, statusCode: 500, body: #"{"detail":"temporary failure"}"#)
        }
        let repository = makeRepository()
        let command = CreateReceiptCommand(
            payerId: UUID(),
            title: "Ужин",
            totalAmount: 1_200,
            items: [],
            receiptImageJPEGData: nil
        )

        _ = try? await repository.createReceipt(eventId: eventID, command)
        _ = try? await repository.createReceipt(eventId: eventID, command)

        let keys = ReceiptCreationURLProtocol.requests.compactMap {
            $0.value(forHTTPHeaderField: "Idempotency-Key")
        }
        XCTAssertEqual(keys.count, 2)
        XCTAssertEqual(Set(keys).count, 1)
    }

    private func makeRepository() -> ReceiptsDataRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ReceiptCreationURLProtocol.self]
        return ReceiptsDataRepository(
            apiClient: APIClient(
                session: URLSession(configuration: configuration),
                secureStorage: ReceiptTestSecureStorage()
            ),
            coreDataStore: CoreDataStore(persistenceController: PersistenceController(inMemory: true))
        )
    }

    private static func receiptJSON(id: UUID, eventID: UUID) -> String {
        #"{"id":"\#(id.uuidString)","event_id":"\#(eventID.uuidString)","payer_id":"\#(UUID().uuidString)","title":"Ужин","total_amount_kopecks":120000,"created_at":"2026-07-13T00:00:00Z","updated_at":"2026-07-13T00:00:00Z","items":[]}"#
    }

    private static func response(_ request: URLRequest, statusCode: Int, body: String) -> (HTTPURLResponse, Data) {
        (
            HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!,
            Data(body.utf8)
        )
    }
}

private final class ReceiptCreationURLProtocol: URLProtocol {
    static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?
    static var requests: [URLRequest] = []

    static func reset() {
        handler = nil
        requests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else { return }
        Self.requests.append(request)
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class ReceiptTestSecureStorage: SecureStorage {
    private var values: [String: String] = [:]
    func save(_ value: String, for key: String) { values[key] = value }
    func get(_ key: String) -> String? { values[key] }
    func delete(_ key: String) { values[key] = nil }
}
