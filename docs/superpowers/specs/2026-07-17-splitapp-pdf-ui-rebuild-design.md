# SplitApp PDF UI Rebuild Design

## Goal

Rebuild the native iOS presentation layer so every state shown in `SplitAppDesign.pdf` is represented by a real, interactive SwiftUI screen while preserving the production authentication, friends, invitations, events, receipts, payments, profile, and Splitik behavior.

The supplied Swift package under `/Users/strongf/Downloads/Design Split Up/SplitApp/Sources/SplitAppUI` is the geometry, typography, color, copy, and asset reference. Its absolute-positioned `SplitAppNativeScreen` renderers are not production views because they contain static layers rather than controls.

## Product decisions

- The bottom navigation contains exactly four destinations in this order: `Главная`, `Друзья`, `Сплитик`, `События`.
- `Профиль` is not a bottom tab. It opens from the round user button in the shared top header.
- PDF page 2 is a broken placeholder and is replaced by a native Apple `confirmationDialog` with `Через AirDrop`, `По номеру телефона`, and `Из контактов`.
- Existing server-backed behavior remains authoritative. The redesign must not replace repository or API operations with local mock behavior.
- All visible buttons must either perform their named action, navigate to the corresponding working screen, or be disabled with the PDF disabled appearance until their prerequisites are satisfied.

## Visual source of truth

- Reference canvas: 402 x 874 points, adapted to the actual safe area and device width rather than scaled as a bitmap.
- Primary blue: `#1F387C`.
- Secondary blues: `#4C6096` and `#7988B0`.
- Primary surfaces: white, with `#F2F2F2` disabled controls and `#999999` secondary text.
- Primary display typography: bundled Montserrat weights.
- Supporting typography: Roboto and system SF Pro where the export specifies system controls.
- Reuse the bundled Splitik mascot and supplied image assets without changing their proportions.
- Use semantic design tokens in `AppTheme` and `AppTypography`; screen files must not duplicate raw colors or font registration.
- Preserve at least 44 x 44 point hit targets, accessibility labels, Dynamic Type scaling, safe-area clearance, loading feedback, and clear disabled states.

## App shell and navigation

`BottomTabConfiguration` becomes the single source of truth for the four tabs. Each tab keeps its own `NavigationStack` state so moving between tabs does not destroy drill-down history.

The shared header exposes:

- leading user button -> profile screen;
- trailing contextual action -> add friend, create event, or inbox depending on the active screen;
- the literal user name from `CurrentUserStore`.

Modal creation flows are item-driven sheets or full-screen covers with a real close action and primary arrow action. Deep links for friend invitations continue to switch to the Friends tab and populate the add-friend flow.

## PDF page mapping

### Page 1 - Friends

- Search filters confirmed friends.
- Friend rows are backed by `FriendsViewModel` data.
- Leading user button opens Profile.
- Trailing plus opens the native add-friend chooser.
- Bottom navigation highlights `Друзья`, not `Главная`.

### Page 2 - Native add-friend chooser

- Use `confirmationDialog` rather than recreating the broken Figma alert.
- AirDrop opens the system activity sheet with a SplitApp friend deep link.
- Phone opens page 3.
- Contacts opens `CNContactPickerViewController`, then transfers the selected phone into page 3.

### Page 3 - Add friend

- Name is resolved from the registered-user search and is not a free-form fake friend.
- Phone input searches the backend by a complete normalized number.
- Primary button sends the real friend request after a user is found.
- Close dismisses; arrow performs the current primary action.
- Loading, not-found, duplicate-request, success, and cancellation states remain visible and safe against stale async responses.

### Page 4 - Notifications

- List real pending event invitations from the backend.
- `Отказаться` declines and removes the item.
- `Вступить` accepts, removes the item, reloads events, and exposes the accepted event.
- Loading, empty, offline, and action-failure states use the same card geometry.

### Page 5 - Login

- Preserve real Yandex OAuth.
- Match the blue background, mascot, `Split.` wordmark, bottom Yandex button, and terms copy.
- The button shows progress and cannot submit twice.

### Pages 6 and 8 - Home states

