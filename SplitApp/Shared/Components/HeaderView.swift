import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("imgLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 104)
                .accessibilityHidden(true)

            Text("SplitApp")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Расходы вместе — без лишних расчётов")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 24)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HeaderView()
            Spacer()
        }
        .background(Color.white)
    }
}
