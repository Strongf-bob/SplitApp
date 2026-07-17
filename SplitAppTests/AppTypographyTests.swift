import UIKit
import XCTest
@testable import SplitApp

final class AppTypographyTests: XCTestCase {
    func testBundledDesignFontsAreRegistered() {
        for name in AppTypography.requiredFontNames {
            XCTAssertNotNil(UIFont(name: name, size: 16), "Font \(name) is not registered")
        }
    }

    func testPDFDesignTokensMatchApprovedPaletteAndGeometry() {
        XCTAssertEqual(SplitAppDesignTokens.primaryBlueHex, "#1F387C")
        XCTAssertEqual(SplitAppDesignTokens.secondaryBlueHex, "#4C6096")
        XCTAssertEqual(SplitAppDesignTokens.tertiaryBlueHex, "#7988B0")
        XCTAssertEqual(SplitAppDesignTokens.disabledSurfaceHex, "#F2F2F2")
        XCTAssertEqual(SplitAppDesignTokens.cardCornerRadius, 21)
        XCTAssertEqual(SplitAppDesignTokens.modalCornerRadius, 32)
    }
}
