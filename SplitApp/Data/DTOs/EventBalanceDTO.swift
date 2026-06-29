import Foundation

struct EventBalanceDTO: Codable {
    let eventId: UUID
    let debitorId: UUID
    let creditorId: UUID
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case amount
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
        amount = try container.decodeLosslessDouble(forKey: .amount)
    }
}
