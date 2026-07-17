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

    func testModalRoutesCanHideAndRestoreTheTabBar() {
        let center = AppTabCenter()

        center.setTabBarHidden(true)
        XCTAssertTrue(center.isTabBarHidden)

        center.setTabBarHidden(false)
        XCTAssertFalse(center.isTabBarHidden)
    }
}
