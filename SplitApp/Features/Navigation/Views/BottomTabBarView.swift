import SwiftUI

struct BottomTabBarView: View {
    private let configuration: BottomTabConfiguration
    @State private var selectedTab: BottomTabID
    @ObservedObject private var inviteStore = FriendInviteStore.shared

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
        .onAppear {
            if inviteStore.pendingToken != nil {
                selectedTab = .friends
            }
        }
        .onChange(of: inviteStore.pendingToken) { _, token in
            if token != nil {
                selectedTab = .friends
            }
        }
    }
}

#Preview {
    BottomTabBarView(configuration: .preview)
}
