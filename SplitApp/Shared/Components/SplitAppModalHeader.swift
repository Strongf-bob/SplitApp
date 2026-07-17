import SwiftUI

struct SplitAppModalHeader: View {
    let title: String
    let onClose: () -> Void
    var canPerformPrimary = false
    var primarySystemImage = "arrow.up"
    var onPrimary: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            circularButton(
                systemImage: "xmark",
                foreground: AppTheme.textPrimary,
                background: AppTheme.disabledSurface,
                accessibilityLabel: "Закрыть",
                action: onClose
            )

            Text(title)
                .font(AppTypography.pdfCardTitle)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .lineLimit(1)

            if let onPrimary {
                circularButton(
                    systemImage: primarySystemImage,
                    foreground: canPerformPrimary ? .white : AppTheme.textSecondary,
                    background: canPerformPrimary ? AppTheme.pdfPrimaryBlue : AppTheme.disabledSurface,
                    accessibilityLabel: "Продолжить",
                    action: onPrimary
                )
                .disabled(!canPerformPrimary)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .frame(minHeight: 44)
    }

    private func circularButton(
        systemImage: String,
        foreground: Color,
        background: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: 44, height: 44)
                .background(background, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
