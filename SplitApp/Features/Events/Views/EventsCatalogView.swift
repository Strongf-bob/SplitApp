import SwiftUI

struct EventsCatalogView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case invitations = "Приглашения"
        case active = "Активные"
        case completed = "Завершённые"

        var id: Self { self }
    }

    @ObservedObject var viewModel: EventsHomeViewModel
    let onEventTap: (EventListItem) -> Void
    @State private var filter: Filter = .active

    var body: some View {
        ZStack {
            AppTheme.figmaHero.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("События")
                    .font(AppTypography.montserrat(.extraBold, size: 36, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 20)

                VStack(spacing: 14) {
                    Picker("Фильтр событий", selection: $filter) {
                        ForEach(Filter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            if filteredEvents.isEmpty {
                                Text(emptyText)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                            } else {
                                ForEach(filteredEvents) { event in
                                    Button {
                                        onEventTap(event)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(event.title)
                                                .font(.headline)
                                                .foregroundStyle(AppTheme.textPrimary)
                                            Text(event.subtitle)
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(AppTheme.contentSurface, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                .background(AppTheme.contentSurface.ignoresSafeArea(edges: .bottom))
            }
        }
        .navigationBarHidden(true)
    }

    private var filteredEvents: [EventListItem] {
        switch filter {
        case .invitations:
            []
        case .active:
            viewModel.latestEvents.filter { !$0.isClosed }
        case .completed:
            viewModel.latestEvents.filter(\.isClosed)
        }
    }

    private var emptyText: String {
        switch filter {
        case .invitations: "Нет приглашений"
        case .active: "Нет активных событий"
        case .completed: "Нет завершённых событий"
        }
    }
}
