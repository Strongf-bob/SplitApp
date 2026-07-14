import Foundation

enum FriendshipStatus: String, Codable {
    case requested
    case accepted
    case rejected
    case removed
    case blocked
}

struct Friendship: Identifiable, Equatable {
    let id: UUID
    let requesterId: UUID
    let addresseeId: UUID
    let status: FriendshipStatus
    let peer: User?
}
