import SwiftUI

struct SplitLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isTitleVisible = false

    private let title = Array("Split")

    var body: some View {
        ZStack {
            AppTheme.figmaHero
                .ignoresSafeArea()

            HStack(spacing: 0) {
                ForEach(Array(title.enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(.system(size: 54, weight: .bold, design: .rounded))
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
