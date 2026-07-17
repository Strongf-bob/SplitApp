import Foundation

struct ListUsersEndpoint: Endpoint {
    let path = "/api/users"
    let method: HTTPMethod = .GET
    let limit: Int
    let offset: Int

    init(limit: Int = 50, offset: Int = 0) {
        self.limit = limit
        self.offset = offset
    }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
    }
}

struct CurrentUserEndpoint: Endpoint {
    let path = "/api/users/me"
    let method: HTTPMethod = .GET
}

struct UpdateCurrentUserEndpoint: Endpoint {
    let path = "/api/users/me"
    let method: HTTPMethod = .PATCH
}

struct UpdateCurrentUserRequest: Encodable {
    let paymentPhone: String
    let paymentPhoneVisibility = "friends"

    enum CodingKeys: String, CodingKey {
        case paymentPhone = "payment_phone"
        case paymentPhoneVisibility = "payment_phone_visibility"
    }
}

struct SearchUsersEndpoint: Endpoint {
    let query: String
    let limit: Int
    let offset: Int

    init(query: String, limit: Int = 20, offset: Int = 0) {
        self.query = query
        self.limit = limit
        self.offset = offset
    }

    let path = "/api/users/search"
    let method: HTTPMethod = .GET

    var queryItems: [URLQueryItem]? {
        var items = [URLQueryItem(name: "q", value: Self.normalizePhone(query))]
        if limit != 20 {
            items.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if offset != 0 {
            items.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        return items
    }

    static func normalizePhone(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.filter(\.isNumber)
        if digits.count == 11, digits.hasPrefix("8") {
            return "+7" + digits.dropFirst()
        }
        if digits.count == 11, digits.hasPrefix("7") {
            return "+" + digits
        }
        if digits.count == 10 {
            return "+7" + digits
        }
        return trimmed.hasPrefix("+") ? "+" + digits : digits
    }
}

struct AuthUserEndpoint: Endpoint {
    let path = "/api/login"
    let method: HTTPMethod = .POST
    let yandexToken: String
}

struct RefreshTokenEndpoint: Endpoint {
    let path = "/api/refresh"
    let method: HTTPMethod = .POST
}
