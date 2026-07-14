import Foundation

struct FriendInviteDTO: Decodable {
    let id: UUID
    let creator: UserDTO
    let token: String
    let inviteURL: URL
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id, creator, token
        case inviteURL = "invite_url"
        case expiresAt = "expires_at"
    }
}

struct FriendInvitePreviewDTO: Decodable {
    let id: UUID
    let creator: UserDTO
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id, creator
        case expiresAt = "expires_at"
    }
}

enum FriendInviteMapper {
    static func mapToDomain(dto: FriendInviteDTO) -> FriendInvite {
        FriendInvite(
            id: dto.id,
            creator: UserMapper.mapToDomain(dto: dto.creator),
            token: dto.token,
            inviteURL: dto.inviteURL,
            expiresAt: dto.expiresAt
        )
    }

    static func mapToDomain(dto: FriendInvitePreviewDTO) -> FriendInvitePreview {
        FriendInvitePreview(
            id: dto.id,
            creator: UserMapper.mapToDomain(dto: dto.creator),
            expiresAt: dto.expiresAt
        )
    }
}
