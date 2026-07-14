import SwiftUI

struct FriendsNavigationHeader: View {
    let onInvite: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text("Друзья")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button(action: onInvite) {
                Image(systemName: "airdrop")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(.white)
            .accessibilityLabel("Пригласить друга через AirDrop")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 20)
    }
}
