import SwiftUI

enum SplitAppActionButtonKind {
    case primary
    case secondary
    case success
}

struct SplitAppActionButton: View {
    let title: String
    var systemImage: String? = nil
    var kind: SplitAppActionButtonKind = .primary
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 19, weight: .semibold))
                }

                Text(title)
                    .font(AppTypography.pdfButton)
            }
            .foregroundStyle(isEnabled ? Color.white : AppTheme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(background, in: RoundedRectangle(cornerRadius: SplitAppDesignTokens.cardCornerRadius, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var background: Color {
        guard isEnabled else { return AppTheme.disabledSurface }
        return switch kind {
        case .primary: AppTheme.pdfPrimaryBlue
        case .secondary: AppTheme.pdfSecondaryBlue
        case .success: AppTheme.success
        }
    }
}
