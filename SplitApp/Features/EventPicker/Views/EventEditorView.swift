import SwiftUI

struct EventEditorView: View {
    @ObservedObject var viewModel: EventsHomeViewModel
    let friendsRepository: any FriendsRepository
    let eventsRepository: any EventsRepository
    let onCreatePayment: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var eventName = ""
    @State private var availableUsers: [User] = []
    @State private var selectedUserIDs: Set<UUID> = []
    @State private var hasLoadedUsers = false
    @State private var showsFriendPicker = false
    @State private var createPaymentAfterEvent = false
    @State private var participantError: String?
    @State private var isDuplicate = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color(hex: "#CCCCCC"))
                    .frame(width: 36, height: 5)
                    .padding(.top, 5)
                    .padding(.bottom, 4)

                SplitAppModalHeader(
                    title: "Добавление события",
                    onClose: { dismiss() },
                    canPerformPrimary: canCreate,
                    onPrimary: createEvent
                )
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 15) {
                    eventNameField

                    SplitAppActionButton(
                        title: selectedUserIDs.isEmpty ? "Добавить друзей" : "Добавить друзей · \(selectedUserIDs.count)",
                        action: { showsFriendPicker = true }
                    )

                    SplitAppActionButton(
                        title: "Добавить платёж",
                        systemImage: createPaymentAfterEvent ? "checkmark.circle.fill" : nil,
                        action: { createPaymentAfterEvent.toggle() }
                    )

                    SplitAppActionButton(
                        title: viewModel.isCreatingEvent ? "Создание..." : "Создать событие",
                        isEnabled: canCreate,
                        action: createEvent
                    )

                    if isDuplicate {
                        Text("Событие с таким названием уже существует")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red)
                    }

                    if let participantError {
                        Text(participantError)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 31)
                .padding(.top, 18)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { isNameFocused = true }
        .sheet(isPresented: $showsFriendPicker) {
            friendPicker
        }
    }
}

private extension EventEditorView {
    var eventNameField: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Введите название события")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(AppTheme.textPrimary)

            TextField("Пример: Поездка на природу", text: $eventName)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppTheme.textPrimary)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit(createEvent)
                .onChange(of: eventName) { _, _ in isDuplicate = false }
                .frame(height: 57)
                .padding(.horizontal, 25)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isNameFocused ? AppTheme.pdfPrimaryBlue : AppTheme.textSecondary, lineWidth: 1)
                }
        }
    }

    var canCreate: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isCreatingEvent
    }

    var friendPicker: some View {
        NavigationStack {
            Group {
                if !hasLoadedUsers {
                    ProgressView("Загружаем друзей...")
                        .task { await loadAvailableUsers() }
                } else if availableUsers.isEmpty {
                    ContentUnavailableView(
                        "Нет подтверждённых друзей",
                        systemImage: "person.2",
                        description: Text("Сначала добавьте друга и дождитесь принятия заявки.")
                    )
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
                                    .foregroundStyle(AppTheme.pdfPrimaryBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Добавить друзей")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { showsFriendPicker = false }
                }
            }
        }
        .presentationCornerRadius(SplitAppDesignTokens.modalCornerRadius)
    }

    func loadAvailableUsers() async {
        availableUsers = ((try? await friendsRepository.listFriendships()) ?? [])
            .filter { $0.status == .accepted }
            .compactMap(\.peer)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        hasLoadedUsers = true
    }

    func createEvent() {
        let name = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !viewModel.isCreatingEvent else { return }

        guard !viewModel.latestEvents.contains(where: { $0.title.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            isDuplicate = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        isNameFocused = false
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
                    try? await Task.sleep(for: .seconds(1))
                }
            }

            dismiss()
            if createPaymentAfterEvent {
                try? await Task.sleep(for: .milliseconds(250))
                onCreatePayment(event.id)
            }
        }
    }
}
