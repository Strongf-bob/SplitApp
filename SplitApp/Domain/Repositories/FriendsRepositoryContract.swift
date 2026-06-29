import Foundation

protocol FriendsRepository {
    /// Online-first: remote users first, local cache fallback.
    func listRemoteFriends() async throws -> [User]
}
