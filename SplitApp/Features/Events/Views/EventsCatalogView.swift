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
    let onCreateTap: () -> Void
    @State private var filter: Filter = .active

    var body: some View {
        ZStack {
            AppTheme.figmaHero.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("События")
                        .font(AppTypography.montserrat(.extraBold, size: 36, relativeTo: .largeTitle))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: onCreateTap) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "#4C6096"), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Добавить событие")
                }
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
                                                .font(AppTypography.montserrat(.semibold, size: 20, relativeTo: .headline))
                                                .foregroundStyle(.white)
                                            Text(event.subtitle)
                                                .font(AppTypography.montserrat(.medium, size: 16, relativeTo: .subheadline))
                                                .foregroundStyle(.white.opacity(0.56))
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .background(Color(hex: "#4C6096"), in: RoundedRectangle(cornerRadius: 16))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.white, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                .background(Color.white.ignoresSafeArea(edges: .bottom))
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
