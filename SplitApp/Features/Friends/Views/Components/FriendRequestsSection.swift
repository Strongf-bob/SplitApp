import SwiftUI

struct FriendRequestsSection: View {
    let incoming: [Friendship]
    let outgoing: [Friendship]
    let updatingIDs: Set<UUID>
    let onAccept: (Friendship) -> Void
    let onReject: (Friendship) -> Void

    var body: some View {
        if !incoming.isEmpty || !outgoing.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Заявки в друзья")
                    .padding(.horizontal, 20)

                VStack(spacing: 8) {
                    ForEach(incoming) { friendship in
                        requestCard(friendship, isIncoming: true)
                    }

                    ForEach(outgoing) { friendship in
                        requestCard(friendship, isIncoming: false)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func requestCard(_ friendship: Friendship, isIncoming: Bool) -> some View {
        let isUpdating = updatingIDs.contains(friendship.id)

        HStack(spacing: 12) {
            avatar(for: friendship)

            VStack(alignment: .leading, spacing: 4) {
                Text(friendship.peer?.name ?? "Пользователь")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(isIncoming ? "Хочет добавить вас в друзья" : "Заявка отправлена")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 8)

            if isIncoming {
                HStack(spacing: 8) {
                    Button {
                        onReject(friendship)
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel("Отклонить заявку от \(friendship.peer?.name ?? "пользователя")")
                    .disabled(isUpdating)

                    Button {
                        onAccept(friendship)
                    } label: {
                        if isUpdating {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 36, height: 36)
                        } else {
                            Image(systemName: "checkmark")
                                .frame(width: 36, height: 36)
                        }
                    }
                    .accessibilityLabel("Принять заявку от \(friendship.peer?.name ?? "пользователя")")
                    .disabled(isUpdating)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            } else {
                Text("Ожидает")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private func avatar(for friendship: Friendship) -> some View {
        Text(initials(for: friendship.peer?.name ?? "?"))
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(AppTheme.accent)
            .clipShape(Circle())
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }
}