- Render real aggregate balance, owed and receivable totals, active-event card, participant avatars, event total, and activity area.
- Empty/no-active-event state keeps the same composition and replaces missing content with explicit empty messaging rather than unrelated controls.
- Event card opens the active event.
- Header plus starts event creation.
- User button opens Profile.

### Page 7 - Events catalog

- The top CTA opens event creation.
- Every event card opens that event using the existing navigation route.
- Amounts, titles, and ordering come from the event repository.
- Loading, error, empty, and refresh behavior remain functional.

### Pages 9 and 11 - Payment editor

- Title is a real text field.
- `Добавить чек` opens receipt scanning/import and then page 10.
- `Добавить друзей` opens the real participant picker.
- `Создать платеж` persists through the existing receipt/payment flow and is disabled until the form is valid.
- `Создать со Сплитиком` opens Splitik with the event/payment context.
- Close preserves the existing unsaved-work behavior; arrow performs the valid primary action.

### Page 10 - Receipt preview

- Show the actual parsed receipt items and totals, not the sample receipt string.
- `Все верно` confirms parsed items and returns them to the payment editor.
- Close cancels preview; arrow confirms.
- Image-upload retry and server-validation behavior remain intact.

### Page 12 - Profile

- Open only from the shared user button.
- Show current name, avatar/initials, phone, email, and payment-transfer phone.
- Keep logout and existing profile actions below the visible PDF card without adding a fifth tab.
- Do not restore the removed permissions section.

### Pages 13 and 15 - Event editor

- Name is a real field.
- `Добавить друзей` opens the participant picker.
- `Добавить платеж` records the intent to continue directly into the payment editor after successful event creation.
- `Создать событие` is enabled only with a valid name and persists once, without duplicate retries.
- Close cancels; arrow performs creation when valid.

### Page 14 - Splitik

- Preserve server-backed conversation history and message sending.
- Match the white canvas, top back treatment, centered mascot greeting for the empty state, and bottom outlined composer with send button.
- The composer remains above the keyboard, supports interactive dismissal, and scrolls only for message/focus changes.

## State and component architecture

- `SplitAppTab`: the four tab identities and labels.
- `SplitAppHeader`: shared profile and contextual-action chrome.
- `SplitAppPrimaryButton`: blue, green, and disabled PDF button states.
- `SplitAppModalHeader`: close, centered title, and primary arrow.
- `SplitAppCard`: reusable 16/21/32-point card shapes from the reference.
- Existing feature ViewModels remain responsible for async work and business state.
- Presentation-only state remains local to views; mutually exclusive modals use an enum rather than parallel Boolean flags.
- Large screens are composed from small feature-specific sections so layout does not become mixed with networking or routing.

## Error handling and data integrity

- Network failures display an inline retry/error state without replacing server data with invented local success.
- Cancellation from view lifecycle tasks is not shown as an error.
- Search and submit buttons prevent duplicate concurrent actions.
- Receipt partial-success behavior and idempotency remain unchanged.
- Event creation persists once before optional payment continuation.
- Invitation and friendship actions retain access-token refresh and one-time retry behavior.

## Verification contract

- Add failing tests first for four-tab order, profile routing, modal destinations, primary-button enablement, event/payment continuation, receipt confirmation, and preserved deep-link routing.
- Run focused tests after each behavior change, then the full `SplitAppUnitTests` suite.
- Build and launch through Build iOS Apps/XcodeBuildMCP on the booted iPhone 17 Pro simulator.
- Capture and compare the reachable PDF states at the 402 x 874 reference aspect ratio, including empty and filled editor states.
- Exercise real accessibility elements with simulator UI inspection: four tabs, profile button, plus buttons, add-friend choices, form controls, create actions, invitation actions, and Splitik composer.
- Final acceptance requires a clean branch diff, successful simulator build, all tests green, no placeholder controls, and no fifth profile tab.

## Out of scope

- Replacing backend contracts that already support the flows.
- Copying device bezels, status bars, or the static Figma layer renderer into production screens.
- Adding new settings or permissions controls not present in the approved PDF.
- Introducing a new design language that overrides the supplied PDF colors, typography, and geometry.
