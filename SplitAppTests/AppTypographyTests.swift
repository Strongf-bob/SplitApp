import UIKit
import XCTest
@testable import SplitApp

final class AppTypographyTests: XCTestCase {
    func testBundledDesignFontsAreRegistered() {
        for name in AppTypography.requiredFontNames {
            XCTAssertNotNil(UIFont(name: name, size: 16), "Font \(name) is not registered")
        }
    }
}
