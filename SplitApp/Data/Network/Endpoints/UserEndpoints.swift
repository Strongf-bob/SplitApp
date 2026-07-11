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

struct AuthUserEndpoint: Endpoint {
    let path = "/api/login"
    let method: HTTPMethod = .POST
    let yandexToken: String
}

struct RefreshTokenEndpoint: Endpoint {
    let path = "/api/refresh"
    let method: HTTPMethod = .POST
}
