import XCTest
@testable import SplitApp

final class APIClientAuthorizationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AuthorizationURLProtocol.reset()
        TokenStore.shared.save(token: "expired-token", validFor: -1)
    }

    override func tearDown() {
        TokenStore.shared.clear()
        super.tearDown()
    }

    func testVoidRequestRefreshesExpiredTokenAndRetriesTheProtectedRequest() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthorizationURLProtocol.self]
        let storage = InMemorySecureStorage(values: ["refresh_token": "refresh-token"])
        let client = APIClient(
            session: URLSession(configuration: configuration),
            secureStorage: storage
        )

        try await client.requestVoid(endpoint: DeleteEventEndpoint(id: UUID()))

        XCTAssertEqual(AuthorizationURLProtocol.requests.count, 3)
        XCTAssertEqual(AuthorizationURLProtocol.requests[0].url?.path, "/api/events/placeholder")
        XCTAssertEqual(AuthorizationURLProtocol.requests[1].url?.path, "/api/refresh")
        XCTAssertEqual(AuthorizationURLProtocol.requests[2].url?.path, "/api/events/placeholder")
        XCTAssertEqual(AuthorizationURLProtocol.requests[2].value(forHTTPHeaderField: "Authorization"), "Bearer refreshed-token")
    }

    func testVoidRequestForcesRefreshWhenServerRejectsLocallyValidToken() async throws {
        TokenStore.shared.save(token: "revoked-token", validFor: 900)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthorizationURLProtocol.self]
        let storage = InMemorySecureStorage(values: ["refresh_token": "refresh-token"])
        let client = APIClient(
            session: URLSession(configuration: configuration),
            secureStorage: storage
        )

        try await client.requestVoid(endpoint: DeleteEventEndpoint(id: UUID()))

        XCTAssertEqual(AuthorizationURLProtocol.requests.count, 3)
        XCTAssertEqual(AuthorizationURLProtocol.requests[0].url?.path, "/api/events/placeholder")
        XCTAssertEqual(AuthorizationURLProtocol.requests[1].url?.path, "/api/refresh")
        XCTAssertEqual(AuthorizationURLProtocol.requests[2].url?.path, "/api/events/placeholder")
        XCTAssertEqual(AuthorizationURLProtocol.requests[2].value(forHTTPHeaderField: "Authorization"), "Bearer refreshed-token")
    }
}

private final class AuthorizationURLProtocol: URLProtocol {
    static var requests: [URLRequest] = []

    static func reset() {
        requests = []
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == APIConfiguration.baseURL.host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        var request = request
        request.url = URL(string: "\(APIConfiguration.baseURL.absoluteString)\(request.url!.path)")
        if request.url?.path.hasPrefix("/api/events/") == true {
            request.url = URL(string: "\(APIConfiguration.baseURL.absoluteString)/api/events/placeholder")
        }
        Self.requests.append(request)

        let response: HTTPURLResponse
        let data: Data
        switch request.url?.path {
        case "/api/refresh":
            response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            data = Data("{\"access_token\":\"refreshed-token\",\"refresh_token\":\"refreshed-refresh-token\",\"token_type\":\"bearer\",\"expires_in\":900}".utf8)
        case "/api/events/placeholder" where Self.requests.count == 1:
            response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            data = Data()
        default:
            response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            data = Data()
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class InMemorySecureStorage: SecureStorage {
    private var values: [String: String]

    init(values: [String: String]) {
        self.values = values
    }

    func save(_ value: String, for key: String) {
        values[key] = value
    }

    func get(_ key: String) -> String? {
        values[key]
    }

    func delete(_ key: String) {
        values[key] = nil
    }
}
