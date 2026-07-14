# Real Friends in iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render real accepted friendships and actionable pending friend requests in the iOS Friends screen, while keeping active-event debts as a separate financial view.

**Architecture:** Add a friendship DTO/domain/repository layer over the existing `/api/friends` backend API. `FriendsViewModel` will derive accepted friendships and request states from that source, while independently loading active-event balances to derive debts. SwiftUI composes the new request section from view-model state and reloads server truth after every mutation.

**Tech Stack:** Swift, SwiftUI, Foundation, XCTest, existing `APIClient` and backend `SplitAppBackend` friendship API.

## Global Constraints

- Do not change the backend: `/api/friends` and its request lifecycle already exist.
- Do not infer friendship from `/api/users`, event membership, or balances.
- Keep debts event-scoped and preserve the existing payment-settlement rules.
- Do not introduce local friendship persistence as a source of truth.
- Keep unrelated working-tree changes untouched.

---

## File Structure

- `SplitApp/Domain/Models/Friendship.swift`: stable domain state for a friendship record and its peer.
- `SplitApp/Data/DTOs/FriendshipDTO.swift`: backend response decoding, including a nullable peer user.
- `SplitApp/Data/Network/Endpoints/FriendshipEndpoints.swift`: all friendship endpoint paths and methods.
- `SplitApp/Domain/Repositories/FriendsRepositoryContract.swift`: list, accept, reject, and remove contract.
- `SplitApp/Data/Repositories/FriendsDataRepository.swift`: API implementation and pagination.
- `SplitApp/Features/Friends/ViewModels/FriendsViewModel.swift`: independently derive friend/request/debt state and execute request actions.
- `SplitApp/Features/Friends/Views/FriendsView.swift`: compose accepted friends, requests, and debt sections.
- `SplitApp/Features/Friends/Views/Components/FriendRequestsSection.swift`: focused request row UI with accept/reject controls.
- `SplitAppTests/FriendsDataRepositoryTests.swift`: endpoint and DTO mapping coverage via URL protocol.
- `SplitAppTests/FriendsViewModelTests.swift`: business-state separation and mutation reload coverage.

---

### Task 1: Model and fetch real friendships

**Files:**
- Create: `SplitApp/Domain/Models/Friendship.swift`
- Create: `SplitApp/Data/DTOs/FriendshipDTO.swift`
- Create: `SplitApp/Data/Network/Endpoints/FriendshipEndpoints.swift`
- Modify: `SplitApp/Domain/Repositories/FriendsRepositoryContract.swift`
- Modify: `SplitApp/Data/Repositories/FriendsDataRepository.swift`
- Create: `SplitAppTests/FriendsDataRepositoryTests.swift`

**Interfaces:**
- Produces `enum FriendshipStatus: String, Decodable { case requested, accepted, rejected, removed, blocked }` and `struct Friendship: Identifiable, Equatable` with `id`, `requesterId`, `addresseeId`, `status`, and optional `peer: User`.
- Produces `FriendsRepository.listFriendships() async throws -> [Friendship]`, `acceptFriendship(id:)`, `rejectFriendship(id:)`, and `removeFriendship(id:)`.
- Consumes `PageResponse<FriendshipDTO>` and existing `APIClient.request` / `requestWithoutResponse`.

- [ ] **Step 1: Write failing repository/model tests**

Create `FriendsDataRepositoryTests` with a URL protocol that returns a paginated `/api/friends` response containing one accepted relationship and a peer user. Assert that `listFriendships()` maps UUIDs, `accepted` status, and peer name. Add one test each that invokes accept, reject, and remove and asserts the expected path and HTTP method.

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:SplitAppTests/FriendsDataRepositoryTests`

Expected: compilation failure because friendship types and repository methods do not exist.

- [ ] **Step 3: Implement the minimal model, endpoint, and repository layer**

Add the DTO with `id`, `requester_id`, `addressee_id`, `status`, `peer`, `created_at`, and `updated_at`, mapping snake-case keys through `CodingKeys`. Add endpoint structs for `GET /api/friends`, `POST /api/friends/{id}/accept`, `POST /api/friends/{id}/reject`, and `DELETE /api/friends/{id}`. Fetch all pages in `FriendsDataRepository`; map each DTO into `Friendship`; use `APIClient.requestWithoutResponse` for deletion.

- [ ] **Step 4: Run focused tests to verify they pass**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:SplitAppTests/FriendsDataRepositoryTests`

Expected: PASS.

- [ ] **Step 5: Commit the focused change**

Run: `git add SplitApp/Domain/Models/Friendship.swift SplitApp/Data/DTOs/FriendshipDTO.swift SplitApp/Data/Network/Endpoints/FriendshipEndpoints.swift SplitApp/Domain/Repositories/FriendsRepositoryContract.swift SplitApp/Data/Repositories/FriendsDataRepository.swift SplitAppTests/FriendsDataRepositoryTests.swift && git commit -m "feat(friends): fetch real friendship records"`

