import SwiftUI

struct SplitAppHeader: View {
    @ObservedObject private var currentUserStore = CurrentUserStore.shared

    var actionSystemImage: String? = nil
    var actionAccessibilityLabel: String = ""
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button {
                AppTabCenter.shared.openProfile()
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.pdfSecondaryBlue)

                    if let initials = currentUserStore.user?.initials, !initials.isEmpty {
                        Text(initials)
                            .font(AppTypography.montserrat(.semibold, size: 14, relativeTo: .caption))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 60, height: 60)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Открыть профиль")

            Text(currentUserStore.user?.name ?? "Профиль")
                .font(AppTypography.robotoMedium(size: 24, relativeTo: .title2))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 12)

            if let actionSystemImage, let onAction {
                Button(action: onAction) {
                    Image(systemName: actionSystemImage)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(AppTheme.pdfSecondaryBlue, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(actionAccessibilityLabel)
            }
        }
        .frame(minHeight: 60)
    }
}
