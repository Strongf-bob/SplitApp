import Foundation

struct InboxNotification: Equatable, Identifiable {
    let id = "offline-sync"
    let title: String
    let message: String
    let systemImage: String
    let isUnread: Bool
}

enum InboxNotificationPresentation {
    static func incoming(isConnected: Bool) -> [InboxNotification] {
        guard !isConnected else { return [] }

        return [
            InboxNotification(
                title: "Нет подключения к интернету",
                message: "Синхронизация недоступна. Мы обновим данные, когда соединение появится.",
                systemImage: "wifi.slash",
                isUnread: true
            )
        ]
    }
}