### Task 2: Separate friendship state from event debts

**Files:**
- Modify: `SplitApp/Features/Friends/ViewModels/FriendsViewModel.swift`
- Create: `SplitAppTests/FriendsViewModelTests.swift`

**Interfaces:**
- Produces `acceptedFriends: [Friend]`, `incomingRequests: [Friendship]`, and `outgoingRequests: [Friendship]` as derived view-model state.
- Consumes `FriendsRepository.listFriendships()` and the existing `BalancesRepository.getEventBalances(eventId:)`.
- Produces async `accept(_:)`, `reject(_:)`, and `remove(_:)` actions that reload server state on success.

- [ ] **Step 1: Write failing view-model tests**

Create a repository spy returning one accepted relationship, one incoming requested relationship, and one outgoing requested relationship. Assert that only the accepted peer appears in `filteredFriends`, only the incoming request appears in `incomingRequests`, and the sent request appears in `outgoingRequests`. Provide an active-event balance against a non-friend and assert that it still appears in `activeDebts`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:SplitAppTests/FriendsViewModelTests`

Expected: compilation failure because friendship-derived state and actions do not exist.

- [ ] **Step 3: Implement the minimal view-model change**

Replace the `listRemoteFriends()` source with `listFriendships()`. Filter friendship records relative to `currentUser.id`: accepted records with a peer map to `Friend`; requested records where `addresseeId == currentUser.id` are incoming; requested records where `requesterId == currentUser.id` are outgoing. When an event is active, load friendships, the event's balances, and `/api/users` concurrently; use users only to resolve debt counterparties, never to populate the Friends section. Without an active event, load friendships only. Keep `settleDebt(_:)` unchanged. On successful request action call `reload()`; surface the current friendly failure copy on error.

- [ ] **Step 4: Run focused tests to verify they pass**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:SplitAppTests/FriendsViewModelTests`

Expected: PASS.

- [ ] **Step 5: Commit the focused change**

Run: `git add SplitApp/Features/Friends/ViewModels/FriendsViewModel.swift SplitAppTests/FriendsViewModelTests.swift && git commit -m "feat(friends): separate requests from event debts"`

### Task 3: Render real friendships and requests

**Files:**
- Create: `SplitApp/Features/Friends/Views/Components/FriendRequestsSection.swift`
- Modify: `SplitApp/Features/Friends/Views/FriendsView.swift`
- Modify: `SplitApp/Features/Friends/Views/Components/AllFriendsSection.swift`

**Interfaces:**
- Consumes `FriendsViewModel.incomingRequests`, `outgoingRequests`, `filteredFriends`, `activeDebts`, `accept(_:)`, and `reject(_:)`.
- Produces a request section with accessible accept/reject buttons and sent-request status text.

- [ ] **Step 1: Write the failing UI contract test**

Add a lightweight source-contract assertion in `FriendsViewModelTests` that asserts the view model exposes incoming and outgoing requests and that accepted friends are the data source of the all-friends section. This protects the business boundary without snapshot-test infrastructure.

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:SplitAppTests/FriendsViewModelTests`

Expected: FAIL until the request state is rendered by the screen.

- [ ] **Step 3: Implement focused SwiftUI composition**

Add `FriendRequestsSection` with a card per request. Incoming cards show the peer name plus "Принять" and "Отклонить" buttons with accessibility labels; outgoing cards show "Заявка отправлена" without mutation controls. Insert this section after the search bar and before debts. Update the all-friends empty state to say that confirmed friends will appear here and retain the debt section independently.

- [ ] **Step 4: Run focused test and build**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:SplitAppTests/FriendsViewModelTests && xcodebuild build -project SplitApp.xcodeproj -scheme SplitApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`

Expected: tests PASS and build succeeds with no compiler errors.

- [ ] **Step 5: Commit the focused change**

Run: `git add SplitApp/Features/Friends/Views/Components/FriendRequestsSection.swift SplitApp/Features/Friends/Views/FriendsView.swift SplitApp/Features/Friends/Views/Components/AllFriendsSection.swift SplitAppTests/FriendsViewModelTests.swift && git commit -m "feat(friends): show real friends and requests"`

### Task 4: Verify, document, and publish

**Files:**
- Modify: `FRONTEND_BACKEND_TODO.md`

- [ ] **Step 1: Update the follow-up record**

Replace the completed portion of the friends/search/invites item with a note that iOS now consumes real friendship records and requests; keep contact import and AirDrop invite-token flow as later work.

- [ ] **Step 2: Run full relevant verification**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' && git diff --check && git status --short`

Expected: unit tests pass, no whitespace errors, and only intentional friendship/doc changes are staged for this work.

- [ ] **Step 3: Commit and push main**

Run: `git add FRONTEND_BACKEND_TODO.md && git commit -m "docs(friends): record real friendship client support" && git push origin main`

Expected: all friendship implementation commits and this documentation commit are published to `origin/main`.
