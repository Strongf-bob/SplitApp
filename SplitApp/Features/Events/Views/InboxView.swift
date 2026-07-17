import SwiftUI

struct InboxView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var networkMonitor: NetworkMonitor
    @ObservedObject private var viewModel: InvitationInboxViewModel

    init(
        viewModel: InvitationInboxViewModel,
        networkMonitor: NetworkMonitor
    ) {
        self.networkMonitor = networkMonitor
        self.viewModel = viewModel
    }

    private var incomingNotifications: [InboxNotification] {
        InboxNotificationPresentation.incoming(isConnected: networkMonitor.isConnected)
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                SplitAppModalHeader(
                    title: "Уведомления",
                    onClose: { dismiss() },
                    canPerformPrimary: true,
                    onPrimary: { dismiss() }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(spacing: 14) {
                    invitationContent
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .task { await viewModel.load() }
    }
}

private extension InboxView {
    @ViewBuilder
    var invitationContent: some View {
        if let notification = incomingNotifications.first {
            InboxNotificationCard(notification: notification)
        }

        if viewModel.isLoading, viewModel.invitations.isEmpty {
            ProgressView("Загружаем приглашения...")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        } else if viewModel.invitations.isEmpty, incomingNotifications.isEmpty {
            ContentUnavailableView(
                "Новых приглашений нет",
                systemImage: "tray",
                description: Text("Персональные приглашения в события появятся здесь.")
            )
            .foregroundStyle(AppTheme.textSecondary)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.invitations) { invitation in
                        EventInvitationCard(
                            invitation: invitation,
                            isUpdating: viewModel.updatingIDs.contains(invitation.id),
                            onDecline: { Task { await viewModel.decline(invitation) } },
                            onAccept: { Task { await viewModel.accept(invitation) } }
                        )
                    }
                }
            }
            .refreshable { await viewModel.load() }
        }

        if let message = viewModel.successMessage {
            Label(message, systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        if let message = viewModel.errorMessage {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct EventInvitationCard: View {
    let invitation: EventInvitationInboxItem
    let isUpdating: Bool
    let onDecline: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(invitation.creatorName) приглашает вас в событие «\(invitation.eventName)»")
                .font(AppTypography.montserrat(.bold, size: 19, relativeTo: .headline))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                actionButton(title: "Отказаться", fill: .white.opacity(0.14), action: onDecline)
                actionButton(title: "Вступить", fill: Color(hex: "#193679"), action: onAccept)
            }
        }
        .padding(20)
        .background(AppTheme.pdfTertiaryBlue, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
    }

    private func actionButton(title: String, fill: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if isUpdating {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(AppTypography.montserrat(.bold, size: 16, relativeTo: .headline))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(fill, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isUpdating)
    }
}

private struct InboxNotificationCard: View {
    let notification: InboxNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notification.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.red)
                .frame(width: 40, height: 40)
                .background(.red.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.red.opacity(0.24), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Непрочитанное уведомление. \(notification.title). \(notification.message)")
    }
}
