import XCTest
@testable import SplitApp

final class SplitLaunchPresentationTests: XCTestCase {
    func testRemainingDurationKeepsOverlayVisibleUntilMinimumDuration() {
        let startedAt = Date(timeIntervalSinceReferenceDate: 100)
        let elapsed = Date(timeIntervalSinceReferenceDate: 100.1)

        XCTAssertEqual(
            SplitLaunchPresentation.remainingDuration(since: startedAt, now: elapsed),
            0.25,
            accuracy: 0.001
        )
    }
}
