# SplitApp PDF UI Rebuild Implementation Plan

> **Execution rule:** Follow this plan task by task with `executing-plans`. Add or update a failing test before each behavior change, keep the existing repositories/ViewModels authoritative, and validate visual states with Build iOS Apps/XcodeBuildMCP on the iPhone 17 Pro simulator.

**Goal:** Replace the current mixed/legacy SwiftUI presentation with the complete 15-page PDF design while retaining working authentication, friends, invitations, events, receipt/payment, profile, and Splitik flows.

**Architecture:** Keep business logic and networking in the existing ViewModels and repositories. Introduce a small PDF design component layer, reduce the app shell to four tabs, route Profile from the shared avatar, and compose each feature screen from accessible SwiftUI controls. Use enum/item-driven navigation for mutually exclusive modals and pass explicit callbacks from feature views to the navigation coordinator.

**Tech stack:** Swift 6, SwiftUI, Combine, ContactsUI, UIKit activity sheets, XCTest, XcodeBuildMCP/iOS Simulator.

---

## Task 1: Four-tab app shell and profile route

**Files:**
- Modify: `SplitAppTests/BottomTabPresentationTests.swift`
- Create: `SplitAppTests/AppTabCenterTests.swift`
- Modify: `SplitApp/Features/Navigation/Models/BottomTabPresentation.swift`
- Modify: `SplitApp/Features/Navigation/Models/BottomTabConfiguration.swift`
- Modify: `SplitApp/Features/Navigation/Views/BottomTabBarView.swift`

**Steps:**

1. Change the presentation test to require exactly this destination order: Home, Friends, Splitik, Events. Assert that Profile is not a tab.
2. Add a focused test proving that `AppTabCenter.openProfile()` and `closeProfile()` control the profile presentation state without changing the selected tab.
3. Run the two focused tests and confirm they fail against the five-tab implementation.
4. Remove the Profile tab identity and item. Keep the profile view factory on `BottomTabConfiguration` so the shell can present it independently.
5. Extend `AppTabCenter` with profile presentation state and explicit open/close functions.
6. Hide the native tab bar and add a custom safe-area inset matching the PDF floating white capsule. Every item remains a real `Button` with a 44-point hit target, label, icon, selected state, and accessibility traits.
7. Present Profile from the shell using the centralized state and preserve deep-link tab switching for Friends.
8. Re-run focused tests, then build the app in Simulator.

## Task 2: Shared PDF design components

**Files:**
- Create: `SplitApp/Shared/Components/SplitAppHeader.swift`
- Create: `SplitApp/Shared/Components/SplitAppModalHeader.swift`
- Create: `SplitApp/Shared/Components/SplitAppActionButton.swift`
- Create: `SplitApp/Shared/Components/SplitAppCard.swift`
- Modify: `SplitApp/Shared/Theme/AppTheme.swift`
- Modify: `SplitApp/Shared/Theme/AppTypography.swift`
- Modify: `SplitAppTests/AppTypographyTests.swift`

**Steps:**

1. Add tests for the PDF-specific font roles and stable semantic colors used by the new controls.
2. Run the focused theme tests and confirm the new roles are absent.
3. Add semantic colors for primary blue `#1F387C`, supporting blues, disabled surface, secondary text, success, and canvas.
4. Add Montserrat display/title/button roles with Dynamic Type scaling. Keep body/input roles readable and consistent with the export.
5. Implement the shared top header: avatar/name on the leading side and an optional contextual button on the trailing side.
6. Implement the modal header: close, centered title, and optional primary arrow with a disabled appearance.
7. Implement reusable large action buttons and rounded cards for the exact PDF radii and spacing.
8. Build once to catch availability, type inference, and accessibility issues before migrating screens.

## Task 3: Friends, add-friend chooser, add-friend form, and notifications

