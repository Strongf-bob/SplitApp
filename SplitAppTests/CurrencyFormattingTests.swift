import XCTest
@testable import SplitApp

final class CurrencyFormattingTests: XCTestCase {
    func testRubleSymbolFollowsAmountAsInApprovedDesign() {
        XCTAssertEqual(4_250.0.rubleText(), "4 250 ₽")
        XCTAssertEqual((-500.0).rubleText(signed: true), "-500 ₽")
        XCTAssertEqual(500.0.rubleText(signed: true), "+500 ₽")
    }
}
