import Foundation

struct EventInvitationInboxItem: Codable, Equatable, Identifiable {
    let id: UUID
    let token: String
    let eventId: UUID
    let eventName: String
    let createdBy: UUID
    let creatorName: String
    let expiresAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case token
        case eventId = "event_id"
        case eventName = "event_name"
        case createdBy = "created_by"
        case creatorName = "creator_name"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}
