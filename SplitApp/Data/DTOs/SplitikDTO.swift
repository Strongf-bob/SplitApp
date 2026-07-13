import Foundation

struct SplitikMessageRequest: Encodable {
    let message: String
    let sessionId: UUID?
    let mode = "general"
    let locale = "ru-RU"
    let timezone = "Europe/Moscow"

    enum CodingKeys: String, CodingKey {
        case message
        case sessionId = "session_id"
        case mode, locale, timezone
    }
}

struct SplitikMessageResponse: Decodable {
    let sessionId: UUID
    let assistantMessage: String
    let drafts: [SplitikDraftDTO]

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case assistantMessage = "assistant_message"
        case drafts
    }
}

struct SplitikDraftDTO: Decodable, Identifiable {
    let id: UUID
    let type: String
    let status: String
    let payload: SplitikDraftPayload

    var eventPlan: SplitikEventPlanDTO? {
        type == "create_event_bundle" ? payload.eventPlan : nil
    }
}

struct SplitikDraftPayload: Decodable {
    let name: String?
    let participantIds: [UUID]?
    let receipts: [SplitikPlanReceiptDTO]?

    enum CodingKeys: String, CodingKey {
        case name
        case participantIds = "participant_ids"
        case receipts
    }

    var eventPlan: SplitikEventPlanDTO? {
        guard let name else { return nil }
        return SplitikEventPlanDTO(name: name, participantIds: participantIds ?? [], receipts: receipts ?? [])
    }
}

struct SplitikEventPlanDTO {
    let name: String
    let participantIds: [UUID]
    let receipts: [SplitikPlanReceiptDTO]
}

struct SplitikPlanReceiptDTO: Decodable {
    let title: String
    let amountKopecks: Int

    enum CodingKeys: String, CodingKey {
        case title
        case amountKopecks = "amount_kopecks"
    }
}

struct SplitikDraftCommitResponse: Decodable {
    let draft: SplitikDraftDTO
}
