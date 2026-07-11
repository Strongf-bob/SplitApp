import XCTest
@testable import SplitApp

final class YandexOAuthConfigurationTests: XCTestCase {
    func testUsesTheRegisteredIOSClientID() {
        XCTAssertEqual(
            YandexOAuthConfiguration.clientID,
            "6c5725f5868c4604adaea1e4b892c14d"
        )
    }
}