**Files:**
- Modify: `SplitApp/Features/Friends/Views/FriendsView.swift`
- Modify: `SplitApp/Features/Friends/Views/AddFriendView.swift`
- Modify: `SplitApp/Features/Friends/Views/Components/FriendsNavigationHeader.swift`
- Modify: `SplitApp/Features/Friends/Views/Components/SearchBar.swift`
- Modify: `SplitApp/Features/Friends/Views/Components/FriendRowView.swift`
- Modify: `SplitApp/Features/Events/Views/InboxView.swift`
- Modify: `SplitAppTests/FriendSearchTests.swift`
- Modify: `SplitAppTests/FriendsViewModelTests.swift`
- Modify: `SplitAppTests/InvitationInboxTests.swift`

**Steps:**

1. Extend existing tests to cover search result presentation, the resolved-user requirement before submit, and accept/decline removal from the inbox.
2. Run the focused tests and retain the existing async safety expectations.
3. Recompose Friends to match page 1: white canvas, PDF header, title, rounded search field, simple friend rows, plus chooser, and the custom four-tab shell below it.
4. Keep the native `confirmationDialog` for AirDrop, phone, and Contacts. AirDrop uses the system share sheet; Contacts passes the chosen number into the same backend lookup flow.
5. Recompose Add Friend to match page 3 with real phone input, resolved identity, status/error messaging, and a primary action that cannot race or submit duplicates.
6. Recompose Notifications to match page 4 with real invitation cards and functioning decline/join buttons.
7. Run focused tests and capture Friends, chooser, Add Friend, and Notifications in Simulator for visual comparison.

## Task 4: Home, events catalog, profile, and event creation

**Files:**
- Modify: `SplitApp/Features/Events/Views/EventsHomeView.swift`
- Modify: `SplitApp/Features/Events/Views/EventsCatalogView.swift`
- Modify: `SplitApp/Features/EventPicker/Views/EventPickerView.swift`
- Create: `SplitApp/Features/EventPicker/Views/EventEditorView.swift`
- Modify: `SplitApp/Features/Navigation/Views/EventsNavigationView.swift`
- Modify: `SplitApp/Features/Navigation/ViewModels/EventsNavigationViewModel.swift`
- Modify: `SplitApp/Features/UserProfile/Views/ProfileScreenView.swift`
- Modify: `SplitAppTests/EventsHomeViewModelTests.swift`
- Modify: `SplitAppTests/EventsNavigationTests.swift`
- Modify: `SplitAppTests/AppTabCenterTests.swift`

**Steps:**

1. Add tests for explicit create-event routing, event-card routing, event-editor validation, one-time persistence, and optional continuation into payment creation.
2. Run focused tests and confirm missing routing/validation cases fail.
3. Recompose Home pages 6/8 from real home data: aggregate balance, owed/receivable values, current event, avatars, event total, and activity/empty state. Remove unrelated scanner/add/inbox shortcuts from the visual surface.
4. Wire avatar to Profile, plus to event creation, event card to event detail, and activity to the real inbox where appropriate.
5. Recompose Events page 7 as a white canvas with shared header, blue `Добавить событие` CTA, and repository-backed event cards.
6. Extract event creation from the picker into `EventEditorView` matching pages 13/15. Keep participant selection, valid-name gating, create-once behavior, and payment continuation.
7. Recompose Profile page 12 with actual cached/server profile fields, data card, existing actions, logout, and an explicit close/back action. Do not restore Profile as a tab.
8. Run focused tests; capture filled/empty Home, Events, Profile, and filled/empty Event Editor states.

## Task 5: Payment editor and receipt preview

**Files:**
- Modify: `SplitApp/Features/BillEntry/Views/BillEntryView.swift`
- Modify: `SplitApp/Features/BillEntry/Views/BillItemRow.swift`
- Modify: `SplitApp/Features/BillEntry/Views/ParticipantPickerSheet.swift`
- Modify: `SplitApp/Features/BillEntry/ViewModels/BillViewModel.swift`
- Modify: `SplitApp/Features/ReceiptScanner/Views/CameraView.swift`
- Modify: `SplitApp/Features/ReceiptScanner/ViewModels/ReceiptViewModel.swift`
- Modify: `SplitApp/Features/Navigation/Views/EventsNavigationView.swift`
- Create: `SplitAppTests/PaymentEditorPresentationTests.swift`
- Modify: `SplitAppTests/EventsNavigationTests.swift`

