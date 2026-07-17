import SwiftUI

struct EventsHomeView: View {
    @ObservedObject var viewModel: EventsHomeViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    @Environment(\.dismiss) private var dismiss
    let hasUnreadInvitations: Bool

    let onScanTap: () -> Void
    let onAddTap: () -> Void
    let onBillTap: ((UUID) -> Void)?
    let onEventTap: () -> Void
    let onCreateEventTap: () -> Void
    let onInboxTap: () -> Void
    var showsNavigationBar = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                if showsNavigationBar {
                    SplitAppModalHeader(title: "Событие", onClose: { dismiss() })
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                } else {
                    SplitAppHeader(
                        actionSystemImage: "plus",
                        actionAccessibilityLabel: "Добавить событие",
                        onAction: onCreateEventTap
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                balanceCard
                    .padding(.horizontal, 16)
                    .padding(.top, 22)

                eventCard
                    .padding(.horizontal, 16)
                    .padding(.top, 18)

                activityCard
                    .padding(.horizontal, 16)
                    .padding(.top, 19)
                    .padding(.bottom, 4)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentEvent?.id)
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentEventBills.count)
    }
}

private extension EventsHomeView {
    var balanceCard: some View {
        ZStack(alignment: .bottom) {
            Text(viewModel.balanceSummary.totalBalance.rubleText(signed: false, minimumFractionDigits: 0))
                .font(AppTypography.montserrat(.extraBold, size: 50, relativeTo: .largeTitle))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 125, alignment: .top)
                .padding(.top, 20)
                .background(AppTheme.pdfPrimaryBlue, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
                .frame(maxHeight: .infinity, alignment: .top)

            HStack(spacing: 22) {
                balanceColumn(title: "Вы должны", amount: viewModel.balanceSummary.youOwe)
                balanceColumn(title: "Вам должны", amount: viewModel.balanceSummary.owedToYou)
            }
            .padding(.horizontal, 26)
            .frame(maxWidth: .infinity, minHeight: 102)
            .background(AppTheme.pdfSecondaryBlue, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
            .padding(.horizontal, 15)
        }
        .frame(height: 201)
    }

    func balanceColumn(title: String, amount: Double) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(AppTypography.montserrat(.semibold, size: 15, relativeTo: .subheadline))
            Text(amount.rubleText(signed: false, minimumFractionDigits: 0))
                .font(AppTypography.montserrat(.medium, size: 20, relativeTo: .title3))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
    }

    var eventCard: some View {
        Button(action: onEventTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Text(viewModel.currentEvent?.title ?? "Выберите событие")
                        .font(AppTypography.montserrat(.semibold, size: 25, relativeTo: .title2))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 5)
                }

                Spacer(minLength: 0)

                HStack(alignment: .bottom, spacing: 12) {
                    HomeParticipantStack(users: viewModel.currentEventParticipants)

                    Spacer(minLength: 8)

                    Text(viewModel.currentEventReceiptsTotal.rubleText(signed: false, minimumFractionDigits: 0))
                        .font(AppTypography.montserrat(.medium, size: 20, relativeTo: .title3))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 145, maxHeight: 145, alignment: .leading)
            .background(AppTheme.pdfSecondaryBlue, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.currentEvent == nil ? "Выбрать событие" : "Открыть событие \(viewModel.currentEvent?.title ?? "")")
    }

    var activityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Активности")
                    .font(AppTypography.montserrat(.semibold, size: 20, relativeTo: .title3))
                    .foregroundStyle(.white)

                Spacer()

                Button(action: onInboxTap) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)

                        if hasUnreadInvitations || !networkMonitor.isConnected {
                            Circle()
                                .fill(.red)
                                .frame(width: 9, height: 9)
                                .offset(x: -3, y: 3)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Открыть уведомления")
            }

            if showsNavigationBar, viewModel.canMutateCurrentEventReceipts {
                HStack(spacing: 10) {
                    compactAction(title: "Сканировать чек", systemImage: "viewfinder", action: onScanTap)
                    compactAction(title: "Добавить платёж", systemImage: "plus", action: onAddTap)
                }
            }

            if viewModel.currentEventBills.isEmpty {
                Text(viewModel.currentEvent == nil ? "Создайте или выберите событие" : "Здесь появятся платежи события")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.currentEventBills) { bill in
                            Button { onBillTap?(bill.id) } label: {
                                HomeActivityRow(bill: bill)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 23)
        .padding(.trailing, 12)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.pdfTertiaryBlue, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
    }

    func compactAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

private struct HomeParticipantStack: View {
    let users: [User]

    var body: some View {
        HStack(spacing: -15) {
            if users.indices.contains(0) { avatar(users[0]) }
            if users.indices.contains(1) { avatar(users[1]) }
            if users.indices.contains(2) { avatar(users[2]) }
            if users.indices.contains(3) { avatar(users[3]) }
        }
    }

    private func avatar(_ user: User) -> some View {
        ZStack {
            Circle().fill(avatarColor(for: user.id))
            Text(initials(for: user.name))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 50, height: 50)
        .overlay(Circle().stroke(AppTheme.pdfSecondaryBlue, lineWidth: 4))
    }

    private func avatarColor(for id: UUID) -> Color {
        let palette: [Color] = [Color(hex: "#BBB2D5"), Color(hex: "#C6CBDC"), Color(hex: "#CB9889"), Color(hex: "#4A5565")]
        return palette[Int(id.uuidString.hashValue.magnitude % UInt(palette.count))]
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
}

private struct HomeActivityRow: View {
    let bill: BillListItem

    var body: some View {
        HStack(spacing: 11) {
            Text(bill.emoji)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(bill.title)
                    .font(AppTypography.montserrat(.semibold, size: 15, relativeTo: .subheadline))
                Text(bill.subtitle)
                    .font(.caption)
                    .opacity(0.7)
            }

            Spacer()

            Text(bill.amount.rubleText(signed: bill.tone == .negative, minimumFractionDigits: 0))
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.vertical, 8)
    }
}

#Preview {
    EventsHomeView(
        viewModel: EventsHomeViewModel(service: EventManagementService(eventsRepository: EventsDataRepository())),
        networkMonitor: .shared,
        hasUnreadInvitations: false,
        onScanTap: {},
        onAddTap: {},
        onBillTap: nil,
        onEventTap: {},
        onCreateEventTap: {},
        onInboxTap: {}
    )
}
