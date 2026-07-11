import XCTest
@testable import SplitApp

final class BottomTabPresentationTests: XCTestCase {
    func testFigmaNavigationUsesTheFiveExpectedDestinationsInOrder() {
        XCTAssertEqual(
            BottomTabPresentation.items.map(\.accessibilityLabel),
            ["Главная", "Друзья", "Сплитик", "События", "Профиль"]
        )
    }
}
