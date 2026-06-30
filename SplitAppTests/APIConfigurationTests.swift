import XCTest
@testable import SplitApp

final class APIConfigurationTests: XCTestCase {
    func testBackendBaseURLPointsToDeployedServer() {
        XCTAssertEqual(APIConfiguration.baseURL.absoluteString, "http://46.243.201.8:8080")
    }

    func testRelativeAvatarURLUsesBackendBaseURL() {
        let url = User.resolveAvatarURL("/avatars/user.png")

        XCTAssertEqual(url?.absoluteString, "http://46.243.201.8:8080/avatars/user.png")
    }
}
