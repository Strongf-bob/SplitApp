import Foundation

struct EventBalanceDTO: Codable {
    let eventId: UUID
    let debitorId: UUID
    let creditorId: UUID
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case amount
        case amountKopecks = "amount_kopecks"
        case eventId = "event_id"
        case debitorId = "debitor_id"
        case creditorId = "creditor_id"
    }

    init(eventId: UUID, debitorId: UUID, creditorId: UUID, amount: Double) {
        self.eventId = eventId
        self.debitorId = debitorId
        self.creditorId = creditorId
        self.amount = amount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventId = try container.decode(UUID.self, forKey: .eventId)
        debitorId = try container.decode(UUID.self, forKey: .debitorId)
        creditorId = try container.decode(UUID.self, forKey: .creditorId)
        if let amountKopecks = try container.decodeIfPresent(Int.self, forKey: .amountKopecks) {
            amount = Double(amountKopecks) / 100
        } else {
            amount = try container.decodeLosslessDouble(forKey: .amount)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(debitorId, forKey: .debitorId)
        try container.encode(creditorId, forKey: .creditorId)
        try container.encode(amount, forKey: .amount)
    }
}
