import Foundation

struct CreateFriendInviteEndpoint: Endpoint {
    let path = "/api/friend-invites"
    let method: HTTPMethod = .POST
}

struct PreviewFriendInviteEndpoint: Endpoint {
    let path = "/api/friend-invites/preview"
    let method: HTTPMethod = .POST
}

struct AcceptFriendInviteEndpoint: Endpoint {
    let path = "/api/friend-invites/accept"
    let method: HTTPMethod = .POST
}

struct FriendInviteTokenPayload: Codable {
    let token: String
}
