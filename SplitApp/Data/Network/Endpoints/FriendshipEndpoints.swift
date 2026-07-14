import Foundation

struct ListFriendshipsEndpoint: Endpoint {
    let limit: Int
    let offset: Int

    init(limit: Int = 50, offset: Int = 0) {
        self.limit = limit
        self.offset = offset
    }

    let path = "/api/friends"
    let method: HTTPMethod = .GET

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
    }
}

struct AcceptFriendshipEndpoint: Endpoint {
    let id: UUID
    var path: String { "/api/friends/\(id.uuidString)/accept" }
    let method: HTTPMethod = .POST
}

struct RejectFriendshipEndpoint: Endpoint {
    let id: UUID
    var path: String { "/api/friends/\(id.uuidString)/reject" }
    let method: HTTPMethod = .POST
}

struct RemoveFriendshipEndpoint: Endpoint {
    let id: UUID
    var path: String { "/api/friends/\(id.uuidString)" }
    let method: HTTPMethod = .DELETE
}
