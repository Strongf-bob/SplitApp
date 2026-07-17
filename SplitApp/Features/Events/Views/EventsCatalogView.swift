import SwiftUI

struct EventsCatalogView: View {
    @ObservedObject var viewModel: EventsHomeViewModel
    let onEventTap: (EventListItem) -> Void
    let onCreateTap: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                SplitAppHeader()
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                SplitAppActionButton(
                    title: "Добавить событие",
                    systemImage: "plus",
                    action: onCreateTap
                )
                .padding(.horizontal, 16)
                .padding(.top, 23)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if !viewModel.isLoaded {
                            ProgressView("Загружаем события...")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                        } else if viewModel.latestEvents.isEmpty {
                            ContentUnavailableView(
                                "Событий пока нет",
                                systemImage: "calendar.badge.plus",
                                description: Text("Создайте первое событие для совместных расходов.")
                            )
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.top, 24)
                        } else {
                            ForEach(viewModel.latestEvents) { event in
                                eventButton(event)
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        }

                        Color.clear.frame(height: 86)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 19)
                }
                .refreshable { await viewModel.refreshData() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension EventsCatalogView {
    func eventButton(_ event: EventListItem) -> some View {
        Button { onEventTap(event) } label: {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 10) {
                    Text(event.title)
                        .font(AppTypography.montserrat(.semibold, size: 22, relativeTo: .title3))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(event.isClosed ? "Закрыто" : abs(event.amount).rubleText(signed: false, minimumFractionDigits: 0))
                    .font(AppTypography.montserrat(.medium, size: 20, relativeTo: .title3))
                    .foregroundStyle(AppTheme.pdfTertiaryBlue)
                    .monospacedDigit()
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
            .background(AppTheme.pdfSecondaryBlue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Открыть событие \(event.title)")
    }
}
