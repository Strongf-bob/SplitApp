# SplitApp Frontend Backend Alignment TODO

## Done in `strongf/frontend-backend-integration`

- [x] Load `FriendsView` debts from backend balances.
- [x] Use backend payments endpoint for `settleDebt()`.
- [x] Keep payment creation sender as the current user; incoming debts are read-only on the current user's device.
- [x] Wire receipt swipe-delete to `DELETE /api/receipts/{id}`.
- [x] Remove `LocalFriendsStore` and local-only friend debt models.
- [x] Remove the dead dot-only `.swift` file.
- [x] Keep CoreData `Payment` mapping in use through `PaymentsDataRepository`.
- [x] Normalize common backend/network errors before showing UI messages.
- [x] Add offline/context banner in `FriendsView`.
- [x] Decode backend money fields from either JSON numbers or decimal strings.
- [x] Stop using stored receipt `image_url` as a permanent public URL for viewing; fetch presigned URLs before opening receipt photos.
- [x] Block receipt mutations when an event is closed.
- [x] Show event close action only to the event creator.

## Still To Do

- [ ] Build a dedicated payment flow: create payment screen, event payment list, receiver-only confirmation button, read-only status for sender/other users, and delete unconfirmed payment.
- [ ] Build an event participants screen: list participants, add/remove participants, hide management actions from non-creators, and respect closed-event read-only state.
- [ ] Add event rename UI and gate it to the event creator.
- [ ] Add receipt photo upload from gallery and expose upload/delete actions only when the event is open.
- [ ] Rework friends/search/invites. `/api/users` now returns only visible users, so adding new people needs a dedicated invite/search backend contract or a product decision to limit selection to visible users.
- [ ] Add profile financial stats (`closedBillsAmount` / `openBillsAmount`) after backend exposes a stable endpoint/metric contract.
- [ ] Replace `Double` money domain/UI models with `Decimal` or minor-unit `Int` end to end. Current code is string-safe at DTO decode boundaries, but many domain/view models still store money as `Double`.
- [ ] Add frontend pagination once backend pagination contracts are designed.
