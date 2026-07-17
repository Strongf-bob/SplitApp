import SwiftUI

struct SplitAppCard<Content: View>: View {
    var background: Color = .white
    var cornerRadius: CGFloat = SplitAppDesignTokens.cardCornerRadius
    var padding: CGFloat = 20
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                background,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}
