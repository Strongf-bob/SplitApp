import SwiftUI

struct BillRowView: View {
    let bill: BillListItem
    let canDelete: Bool
    let onDelete: () -> Void
    let loadImageURL: (() async -> URL?)?
    let onTap: (() -> Void)?

    @State private var isDeleting: Bool = false
    @State private var showImageViewer = false
    @State private var imageViewerURL: URL?
    @State private var isLoadingImageURL = false

    init(
        bill: BillListItem,
        canDelete: Bool = true,
        onDelete: @escaping () -> Void,
        loadImageURL: (() async -> URL?)? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.bill = bill
        self.canDelete = canDelete
        self.onDelete = onDelete
        self.loadImageURL = loadImageURL
        self.onTap = onTap
    }

    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                receiptIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text(bill.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(bill.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Text(amountLabel)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        bill.tone == .neutral
                            ? AnyShapeStyle(AppTheme.textSecondary)
                            : AnyShapeStyle(
                                AppTheme.accentGradient
                            )
                    )
            }
        }
        .onTapGesture {
            onTap?()
        }
        .sheet(isPresented: $showImageViewer) {
            if let url = imageViewerURL {
                ReceiptImageViewerSheet(url: url, title: bill.title)
            }
        }
        .deleteTransition(isDeleting: isDeleting)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if canDelete {
                Button(role: .destructive) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        isDeleting = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onDelete()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Удалить")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .tint(.red)
            }
        }
    }

    @ViewBuilder
    private var receiptIcon: some View {
        if bill.hasImage {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task {
                    isLoadingImageURL = true
                    defer { isLoadingImageURL = false }
                    guard let url = await loadImageURL?() else { return }
                    imageViewerURL = url
                    showImageViewer = true
                }
            } label: {
                ZStack {
                    Text(bill.emoji)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)

                    if isLoadingImageURL {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 20, height: 20)
                            .background(AppTheme.cardBackground)
                            .clipShape(Circle())
                            .offset(x: 14, y: 14)
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            Text(bill.emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
        }
    }

    private var amountLabel: String {
        switch bill.tone {
        case .positive:
            bill.amount.rubleText(signed: true, minimumFractionDigits: 0)
        case .negative:
            bill.amount.rubleText(signed: true, minimumFractionDigits: 0)
        case .neutral:
            "Закрыт"
        }
    }
}