**Steps:**

1. Add pure presentation tests for editor validity and available actions: title, receipt, participants, create payment, and Splitik continuation. Extend navigation tests for scanner -> receipt preview -> editor and editor -> Splitik.
2. Run focused tests and confirm the new presentation contract fails.
3. Recompose Bill Entry as pages 9/11: modal header, title field, `Добавить чек`, `Добавить друзей`, primary create action, Splitik action, and visible parsed items/total when filled.
4. Keep the existing item allocation and participant picker functionality accessible from the filled editor. Do not weaken receipt validation or idempotency behavior.
5. Add a receipt confirmation presentation matching page 10 using actual parsed items/totals. `Все верно` returns confirmed items to the editor; close cancels; arrow confirms.
6. Route `Добавить чек` into the real scanner/import flow and restore the in-progress draft after confirmation. Route `Создать со Сплитиком` into the Splitik tab with available event/payment context.
7. Exercise partial-success and image-upload retry paths using the existing ViewModel behavior.
8. Run focused tests and capture empty editor, receipt preview, and filled editor in Simulator.

## Task 6: Login and Splitik fidelity

**Files:**
- Modify: `SplitApp/Features/Authorization/Views/LoginView.swift`
- Modify: `SplitApp/Features/Navigation/Views/SplitikChatView.swift`
- Modify: `SplitAppTests/BootstrapAuthUseCaseTests.swift`
- Modify: `SplitAppTests/SplitikMessageRequestTests.swift`

**Steps:**

1. Preserve existing authentication and message-request tests, adding assertions only where presentation state drives duplicate-submit prevention.
2. Recompose Login page 5 to the exact blue canvas, mascot/wordmark proportions, bottom Yandex button, terms, progress, and disabled double-submit behavior.
3. Recompose Splitik page 14 to the exact white canvas, top treatment, empty-state mascot/copy, outlined composer, send button, keyboard-safe layout, history, and message bubbles.
4. Confirm Splitik retains server-backed history and send behavior.
5. Run focused tests and capture Login plus empty/filled Splitik in Simulator.

## Task 7: Full verification, review, and branch completion

**Files:**
- Modify only files required by defects found during verification.

**Steps:**

1. Run the complete `SplitAppUnitTests` scheme through XcodeBuildMCP and record the exact pass/fail count.
2. Build and launch the app on the booted iPhone 17 Pro simulator.
3. Inspect the accessibility tree for the four tab buttons, avatar/profile route, contextual plus buttons, friend chooser actions, form fields, invitation actions, create actions, and Splitik composer.
4. Capture every reachable PDF state and compare layout, copy, color, typography, spacing, disabled state, and safe-area behavior against `/Users/strongf/Downloads/SplitAppDesign.pdf`.
5. Search production Swift files for placeholder labels and static exported renderer usage. Confirm there are no five-tab remnants and no fake local success paths.
6. Review the full branch diff for regressions, large mixed-responsibility views, accidental user-file changes, and dead components.
7. Fix every validated issue and repeat the full test/build/visual checks.
8. Commit coherent batches with Conventional Commit messages. Keep the verified feature branch ready for the requested merge/push workflow.

## Acceptance checklist

- Exactly four bottom tabs, in PDF order.
- Profile opens from the shared avatar and never appears as a fifth tab.
- All 15 PDF pages have a real production SwiftUI state or the explicitly approved native Apple replacement for broken page 2.
- Every visible control performs its named real action or is clearly disabled until valid.
- Existing repositories, API calls, auth, deep links, idempotency, and partial-success recovery remain authoritative.
- Full unit test scheme passes.
- Simulator build launches and the accessibility tree exposes all primary interactions.
- Visual captures match the PDF at the reference aspect ratio without copying static Figma layer code.
