import XCTest
@testable import SplitApp

final class FriendsDataRepositoryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        FriendshipURLProtocol.reset()
        TokenStore.shared.save(token: "friend-token", validFor: 900)
    }

    override func tearDown() {
        TokenStore.shared.clear()
        super.tearDown()
    }

    func testListFriendshipsMapsAcceptedPeer() async throws {
        let friendshipId = UUID()
        let requesterId = UUID()
        let peerId = UUID()
        FriendshipURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/friends")
            return .json("""
            {
              "items": [{
                "id": "\(friendshipId.uuidString)",
                "requester_id": "\(requesterId.uuidString)",
                "addressee_id": "\(peerId.uuidString)",
                "status": "accepted",
                "peer": {
                  "id": "\(peerId.uuidString)",
                  "name": "Алиса",
                  "phone_number": "79000000000",
                  "email": null,
                  "avatar_url": null
                },
                "created_at": "2026-07-14T12:00:00Z",
                "updated_at": "2026-07-14T12:00:00Z"
              }],
              "limit": 50,
              "offset": 0,
              "total": 1
            }
            """)
        }

        let friendships = try await repository().listFriendships()

        XCTAssertEqual(friendships.count, 1)
        XCTAssertEqual(friendships[0].id, friendshipId)
        XCTAssertEqual(friendships[0].status, .accepted)
        XCTAssertEqual(friendships[0].peer?.name, "Алиса")
    }

    func testFriendshipActionsUseExpectedPathsAndMethods() async throws {
        let friendshipId = UUID()
        FriendshipURLProtocol.handler = { request in
            switch request.url?.path {
            case "/api/friends/\(friendshipId.uuidString)/accept":
                XCTAssertEqual(request.httpMethod, "POST")
                return .json(Self.friendshipJSON(id: friendshipId, status: "accepted"))
            case "/api/friends/\(friendshipId.uuidString)/reject":
                XCTAssertEqual(request.httpMethod, "POST")
                return .json(Self.friendshipJSON(id: friendshipId, status: "rejected"))
            case "/api/friends/\(friendshipId.uuidString)":
                XCTAssertEqual(request.httpMethod, "DELETE")
                return .empty(statusCode: 204)
            default:
                XCTFail("Unexpected request: \(request)")
                return .empty(statusCode: 500)
            }
        }

        let repository = repository()
        _ = try await repository.acceptFriendship(id: friendshipId)
        _ = try await repository.rejectFriendship(id: friendshipId)
        try await repository.removeFriendship(id: friendshipId)

        XCTAssertEqual(FriendshipURLProtocol.requests.count, 3)
    }

    private func repository() -> FriendsDataRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FriendshipURLProtocol.self]
        return FriendsDataRepository(
            apiClient: APIClient(session: URLSession(configuration: configuration))
        )
    }

    private static func friendshipJSON(id: UUID, status: String) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "requester_id": "\(UUID().uuidString)",
          "addressee_id": "\(UUID().uuidString)",
          "status": "\(status)",
          "peer": null,
          "created_at": "2026-07-14T12:00:00Z",
          "updated_at": "2026-07-14T12:00:00Z"
        }
        """
    }
}

private final class FriendshipURLProtocol: URLProtocol {
    struct Response {
        let statusCode: Int
        let data: Data

        static func json(_ string: String, statusCode: Int = 200) -> Response {
            Response(statusCode: statusCode, data: Data(string.utf8))
        }

        static func empty(statusCode: Int) -> Response {
            Response(statusCode: statusCode, data: Data())
        }
    }

    static var requests: [URLRequest] = []
    static var handler: ((URLRequest) -> Response)?

    static func reset() {
        requests = []
        handler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == APIConfiguration.baseURL.host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requests.append(request)
        let result = Self.handler?(request) ?? .empty(statusCode: 500)
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
