import SwiftUI

struct BottomTabPresentationItem: Identifiable, Equatable {
    let id: BottomTabID
    let title: String
    let systemImage: String
    let accessibilityLabel: String
    let isPrimaryAction: Bool
    let showsTitle: Bool
}

enum BottomTabPresentation {
    static let items: [BottomTabPresentationItem] = [
        .init(id: .home, title: "Главная", systemImage: "house.fill", accessibilityLabel: "Главная", isPrimaryAction: false, showsTitle: true),
        .init(id: .friends, title: "Друзья", systemImage: "person.2.fill", accessibilityLabel: "Друзья", isPrimaryAction: false, showsTitle: true),
        .init(id: .splitik, title: "Сплитик", systemImage: "sparkles", accessibilityLabel: "Сплитик", isPrimaryAction: true, showsTitle: true),
        .init(id: .events, title: "События", systemImage: "calendar", accessibilityLabel: "События", isPrimaryAction: false, showsTitle: true)
    ]
}
