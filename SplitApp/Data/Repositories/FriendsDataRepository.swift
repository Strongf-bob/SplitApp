import Foundation

final class FriendsDataRepository: FriendsRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func listFriendships() async throws -> [Friendship] {
        var offset = 0
        var friendships: [Friendship] = []

        while true {
            let page: PageResponse<FriendshipDTO> = try await apiClient.request(
                endpoint: ListFriendshipsEndpoint(offset: offset)
            )
            friendships += page.items.map(FriendshipMapper.mapToDomain)

            guard page.hasMore, !page.items.isEmpty else {
                return friendships
            }
            offset = page.nextOffset
        }
    }

    func acceptFriendship(id: UUID) async throws -> Friendship {
        let dto: FriendshipDTO = try await apiClient.request(
            endpoint: AcceptFriendshipEndpoint(id: id)
        )
        return FriendshipMapper.mapToDomain(dto: dto)
    }

    func rejectFriendship(id: UUID) async throws -> Friendship {
        let dto: FriendshipDTO = try await apiClient.request(
            endpoint: RejectFriendshipEndpoint(id: id)
        )
        return FriendshipMapper.mapToDomain(dto: dto)
    }

    func removeFriendship(id: UUID) async throws {
        try await apiClient.requestVoid(endpoint: RemoveFriendshipEndpoint(id: id))
    }

    func createFriendInvite() async throws -> FriendInvite {
        let dto: FriendInviteDTO = try await apiClient.request(
            endpoint: CreateFriendInviteEndpoint()
        )
        return FriendInviteMapper.mapToDomain(dto: dto)
    }

    func previewFriendInvite(token: String) async throws -> FriendInvitePreview {
        let dto: FriendInvitePreviewDTO = try await apiClient.request(
            endpoint: PreviewFriendInviteEndpoint(),
            body: FriendInviteTokenPayload(token: token)
        )
        return FriendInviteMapper.mapToDomain(dto: dto)
    }

    func acceptFriendInvite(token: String) async throws -> Friendship {
        let dto: FriendshipDTO = try await apiClient.request(
            endpoint: AcceptFriendInviteEndpoint(),
            body: FriendInviteTokenPayload(token: token)
        )
        return FriendshipMapper.mapToDomain(dto: dto)
    }
}
