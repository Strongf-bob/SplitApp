import Foundation

struct CreateFriendInviteEndpoint: Endpoint {
    let path = "/api/friend-invites"
    let method: HTTPMethod = .POST
}

struct PreviewFriendInviteEndpoint: Endpoint {
    let token: String
    var path: String { "/api/friend-invites/\(token)/preview" }
    let method: HTTPMethod = .GET
}

struct AcceptFriendInviteEndpoint: Endpoint {
    let token: String
    var path: String { "/api/friend-invites/\(token)/accept" }
    let method: HTTPMethod = .POST
}
