import SwiftUI

struct SocialButton: View {
    let icon: String
    let backgroundColor: Color
    let textColor: Color
    var hasBorder: Bool = false
    var title: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let title {
                HStack(spacing: 12) {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text(title)
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(textColor)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(hasBorder ? AppTheme.cardBorder : .clear, lineWidth: 1)
                )
            } else {
                Group {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(textColor)
                        .frame(width: 25, height: 50)
                        .padding(.horizontal, 20)
                        .background(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    hasBorder ? Color.gray.opacity(0.3) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                        .cornerRadius(25)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct SocialButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SocialButton(
                icon: "applelogo",
                backgroundColor: .black,
                textColor: .white
            ) {
                print("Apple sign in")
            }

            SocialButton(
                icon: "yandex",
                backgroundColor: .white,
                textColor: .black,
                hasBorder: true
            ) {
                print("Yandex sign in")
            }
        }
        .padding()
    }
}
