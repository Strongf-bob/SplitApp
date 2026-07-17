import XCTest
@testable import SplitApp

final class FriendSearchTests: XCTestCase {
    override func setUp() {
        super.setUp()
        FriendSearchURLProtocol.reset()
        TokenStore.shared.save(token: "friend-search-token", validFor: 900)
    }

    override func tearDown() {
        TokenStore.shared.clear()
        FriendSearchURLProtocol.reset()
        super.tearDown()
    }

    func testSearchEndpointNormalizesPhoneQuery() {
        let endpoint = SearchUsersEndpoint(query: "+7 (905) 469-77-10")

        XCTAssertEqual(endpoint.path, "/api/users/search")
        XCTAssertEqual(endpoint.method, .GET)
        XCTAssertEqual(endpoint.queryItems, [URLQueryItem(name: "q", value: "+79054697710")])
    }

    func testAirDropInviteRoundTripsSenderPhone() throws {
        let url = try XCTUnwrap(FriendInviteLink.make(phone: "+7 (905) 469-77-10"))

        XCTAssertEqual(url.absoluteString, "splitapp://friends/add?phone=+79054697710")
        XCTAssertEqual(FriendInviteLink.phone(from: url), "+79054697710")
    }

    func testUsersRepositorySearchesRegisteredUser() async throws {
        let userID = UUID()
        FriendSearchURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/users/search")
            XCTAssertEqual(
                URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems,
                [URLQueryItem(name: "q", value: "+79054697710")]
            )
            return .json("""
            {
              "items": [{
                "id": "\(userID.uuidString)",
                "name": "Алиса Одинцова",
                "phone_number": "+79054697710",
                "email": null,
                "avatar_url": null
              }],
              "limit": 20,
              "offset": 0,
              "total": 1
            }
            """)
        }

        let users = try await UsersDataRepository(apiClient: apiClient()).searchUsers(
            query: "+7 (905) 469-77-10"
        )

        XCTAssertEqual(users.map(\.id), [userID])
        XCTAssertEqual(users.first?.name, "Алиса Одинцова")
    }

    func testFriendsRepositoryCreatesRequestForSelectedUser() async throws {
        let userID = UUID()
        let friendshipID = UUID()
        let encodedBody = try JSONEncoder().encode(CreateFriendRequest(userId: userID))
        let body = try JSONSerialization.jsonObject(with: encodedBody) as! [String: String]
        XCTAssertEqual(body["user_id"], userID.uuidString)

        FriendSearchURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/friends")
            return .json("""
            {
              "id": "\(friendshipID.uuidString)",
              "requester_id": "\(UUID().uuidString)",
              "addressee_id": "\(userID.uuidString)",
              "status": "requested",
              "peer": null,
              "created_at": "2026-07-17T10:00:00Z",
              "updated_at": "2026-07-17T10:00:00Z"
            }
            """, statusCode: 201)
        }

        let request = try await FriendsDataRepository(apiClient: apiClient()).createFriendRequest(
            userId: userID
        )

        XCTAssertEqual(request.id, friendshipID)
        XCTAssertEqual(request.status, .requested)
    }

    private func apiClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FriendSearchURLProtocol.self]
        return APIClient(session: URLSession(configuration: configuration))
    }
}

private final class FriendSearchURLProtocol: URLProtocol {
    struct Response {
        let statusCode: Int
        let data: Data

        static func json(_ string: String, statusCode: Int = 200) -> Response {
            Response(statusCode: statusCode, data: Data(string.utf8))
        }
    }

    static var handler: ((URLRequest) -> Response)?

    static func reset() {
        handler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == APIConfiguration.baseURL.host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let result = Self.handler?(request) ?? .json("{}", statusCode: 500)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: result.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: result.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
