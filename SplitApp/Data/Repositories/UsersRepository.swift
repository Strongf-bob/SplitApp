import CoreData
import Foundation

final class UsersDataRepository: UsersRepository {
    private let apiClient: APIClient
    private let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    func listUsers() async throws -> [User] {
        do {
            let dtos = try await fetchAllUsers()
            try await coreDataStore.performBackground { [weak self] context in
                try self?.upsertUsers(dtos, in: context)
            }
            return try await getCachedUsers()
        } catch {
            let cached = try await getCachedUsers()
            if cached.isEmpty {
                throw RepositoryError.offlineNoCache
            }
            return cached
        }
    }

    func getCachedUsers() async throws -> [User] {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDUser.name, ascending: true)]
            let cdUsers = try context.fetch(fetchRequest)
            return cdUsers.compactMap { UserMapper.mapToDomain(cdUser: $0) }
        }
    }

    func searchUsers(query: String) async throws -> [User] {
        var offset = 0
        var users: [User] = []

        while true {
            let page: PageResponse<UserDTO> = try await apiClient.request(
                endpoint: SearchUsersEndpoint(query: query, offset: offset)
            )
            users += page.items.map(UserMapper.mapToDomain)
            guard page.hasMore, !page.items.isEmpty else {
                return users
            }
            offset = page.nextOffset
        }
    }

    func getCurrentUser() async throws -> User {
        let dto: UserDTO = try await apiClient.request(endpoint: CurrentUserEndpoint())
        return UserMapper.mapToDomain(dto: dto)
    }

    func updatePaymentPhone(_ phone: String) async throws -> User {
        let dto: UserDTO = try await apiClient.request(
            endpoint: UpdateCurrentUserEndpoint(),
            body: UpdateCurrentUserRequest(paymentPhone: phone)
        )
        return UserMapper.mapToDomain(dto: dto)
    }

    private func upsertUsers(
        _ dtos: [UserDTO],
        in context: NSManagedObjectContext
    ) throws {
        for dto in dtos {
            let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
            fetchRequest.fetchLimit = 1

            let existing = try context.fetch(fetchRequest).first
            let user = existing ?? CDUser(context: context)
            user.update(from: dto)
        }
    }

    private func fetchAllUsers(limit: Int = 50) async throws -> [UserDTO] {
        var offset = 0
        var users: [UserDTO] = []

        while true {
            let page: PageResponse<UserDTO> = try await apiClient.request(
                endpoint: ListUsersEndpoint(limit: limit, offset: offset)
            )
            users.append(contentsOf: page.items)

            guard page.hasMore, !page.items.isEmpty else {
                return users
            }
            offset = page.nextOffset
        }
    }
}
