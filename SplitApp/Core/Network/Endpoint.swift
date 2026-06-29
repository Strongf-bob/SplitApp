import Foundation

enum HTTPMethod: String {
    case GET
    case POST
    case PATCH
    case DELETE
}

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String] { get }
}

extension Endpoint {
    var queryItems: [URLQueryItem]? {
        nil
    }

    var headers: [String: String] {
        [:]
    }
}
