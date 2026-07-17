import SwiftUI

struct EventPickerView: View {
    @ObservedObject var viewModel: EventsHomeViewModel
    private let friendsRepository: any FriendsRepository
    private let eventsRepository: any EventsRepository
    private let onCreatePayment: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateSheet = false
    @State private var showSplitikCreation = false
    @State private var showFriendPicker = false
    @State private var eventPendingDeletion: EventListItem?
    @State private var deletingEventID: UUID?

    @State private var newEventName = ""
    @State private var availableUsers: [User] = []
    @State private var selectedUserIDs: Set<UUID> = []
    @State private var participantError: String?
    @State private var createPaymentAfterEvent = false
    @State private var nameIsDuplicate = false
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var isNameFieldFocused: Bool

    init(
        viewModel: EventsHomeViewModel,
        friendsRepository: any FriendsRepository,
        eventsRepository: any EventsRepository,
        onCreatePayment: @escaping (UUID) -> Void
    ) {
        self.viewModel = viewModel
        self.friendsRepository = friendsRepository
        self.eventsRepository = eventsRepository
        self.onCreatePayment = onCreatePayment
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            AppTheme.backgroundRadialGlow.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Заголовок списка

                HStack(alignment: .center) {
                    sectionLabel("ВЫБРАТЬ СОБЫТИЕ")
                    Spacer()
                    Button {
                        newEventName = ""
                        showCreateSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("Новое")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppTheme.accentGradient)
                        .foregroundStyle(AppTheme.accentForeground)
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.accent.opacity(0.35), radius: 8, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 10)

                List {
                    ForEach(viewModel.latestEvents) { event in
                        eventRow(event)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.latestEvents.map(\.id))
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("События")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Удалить событие?", isPresented: deleteConfirmationBinding) {
            Button("Удалить", role: .destructive) {
                guard let event = eventPendingDeletion else { return }

                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    deletingEventID = event.id
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    viewModel.deleteEvent(event)
                    deletingEventID = nil
                    eventPendingDeletion = nil
                }
            }

            Button("Отмена", role: .cancel) {
                eventPendingDeletion = nil
            }
        } message: {
            Text("Вы точно хотите удалить событие «\(eventPendingDeletion?.title ?? "")»?")
        }
        .fullScreenCover(isPresented: $showCreateSheet) {
            createEventSheet
        }
        .sheet(isPresented: $showFriendPicker) {
            eventFriendPicker
        }
    }

    private func eventRow(_ event: EventListItem) -> some View {
        SwipeableEventRow(
            event: event,
            isSelected: event.id == viewModel.currentEvent?.id,
            isDeleting: deletingEventID == event.id,
            canDelete: event.creatorId == viewModel.currentUserId,
            canClose: event.creatorId == viewModel.currentUserId && !event.isClosed,
            onTap: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    viewModel.selectEvent(event)
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { dismiss() }
            },
            onDelete: {
                eventPendingDeletion = event
            },
            onClose: {
                viewModel.closeEvent(event)
            }
        )
    }

    // MARK: - Create Event Sheet

    private var createEventSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                AppTheme.backgroundRadialGlow.ignoresSafeArea()

                VStack(spacing: 14) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("НАЗВАНИЕ СОБЫТИЯ")
                            .font(AppTypography.montserrat(.semibold, size: 14, relativeTo: .caption))
                            .tracking(1.2)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 4)

                        TextField("Например, День рождения", text: $newEventName)
                            .font(AppTypography.montserrat(.medium, size: 18, relativeTo: .headline))
                            .foregroundStyle(AppTheme.textPrimary)
                            .tint(AppTheme.accent)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        nameIsDuplicate ? Color.red :
                                            isNameFieldFocused ? AppTheme.accent : AppTheme.accent.opacity(0.2),
                                        lineWidth: (nameIsDuplicate || isNameFieldFocused) ? 2 : 1
                                    )
                            )
                            .focused($isNameFieldFocused)
                            .offset(x: shakeOffset)
                            .onChange(of: newEventName) { _, _ in
                                if nameIsDuplicate { nameIsDuplicate = false }
                            }
                            .onSubmit { submitCreate() }

                        if nameIsDuplicate {
                            Text("Событие с таким названием уже существует")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)

                    eventSetupButton(
                        title: selectedUserIDs.isEmpty
                            ? "Добавить друзей"
                            : "Выбрано друзей: \(selectedUserIDs.count)",
                        systemImage: "person.2.fill"
                    ) {
                        showFriendPicker = true
                    }

                    eventSetupButton(
                        title: createPaymentAfterEvent ? "Платёж будет добавлен" : "Добавить платёж",
                        systemImage: createPaymentAfterEvent ? "checkmark.circle.fill" : "creditcard"
                    ) {
                        createPaymentAfterEvent.toggle()
                    }

                    GlassButton(
                        title: viewModel.isCreatingEvent ? "Создание…" : "Создать событие"
                    ) {
                        submitCreate()
                    }
                    .padding(.horizontal, 20)
                    .disabled(
                        viewModel.isCreatingEvent ||
                            newEventName.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                    .opacity(newEventName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    .animation(.easeInOut(duration: 0.2), value: newEventName.isEmpty)

                    Button {
                        showSplitikCreation = true
                    } label: {
                        Label("Создать со Сплитиком", systemImage: "sparkles")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.accent.opacity(0.32), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)

                    if let participantError {
                        Text(participantError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Text("Способ деления указывается при добавлении чека.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Новое событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { showCreateSheet = false }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { isNameFieldFocused = true }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .fullScreenCover(isPresented: $showSplitikCreation) {
            SplitikChatView(initialDraft: "Помоги создать событие для совместных расходов")
        }
    }

    private var eventFriendPicker: some View {
        NavigationStack {
            Group {
                if availableUsers.isEmpty {
                    ProgressView("Загружаем друзей...")
                        .task { await loadAvailableUsers() }
                } else {
                    List(availableUsers, id: \.id) { user in
                        Button {
                            if selectedUserIDs.contains(user.id) {
                                selectedUserIDs.remove(user.id)
                            } else {
                                selectedUserIDs.insert(user.id)
                            }
                        } label: {
                            HStack {
                                Text(user.name)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Image(systemName: selectedUserIDs.contains(user.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Добавить друзей")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { showFriendPicker = false }
                }
            }
        }
    }

    private func eventSetupButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppTypography.montserrat(.medium, size: 18, relativeTo: .headline))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color(hex: "#1F387C"), in: RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private func loadAvailableUsers() async {
        availableUsers = ((try? await friendsRepository.listFriendships()) ?? [])
            .filter { $0.status == .accepted }
            .compactMap(\.peer)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Helpers

    private func submitCreate() {
        let name = newEventName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !viewModel.isCreatingEvent else { return }

        if viewModel.latestEvents.contains(where: { $0.title.lowercased() == name.lowercased() }) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { shakeOffset = 10 }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3).delay(0.1)) { shakeOffset = -8 }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4).delay(0.2)) { shakeOffset = 0 }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            nameIsDuplicate = true
            return
        }

        isNameFieldFocused = false
        Task {
            guard let event = await viewModel.createEvent(name: name) else { return }
            if !selectedUserIDs.isEmpty {
                do {
                    _ = try await eventsRepository.addParticipants(
                        eventId: event.id,
                        AddParticipantsCommand(userIds: Array(selectedUserIDs))
                    )
                } catch {
                    participantError = "Событие создано, но не всех друзей удалось добавить."
                    return
                }
            }
            showCreateSheet = false
            try? await Task.sleep(nanoseconds: 250_000_000)
            dismiss()
            if createPaymentAfterEvent {
                onCreatePayment(event.id)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(AppTheme.textSecondary)
    }

    private func amountColor(for tone: EventAmountTone) -> Color {
        switch tone {
        case .positive: Color(red: 0.17, green: 0.76, blue: 0.32)
        case .negative: Color(red: 0.92, green: 0.29, blue: 0.29)
        case .neutral: AppTheme.textSecondary
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { eventPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    eventPendingDeletion = nil
                }
            }
        )
    }
}

private struct SwipeableEventRow: View {
    let event: EventListItem
    let isSelected: Bool
    let isDeleting: Bool
    let canDelete: Bool
    let canClose: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    var body: some View {
        Button(action: onTap) {
            GlassCard(padding: 14) {
                HStack(spacing: 12) {
                    Text(event.emoji)
                        .font(.system(size: 26))
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(event.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(event.subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.accent)
                            .transition(.scale.combined(with: .opacity))
                    } else if event.isClosed {
                        Text("Закрыто")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Text(event.amount.rubleText(signed: true, minimumFractionDigits: 0))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(amountColor)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
        .deleteTransition(isDeleting: isDeleting)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if canDelete {
                if canClose {
                    Button {
                        onClose()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Закрыть")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .tint(.orange)
                }

                Button(role: .destructive) {
                    onDelete()
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

    private var amountColor: Color {
        switch event.tone {
        case .positive:
            Color(red: 0.17, green: 0.76, blue: 0.32)
        case .negative:
            Color(red: 0.92, green: 0.29, blue: 0.29)
        case .neutral:
            AppTheme.textSecondary
        }
    }
}
