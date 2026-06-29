import Foundation

struct PaymentDTO: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let senderId: UUID
    let receiverId: UUID
    let amount: Double
    let confirmed: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, amount, confirmed
        case eventId = "event_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case createdAt = "created_at"
    }

    init(
        id: UUID,
        eventId: UUID,
        senderId: UUID,
        receiverId: UUID,
        amount: Double,
        confirmed: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.eventId = eventId
        self.senderId = senderId
        self.receiverId = receiverId
        self.amount = amount
        self.confirmed = confirmed
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        eventId = try container.decode(UUID.self, forKey: .eventId)
        senderId = try container.decode(UUID.self, forKey: .senderId)
        receiverId = try container.decode(UUID.self, forKey: .receiverId)
        amount = try container.decodeLosslessDouble(forKey: .amount)
        confirmed = try container.decode(Bool.self, forKey: .confirmed)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct CreatePaymentRequest: Codable {
    let senderId: UUID
    let receiverId: UUID
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case amount
        case senderId = "sender_id"
        case receiverId = "receiver_id"
    }
}

struct UpdatePaymentRequest: Codable {
    let confirmed: Bool
}
