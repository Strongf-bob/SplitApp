import SwiftUI

struct SplitLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isTitleVisible = false

    private let title = Array("Split")

    var body: some View {
        ZStack {
            AppTheme.figmaHero
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Image("asset-0da481f91365")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 108, height: 110)

                HStack(spacing: 0) {
                    ForEach(Array(title.enumerated()), id: \.offset) { index, letter in
                        Text(String(letter))
                            .font(AppTypography.montserrat(.extraBold, size: 54, relativeTo: .largeTitle))
                            .foregroundStyle(.white)
                            .opacity(isTitleVisible ? 1 : 0)
                            .offset(y: isTitleVisible ? 0 : 12)
                            .animation(
                                reduceMotion
                                    ? nil
                                    : .easeOut(duration: 0.16).delay(Double(index) * 0.045),
                                value: isTitleVisible
                            )
                    }
                }
            }
            .accessibilityLabel("Split")
        }
        .onAppear {
            isTitleVisible = true
        }
    }
}

#Preview {
    SplitLaunchView()
}
