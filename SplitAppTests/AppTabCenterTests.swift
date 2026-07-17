import XCTest
@testable import SplitApp

@MainActor
final class AppTabCenterTests: XCTestCase {
    func testProfilePresentationDoesNotRequestAnotherTab() {
        let center = AppTabCenter()

        center.openProfile()

        XCTAssertTrue(center.isProfilePresented)
        XCTAssertNil(center.requestedTab)

        center.closeProfile()

        XCTAssertFalse(center.isProfilePresented)
    }
}
