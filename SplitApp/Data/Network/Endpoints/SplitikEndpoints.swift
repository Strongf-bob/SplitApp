import Foundation

struct SplitikMessageEndpoint: Endpoint {
    let path = "/api/splitik/messages"
    let method: HTTPMethod = .POST
    let idempotencyKey = UUID().uuidString

    var headers: [String: String] {
        ["Idempotency-Key": idempotencyKey]
    }
}

struct SplitikDraftCommitEndpoint: Endpoint {
    let draftId: UUID
    var path: String { "/api/splitik/drafts/\(draftId.uuidString)/commit" }
    let method: HTTPMethod = .POST
}

struct CurrentSplitikSessionEndpoint: Endpoint {
    let path = "/api/splitik/sessions/current"
    let method: HTTPMethod = .GET
}
