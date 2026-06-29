import Foundation

final class FriendsDataRepository: FriendsRepository {
    private let usersRepository: any UsersRepository

    init(usersRepository: any UsersRepository) {
        self.usersRepository = usersRepository
    }

    func listRemoteFriends() async throws -> [User] {
        try await usersRepository.listUsers()
    }
}
