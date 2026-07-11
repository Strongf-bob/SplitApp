import XCTest
@testable import SplitApp

final class CurrentUserEndpointTests: XCTestCase {
    func testUsesAuthenticatedCurrentUserEndpoint() {
        XCTAssertEqual(CurrentUserEndpoint().path, "/api/users/me")
    }
}
