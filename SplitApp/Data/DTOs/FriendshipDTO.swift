import Foundation

struct FriendshipDTO: Decodable, Identifiable {
    let id: UUID
    let requesterId: UUID
    let addresseeId: UUID
    let status: FriendshipStatus
    let peer: UserDTO?

    enum CodingKeys: String, CodingKey {
        case id, status, peer
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
    }
}

enum FriendshipMapper {
    static func mapToDomain(dto: FriendshipDTO) -> Friendship {
        Friendship(
            id: dto.id,
            requesterId: dto.requesterId,
            addresseeId: dto.addresseeId,
            status: dto.status,
            peer: dto.peer.map(UserMapper.mapToDomain)
        )
    }
}
