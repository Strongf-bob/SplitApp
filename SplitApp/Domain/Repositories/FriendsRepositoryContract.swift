import Foundation

protocol FriendsRepository {
    func listFriendships() async throws -> [Friendship]
    func acceptFriendship(id: UUID) async throws -> Friendship
    func rejectFriendship(id: UUID) async throws -> Friendship
    func removeFriendship(id: UUID) async throws
}
