import Foundation

struct FriendInvite {
    let id: UUID
    let creator: User
    let token: String
    let inviteURL: URL
    let expiresAt: Date
}

struct FriendInvitePreview: Identifiable {
    let id: UUID
    let creator: User
    let expiresAt: Date
}
