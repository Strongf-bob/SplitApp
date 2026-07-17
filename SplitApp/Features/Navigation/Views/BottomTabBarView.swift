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
        TabView(selection: $selectedTab) {
            ForEach(configuration.items) { item in
                item.makeView()
                    .toolbar(.hidden, for: .tabBar)
                    .tag(item.id)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PDFBottomTabBar(
                items: configuration.items,
                selectedTab: $selectedTab
            )
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { appTabCenter.isProfilePresented },
                set: { isPresented in
                    if !isPresented {
                        appTabCenter.closeProfile()
                    }
                }
            )
        ) {
            ZStack(alignment: .topTrailing) {
                configuration.makeProfileView()

                Button {
                    appTabCenter.closeProfile()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Закрыть профиль")
                .padding(.top, 8)
                .padding(.trailing, 20)
            }
        }
        .onAppear {
            if inviteStore.pendingToken != nil || friendInviteCenter.pendingPhone != nil {
                selectedTab = .friends
            }
        }
        .onChange(of: inviteStore.pendingToken) { _, token in
            if token != nil {
                selectedTab = .friends
            }
        }
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

private struct PDFBottomTabBar: View {
    let items: [BottomTabItem]
    @Binding var selectedTab: BottomTabID

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                Button {
                    selectedTab = item.id
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
                    .foregroundStyle(selectedTab == item.id ? Color.white : Color(hex: "#1F387C"))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background {
                        if selectedTab == item.id {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .fill(Color(hex: "#1F387C"))
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
        .padding(.bottom, 4)
    }
}

#Preview {
    BottomTabBarView(configuration: .preview)
}
