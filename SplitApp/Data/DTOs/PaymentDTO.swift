import Foundation

struct PaymentDTO: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let senderId: UUID
    let receiverId: UUID
    let amount: Double
    let status: String?
    let confirmed: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, amount, confirmed
        case amountKopecks = "amount_kopecks"
        case status
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
        status: String? = nil,
        confirmed: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.eventId = eventId
        self.senderId = senderId
        self.receiverId = receiverId
        self.amount = amount
        self.status = status
        self.confirmed = confirmed
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        eventId = try container.decode(UUID.self, forKey: .eventId)
        senderId = try container.decode(UUID.self, forKey: .senderId)
        receiverId = try container.decode(UUID.self, forKey: .receiverId)
        if let amountKopecks = try container.decodeIfPresent(Int.self, forKey: .amountKopecks) {
            amount = Double(amountKopecks) / 100
        } else {
            amount = try container.decodeLosslessDouble(forKey: .amount)
        }
        status = try container.decodeIfPresent(String.self, forKey: .status)
        confirmed = try container.decode(Bool.self, forKey: .confirmed)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encode(confirmed, forKey: .confirmed)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

struct CreatePaymentRequest: Encodable {
    let senderId: UUID
    let receiverId: UUID
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case amountKopecks = "amount_kopecks"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(Int((amount * 100).rounded()), forKey: .amountKopecks)
    }
}

struct UpdatePaymentRequest: Codable {
    let confirmed: Bool
}
