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

    func testHiddenRouteInInactiveTabDoesNotHideSelectedTabsBar() {
        let center = AppTabCenter()

        center.select(.home)
        center.setTabBarHidden(true)
        center.select(.friends)

        XCTAssertFalse(center.isTabBarHidden)
    }

    func testShellResetClearsPresentationState() {
        let center = AppTabCenter()

        center.select(.events)
        center.openProfile()
        center.setTabBarHidden(true)
        center.resetShell()

        XCTAssertFalse(center.isProfilePresented)
        XCTAssertFalse(center.isTabBarHidden)
        XCTAssertEqual(center.requestedTab, .home)
    }
}
