import SwiftUI

struct FriendsNavigationHeader: View {
    var body: some View {
        HStack(alignment: .center) {
            Text("Друзья")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 20)
    }
}
