import XCTest
@testable import SplitApp

final class BottomTabPresentationTests: XCTestCase {
    func testPDFNavigationUsesExactlyFourExpectedDestinationsInOrder() {
        XCTAssertEqual(
            BottomTabPresentation.items.map(\.accessibilityLabel),
            ["Главная", "Друзья", "Сплитик", "События"]
        )
        XCTAssertEqual(BottomTabPresentation.items.count, 4)
    }

    func testSplitikKeepsItsCaptionInTheNavigationBar() {
        let splitik = try! XCTUnwrap(
            BottomTabPresentation.items.first(where: { $0.id == .splitik })
        )

        XCTAssertTrue(splitik.showsTitle)
    }
}
