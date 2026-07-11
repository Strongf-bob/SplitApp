import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel: FriendsViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor

    init(
        friendsRepository: any FriendsRepository,
        balancesRepository: any BalancesRepository,
        paymentsRepository: any PaymentsRepository,
        activeEventRepository: any ActiveEventRepository,
        networkMonitor: NetworkMonitor
    ) {
        _viewModel = StateObject(
            wrappedValue: FriendsViewModel(
                friendsRepository: friendsRepository,
                balancesRepository: balancesRepository,
                paymentsRepository: paymentsRepository,
                activeEventRepository: activeEventRepository
            )
        )
        self.networkMonitor = networkMonitor
    }

    var body: some View {
        ZStack {
            background
            content
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
    }
}

private extension FriendsView {
    var background: some View {
        AppTheme.figmaHero
            .ignoresSafeArea()
            .dismissKeyboardOnTap()
    }

    var content: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 0) {
                offlineBanner
                searchBar
                scrollContent
            }
            .background(
                AppTheme.contentSurface,
                in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
            )
            .background(AppTheme.contentSurface.ignoresSafeArea(edges: .bottom))
        }
    }

    var header: some View {
        FriendsNavigationHeader()
            .onTapGesture {
                hideKeyboard()
            }
    }

    var searchBar: some View {
        SearchBar(searchText: $viewModel.searchText)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    @ViewBuilder
    var offlineBanner: some View {
        if !networkMonitor.isConnected || viewModel.offlineMessage != nil {
            HStack(spacing: 8) {
                Image(systemName: networkMonitor.isConnected ? "info.circle" : "wifi.slash")
                    .font(.system(size: 14, weight: .semibold))

                Text(viewModel.offlineMessage ?? "Нет соединения. Показываем сохраненные данные, если они есть.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.cardBackground.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }

    var scrollContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                activeDebtsSection
                allFriendsSection
                loadingState
                errorState
                emptyState
                bottomSpacer
            }
            .padding(.bottom, 32)
        }
        .refreshable {
            await viewModel.reload()
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    hideKeyboard()
                }
        )
    }

    @ViewBuilder
    var activeDebtsSection: some View {
        if !viewModel.activeDebts.isEmpty {
            ActiveDebtsSection(
                debts: viewModel.activeDebts,
                isSettling: { debt in
                    viewModel.settlingDebtIds.contains(debt.id)
                },
                onSettle: { debt in
                    Task {
                        await viewModel.settleDebt(debt)
                    }
                }
            )
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    var allFriendsSection: some View {
        if !viewModel.filteredFriends.isEmpty {
            AllFriendsSection(
                friends: viewModel.filteredFriends,
                startIndex: viewModel.activeDebts.count
            )
        }
    }

    @ViewBuilder
    var loadingState: some View {
        if viewModel.isLoading {
            ProgressView("Загружаем друзей...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 16)
        }
    }

    @ViewBuilder
    var errorState: some View {
        if !viewModel.isLoading,
           viewModel.filteredFriends.isEmpty,
           let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 24)
        }
    }

    @ViewBuilder
    var emptyState: some View {
        if viewModel.filteredFriends.isEmpty, !viewModel.searchText.isEmpty {
            EmptySearchState()
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    var bottomSpacer: some View {
        Color.clear
            .frame(minHeight: 100)
            .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        FriendsView(
            friendsRepository: FriendsDataRepository(
                usersRepository: UsersDataRepository()
            ),
            balancesRepository: BalancesDataRepository(),
            paymentsRepository: PaymentsDataRepository(),
            activeEventRepository: ActiveEventSelectionDataRepository(),
            networkMonitor: .shared
        )
    }
}
