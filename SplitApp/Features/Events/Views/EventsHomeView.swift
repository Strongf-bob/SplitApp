import SwiftUI

struct EventsHomeView: View {
    @ObservedObject var viewModel: EventsHomeViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    @ObservedObject private var currentUserStore = CurrentUserStore.shared
    let hasUnreadInvitations: Bool

    let onScanTap: () -> Void
    let onAddTap: () -> Void
    let onBillTap: ((UUID) -> Void)?
    let onEventTap: () -> Void
    let onInboxTap: () -> Void
    var showsNavigationBar = false

    var body: some View {
        ZStack {
            AppTheme.figmaHero
                .ignoresSafeArea()

            VStack(spacing: 0) {
                hero
                activityPanel
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: viewModel.currentEvent)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: viewModel.currentEventBills.count)
        .navigationTitle("Событие")
        .navigationBarHidden(!showsNavigationBar)
    }

    private var hero: some View {
        VStack(spacing: 18) {
            homeHeader
            BalanceCardView(summary: viewModel.balanceSummary)

            Button(action: onEventTap) {
                if let currentEvent = viewModel.currentEvent {
                    CurrentEventCardView(event: currentEvent)
                } else {
                    emptyEventCard
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 20) {
                ScanButton(action: onScanTap)
                    .disabled(!viewModel.canMutateCurrentEventReceipts)
                    .opacity(viewModel.canMutateCurrentEventReceipts ? 1 : 0.45)
                AddButton(action: onAddTap)
                    .disabled(!viewModel.canMutateCurrentEventReceipts)
                    .opacity(viewModel.canMutateCurrentEventReceipts ? 1 : 0.45)
                InboxButton(
                    action: onInboxTap,
                    showsUnreadNotification: !networkMonitor.isConnected || hasUnreadInvitations
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var homeHeader: some View {
        HStack(spacing: 14) {
            Button {
                AppTabCenter.shared.openProfile()
            } label: {
                ZStack {
                    Circle().fill(Color(hex: "#4C6096"))
                    if let initials = currentUserStore.user?.initials {
                        Text(initials)
                            .font(AppTypography.montserrat(.semibold, size: 14, relativeTo: .caption))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "person")
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Открыть профиль")

            Text(currentUserStore.user?.name ?? "Профиль")
                .font(AppTypography.robotoMedium(size: 22, relativeTo: .title3))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Button(action: onEventTap) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#4C6096"), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Добавить событие")
        }
    }

    private var activityPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Активность")
                    .font(AppTypography.montserrat(.semibold, size: 20, relativeTo: .title3))
                    .foregroundStyle(.white)
                Spacer()
                Text("Все")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.14), in: Capsule())
            }

            if viewModel.currentEventBills.isEmpty {
                Text("Добавьте первый чек или платёж в событие")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.currentEventBills) { bill in
                            Button { onBillTap?(bill.id) } label: {
                                ActivityRow(bill: bill)
                            }
                            .buttonStyle(.plain)
                            if bill.id != viewModel.currentEventBills.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hex: "#7988B0"), in: RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var emptyEventCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("Выбрать событие")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(18)
        .background(.black.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
    }

    private var emptyBillsCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
            Text("Пока нет прикрепленных чеков")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.82))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.textSecondary.opacity(0.16), lineWidth: 1)
        )
    }

    private var loadingBillsCard: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(AppTheme.accent)
            Text("Загружаем чеки")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.82))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.textSecondary.opacity(0.16), lineWidth: 1)
        )
    }

    private var receiptLoadMoreButton: some View {
        Button {
            Task {
                await viewModel.loadMoreReceipts()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isLoadingMoreReceipts {
                    ProgressView()
                        .tint(AppTheme.accent)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(viewModel.isLoadingMoreReceipts ? "Загрузка..." : "Ещё чеки")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .foregroundStyle(AppTheme.accent)
            .background(.ultraThinMaterial)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isLoadingMoreReceipts)
    }
}

private struct BalanceCardView: View {
    let summary: EventBalanceSummary

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(summary.totalBalance.rubleText(signed: true, minimumFractionDigits: 0))
                .font(AppTypography.montserrat(.extraBold, size: 46, relativeTo: .largeTitle))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 104)
                .background(Color(hex: "#1F387C"), in: RoundedRectangle(cornerRadius: 22))

            HStack(spacing: 24) {
                balanceColumn(title: "Вы должны", amount: summary.youOwe)
                balanceColumn(title: "Вам должны", amount: summary.owedToYou)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 82)
            .background(Color(hex: "#7988B0"), in: RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 10)
            .offset(y: -10)
        }
        .frame(maxWidth: .infinity)
    }

    private func balanceColumn(title: String, amount: Double) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(AppTypography.montserrat(.semibold, size: 14, relativeTo: .caption))
            Text(amount.rubleText(signed: false, minimumFractionDigits: 0))
                .font(AppTypography.montserrat(.medium, size: 18, relativeTo: .headline))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
    }
}

private struct ActivityRow: View {
    let bill: BillListItem

    var body: some View {
        HStack(spacing: 12) {
            Text(bill.emoji)
                .font(.title3)
                .frame(width: 42, height: 42)
                .background(AppTheme.accent.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(bill.title)
                    .font(AppTypography.montserrat(.semibold, size: 15, relativeTo: .subheadline))
                    .foregroundStyle(.white)
                Text(bill.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            Text(bill.amount.rubleText(signed: bill.tone == .negative, minimumFractionDigits: 0))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 10)
    }
}

private struct ScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "viewfinder")
                    .font(.title2.weight(.semibold))
                    .frame(width: 62, height: 62)
                    .background(.black.opacity(0.90), in: Circle())
                Text("Сканировать чек")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .medium))
                    .frame(width: 62, height: 62)
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.90), in: Circle())
                Text("Добавить платёж")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct InboxButton: View {
    let action: () -> Void
    let showsUnreadNotification: Bool

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "tray")
                        .font(.title2.weight(.semibold))
                        .frame(width: 62, height: 62)
                        .foregroundStyle(.white)
                        .background(.black.opacity(0.90), in: Circle())

                    if showsUnreadNotification {
                        Circle()
                            .fill(.red)
                            .frame(width: 12, height: 12)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            }
                            .offset(x: 2, y: -2)
                    }
                }
                Text("Входящие")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Открыть входящие уведомления")
        .accessibilityValue(showsUnreadNotification ? "Есть непрочитанное уведомление" : "")
    }
}

#Preview {
    EventsHomeView(
        viewModel: EventsHomeViewModel(
            service: EventManagementService(eventsRepository: EventsDataRepository())
        ),
        networkMonitor: .shared,
        hasUnreadInvitations: false,
        onScanTap: {},
        onAddTap: {},
        onBillTap: nil,
        onEventTap: {},
        onInboxTap: {}
    )
}
