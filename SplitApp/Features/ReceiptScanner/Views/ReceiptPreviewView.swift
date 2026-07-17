import SwiftUI

struct ReceiptPreviewView: View {
    let viewModel: ReceiptViewModel
    let onClose: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    SplitAppModalHeader(
                        title: "Просмотр чека",
                        onClose: onClose
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                    Text(item.name)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(NSDecimalNumber(decimal: item.amount).stringValue)
                                        .monospacedDigit()
                                }
                            }

                            Divider()

                            HStack {
                                Text("ИТОГ")
                                Spacer()
                                Text(NSDecimalNumber(decimal: viewModel.total).stringValue + " ₽")
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                            }
                        }
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 31)
                        .padding(.top, 30)
                        .padding(.bottom, 24)
                    }

                    SplitAppActionButton(
                        title: "Все верно",
                        kind: .success,
                        isEnabled: !viewModel.items.isEmpty,
                        action: onConfirm
                    )
                    .padding(.horizontal, 31)
                    .padding(.bottom, 26)
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.top, 10)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
