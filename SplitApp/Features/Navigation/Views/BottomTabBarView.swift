import SwiftUI

struct BottomTabBarView: View {
    private let configuration: BottomTabConfiguration
    @State private var selectedTab: BottomTabID
    @ObservedObject private var inviteStore = FriendInviteStore.shared
    @ObservedObject private var friendInviteCenter = FriendInviteLinkCenter.shared
    @ObservedObject private var appTabCenter = AppTabCenter.shared

    init(configuration: BottomTabConfiguration) {
        self.configuration = configuration
        _selectedTab = State(initialValue: configuration.initialTab)
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ForEach(configuration.items) { item in
                    item.makeView()
                        .tabItem {
                            Label(item.title, systemImage: item.systemImage)
                        }
                        .tag(item.id)
                }
            }
            .tint(AppTheme.pdfPrimaryBlue)
            .toolbar(appTabCenter.isTabBarHidden ? .hidden : .visible, for: .tabBar)

            if appTabCenter.isProfilePresented {
                ZStack(alignment: .topTrailing) {
                    configuration.makeProfileView()

                    Button {
                        appTabCenter.closeProfile()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.disabledSurface, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Закрыть профиль")
                    .padding(.top, 8)
                    .padding(.trailing, 16)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            appTabCenter.activate(selectedTab)
            if inviteStore.pendingToken != nil || friendInviteCenter.pendingPhone != nil {
                selectedTab = .friends
                appTabCenter.activate(.friends)
            }
        }
        .onChange(of: inviteStore.pendingToken) { _, token in
            if token != nil {
                selectedTab = .friends
                appTabCenter.activate(.friends)
            }
        }
        .onChange(of: friendInviteCenter.pendingPhone) { _, phone in
            if phone != nil {
                selectedTab = .friends
                appTabCenter.activate(.friends)
            }
        }
        .onChange(of: appTabCenter.requestedTab) { _, tab in
            guard let tab else { return }
            selectedTab = tab
            appTabCenter.activate(tab)
            appTabCenter.consume()
        }
        .onChange(of: selectedTab) { _, tab in
            appTabCenter.activate(tab)
            appTabCenter.closeProfile()
        }
    }
}

#Preview {
    BottomTabBarView(configuration: .preview)
}
