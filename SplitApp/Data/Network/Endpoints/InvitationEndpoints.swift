import Foundation

struct ListEventInvitationsEndpoint: Endpoint {
    let path = "/api/invites"
    let method: HTTPMethod = .GET
    let limit: Int
    let offset: Int

    init(limit: Int = 50, offset: Int = 0) {
        self.limit = limit
        self.offset = offset
    }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
    }
}

struct AcceptEventInvitationEndpoint: Endpoint {
    let token: String
    var path: String { "/api/invites/\(token)/accept" }
    let method: HTTPMethod = .POST
}

struct DeclineEventInvitationEndpoint: Endpoint {
    let token: String
    var path: String { "/api/invites/\(token)/decline" }
    let method: HTTPMethod = .POST
}
