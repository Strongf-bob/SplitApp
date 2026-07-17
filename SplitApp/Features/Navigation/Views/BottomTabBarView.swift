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
                        .toolbar(.hidden, for: .tabBar)
                        .tag(item.id)
                }
            }

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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !appTabCenter.isTabBarHidden {
                PDFBottomTabBar(
                    items: configuration.items,
                    selectedTab: $selectedTab,
                    onSelect: { tab in
                        appTabCenter.activate(tab)
                        appTabCenter.closeProfile()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .animation(.easeInOut(duration: 0.18), value: appTabCenter.isTabBarHidden)
    }
}

private struct PDFBottomTabBar: View {
    let items: [BottomTabItem]
    @Binding var selectedTab: BottomTabID
    let onSelect: (BottomTabID) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                Button {
                    selectedTab = item.id
                    onSelect(item.id)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 19, weight: .semibold))
                            .frame(height: 22)

                        Text(item.title)
                            .font(AppTypography.montserrat(.semibold, size: 10, relativeTo: .caption2))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selectedTab == item.id ? Color(hex: "#0088FF") : AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background {
                        if selectedTab == item.id {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .fill(Color(hex: "#EDEDED"))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selectedTab == item.id ? .isSelected : [])
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(Color.white.opacity(0.75), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 18, y: 8)
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, -10)
    }
}

#Preview {
    BottomTabBarView(configuration: .preview)
}
