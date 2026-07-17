import SwiftUI

struct BottomTabBarView: View {
    private let configuration: BottomTabConfiguration
    @State private var selectedTab: BottomTabID
    @ObservedObject private var friendInviteCenter = FriendInviteLinkCenter.shared
    @ObservedObject private var appTabCenter = AppTabCenter.shared

    init(configuration: BottomTabConfiguration) {
        self.configuration = configuration
        _selectedTab = State(initialValue: configuration.initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(configuration.items) { item in
                item.makeView()
                    .tabItem {
                        Label(item.title, systemImage: item.systemImage)
                    }
                .tag(item.id)
            }
        }
        .tint(AppTheme.accent)
        .onChange(of: friendInviteCenter.pendingPhone) { _, phone in
            if phone != nil {
                selectedTab = .friends
            }
        }
        .onChange(of: appTabCenter.requestedTab) { _, tab in
            guard let tab else { return }
            selectedTab = tab
            appTabCenter.consume()
        }
    }
}

#Preview {
    BottomTabBarView(configuration: .preview)
}
