import SwiftUI

struct BottomTabPresentationItem: Identifiable, Equatable {
    let id: BottomTabID
    let title: String
    let systemImage: String
    let accessibilityLabel: String
    let isPrimaryAction: Bool
}

enum BottomTabPresentation {
    static let items: [BottomTabPresentationItem] = [
        .init(id: .home, title: "Главная", systemImage: "house.fill", accessibilityLabel: "Главная", isPrimaryAction: false),
        .init(id: .friends, title: "Друзья", systemImage: "person.2.fill", accessibilityLabel: "Друзья", isPrimaryAction: false),
        .init(id: .splitik, title: "Сплитик", systemImage: "sparkles", accessibilityLabel: "Сплитик", isPrimaryAction: true),
        .init(id: .events, title: "События", systemImage: "calendar", accessibilityLabel: "События", isPrimaryAction: false),
        .init(id: .profile, title: "Профиль", systemImage: "person.fill", accessibilityLabel: "Профиль", isPrimaryAction: false)
    ]
}
