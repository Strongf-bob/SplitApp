import SwiftUI

struct BottomTabBarView: View {
    private let configuration: BottomTabConfiguration
    @State private var selectedTab: BottomTabID

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
        .tabViewStyle(.page(indexDisplayMode: .never))
        .tint(AppTheme.accent)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LiquidGlassTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
    }
}

private struct LiquidGlassTabBar: View {
    @Binding var selectedTab: BottomTabID

    var body: some View {
        if #available(iOS 26.0, *) {
            tabItems
                .glassEffect(
                    .regular.tint(AppTheme.tabGlassTint.opacity(0.88)),
                    in: Capsule()
                )
        } else {
            tabItems
                .background(AppTheme.tabGlassTint.opacity(0.9), in: Capsule())
                .overlay {
                    Capsule().stroke(.white.opacity(0.18), lineWidth: 1)
                }
        }
    }

    private var tabItems: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(BottomTabPresentation.items) { item in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selectedTab = item.id
                    }
                } label: {
                    if item.isPrimaryAction {
                        Image(systemName: item.systemImage)
                            .font(.headline.weight(.bold))
                            .frame(width: 42, height: 42)
                            .foregroundStyle(.white)
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 16, weight: .semibold))
                            Text(item.title)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(selectedTab == item.id ? 1 : 0.82))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background {
                            if selectedTab == item.id {
                                Capsule().fill(.white.opacity(0.30))
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .accessibilityLabel(item.accessibilityLabel)
                .accessibilityAddTraits(selectedTab == item.id ? .isSelected : [])
            }
        }
        .padding(6)
        .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
    }
}

#Preview {
    BottomTabBarView(configuration: .preview)
}
