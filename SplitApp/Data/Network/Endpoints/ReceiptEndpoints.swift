import Foundation

struct CreateReceiptEndpoint: Endpoint {
    let eventId: UUID
    var path: String { "/api/events/\(eventId.uuidString.lowercased())/receipts" }
    let method: HTTPMethod = .POST
    let headers: [String: String] = ["Idempotency-Key": UUID().uuidString]
}

struct ListReceiptsEndpoint: Endpoint {
    let eventId: UUID
    let limit: Int
    let offset: Int

    init(eventId: UUID, limit: Int = 50, offset: Int = 0) {
        self.eventId = eventId
        self.limit = limit
        self.offset = offset
    }

    var path: String { "/api/events/\(eventId.uuidString.lowercased())/receipts" }
    let method: HTTPMethod = .GET

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
    }
}

struct UpdateReceiptEndpoint: Endpoint {
    let id: UUID
    var path: String {
        "/api/receipts/\(id.uuidString)"
    }

    let method: HTTPMethod = .PATCH
}

struct DeleteReceiptEndpoint: Endpoint {
    let id: UUID
    var path: String {
        "/api/receipts/\(id.uuidString)"
    }

    let method: HTTPMethod = .DELETE
}

struct UploadReceiptImageEndpoint: Endpoint {
    let id: UUID
    var path: String {
        "/api/receipts/\(id.uuidString)/image"
    }

    let method: HTTPMethod = .POST
}

struct ReceiptImagePresignedURLEndpoint: Endpoint {
    let id: UUID
    var path: String {
        "/api/receipts/\(id.uuidString)/image/presigned-url"
    }

    let method: HTTPMethod = .GET
}
