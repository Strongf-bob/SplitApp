import Foundation

struct CreatePaymentEndpoint: Endpoint {
    let eventId: UUID
    var path: String {
        "/api/events/\(eventId.uuidString)/payments"
    }

    let method: HTTPMethod = .POST
}

struct ListPaymentsEndpoint: Endpoint {
    let eventId: UUID
    let limit: Int
    let offset: Int

    init(eventId: UUID, limit: Int = 50, offset: Int = 0) {
        self.eventId = eventId
        self.limit = limit
        self.offset = offset
    }

    var path: String {
        "/api/events/\(eventId.uuidString)/payments"
    }

    let method: HTTPMethod = .GET

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
    }
}

struct UpdatePaymentEndpoint: Endpoint {
    let id: UUID
    var path: String {
        "/api/payments/\(id.uuidString)"
    }

    let method: HTTPMethod = .PATCH
}
