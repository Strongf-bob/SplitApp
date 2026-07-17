import SwiftUI

struct FriendsNavigationHeader: View {
    let onAddFriend: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text("Друзья")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button(action: onAddFriend) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.16), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Добавить друга")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 20)
    }
}
