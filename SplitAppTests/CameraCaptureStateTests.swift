import XCTest
@testable import SplitApp

final class CameraCaptureStateTests: XCTestCase {
    func testCaptureCanStartOnlyOnceUntilItFinishes() {
        var state = CameraCaptureState()
        state.markReady()

        XCTAssertTrue(state.beginCapture())
        XCTAssertFalse(state.beginCapture())

        state.finishCapture()

        XCTAssertTrue(state.beginCapture())
    }

    func testCaptureIsRejectedWhenCameraIsNotReady() {
        var state = CameraCaptureState()

        XCTAssertFalse(state.beginCapture())
    }
}
