import Foundation

struct SplitikMessageEndpoint: Endpoint {
    let path = "/api/splitik/messages"
    let method: HTTPMethod = .POST
    let idempotencyKey = UUID().uuidString

    var headers: [String: String] {
        ["Idempotency-Key": idempotencyKey]
    }
}
