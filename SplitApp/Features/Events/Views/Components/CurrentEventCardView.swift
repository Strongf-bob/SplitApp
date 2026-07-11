import SwiftUI

struct CurrentEventCardView: View {
    let event: EventListItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.isClosed ? "lock.fill" : "calendar")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(event.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.60))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(18)
        .background(.black.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
    }
}
