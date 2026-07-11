import XCTest
@testable import SplitApp

final class BottomTabPresentationTests: XCTestCase {
    func testFigmaNavigationUsesTheFiveExpectedDestinationsInOrder() {
        XCTAssertEqual(
            BottomTabPresentation.items.map(\.accessibilityLabel),
            ["Главная", "Друзья", "Сплитик", "События", "Профиль"]
        )
    }

    func testSplitikKeepsItsCaptionInTheNavigationBar() {
        let splitik = try! XCTUnwrap(
            BottomTabPresentation.items.first(where: { $0.id == .splitik })
        )

        XCTAssertTrue(splitik.showsTitle)
    }
}
