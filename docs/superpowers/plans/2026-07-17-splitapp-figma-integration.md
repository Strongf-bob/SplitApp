# SplitApp Figma Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the 15-screen PDF design as adaptive, functional SwiftUI backed by registered-user friend search and a real targeted event-invitation inbox.

**Architecture:** Keep the existing feature/view-model/repository structure and rebuild presentation in place. Extend the backend token invitation model with an optional addressee and actor-scoped inbox, then expose it through focused iOS repositories. The generated fixed-coordinate package remains a visual fixture only.

**Tech Stack:** Swift 5.9, SwiftUI, Combine, XCTest, FastAPI, Pydantic, MongoDB, pytest, OpenAPI.

## Global Constraints

- Preserve authentication, event, receipt, payment, friendship, profile, and Splitik behavior.
- Search registered users only; do not send SMS or create placeholder contacts.
- Preserve Montserrat and Roboto from the supplied package.
- Use adaptive SwiftUI, Dynamic Type, VoiceOver labels, and 44pt touch targets.
- Keep backend behavior, tests, `openapi.yaml`, and docs synchronized.
- Preserve unrelated dirty files and stage only deliberate hunks.
- Use Conventional Commits in English.

---

### Task 1: Targeted invitation inbox backend

**Files:**
- Modify: `../SplitAppBackend/app/schemas.py`
- Modify: `../SplitAppBackend/app/services/events.py`
- Modify: `../SplitAppBackend/app/services/indexes.py`
- Modify: `../SplitAppBackend/app/services/__init__.py`
- Modify: `../SplitAppBackend/app/routers/events.py`
- Modify: `../SplitAppBackend/tests/test_services.py`
- Modify: `../SplitAppBackend/tests/test_app_config.py`
- Modify: `../SplitAppBackend/openapi.yaml`
- Modify: `../SplitAppBackend/docs/wiki/iOS-Frontend-Integration.md`

**Interfaces:**
- Produces `CreateEventInviteRequest(expires_in_seconds, addressee_id)`.
- Produces `GET /api/invites?limit=50&offset=0` returning `EventInvitationInboxPage`.
- Preserves existing link invites where `addressee_id` is absent.

- [ ] **Step 1: Write failing actor-scope and lifecycle tests**

```python
def test_targeted_invitation_inbox_is_actor_scoped(db):
    invite = events.create_event_invite(
        db, EVENT_ID,
        schemas.CreateEventInviteRequest(addressee_id=UUID(USER_C)), USER_A,
    )
    page = events.list_event_invitation_inbox(db, USER_C, limit=50, offset=0)
    assert [row["id"] for row in page["items"]] == [invite["id"]]
    assert events.list_event_invitation_inbox(db, USER_B, limit=50, offset=0)["items"] == []
```

Also test pagination, exclusion after accept/decline/expiry, and 403 when another actor accepts a targeted invite.

- [ ] **Step 2: Run `cd ../SplitAppBackend && pytest tests/test_services.py -k 'targeted_invitation' -q`**

Expected: FAIL because the new schema field and list service do not exist.

- [ ] **Step 3: Implement schemas and service rules**

```python
class EventInvitationInboxItem(BaseModel):
    id: UUID
    token: str
    event_id: UUID
    event_name: str
    created_by: UUID
    creator_name: str
    expires_at: datetime
    created_at: datetime

class EventInvitationInboxPage(BaseModel):
    items: list[EventInvitationInboxItem]
    limit: int
    offset: int
    total: int
```

Store `addressee_id`, index `(addressee_id, status, expires_at)`, filter by actor and missing decision, and authorize targeted accept/decline against the addressee.

- [ ] **Step 4: Add the router and OpenAPI test**

```python
@router.get("/api/invites", response_model=schemas.EventInvitationInboxPage)
def list_event_invitation_inbox(limit: int = Query(50, ge=1, le=100), offset: int = Query(0, ge=0), db: Database = Depends(get_db), current_user_id: str = Depends(get_actor_user_id)) -> dict:
    return services.list_event_invitation_inbox(db, current_user_id, limit=limit, offset=offset)
```

- [ ] **Step 5: Regenerate OpenAPI, update docs, and run `make test`**

Expected: all backend tests PASS and `/api/invites` appears in `openapi.yaml`.

- [ ] **Step 6: Commit with `feat(invites): add targeted invitation inbox`**

### Task 2: Registered-user phone search and friend request

**Files:**
- Modify: `SplitApp/Data/Network/Endpoints/UserEndpoints.swift`
- Modify: `SplitApp/Data/Network/Endpoints/FriendshipEndpoints.swift`
- Modify: `SplitApp/Domain/Repositories/UsersRepositoryContract.swift`
- Modify: `SplitApp/Domain/Repositories/FriendsRepositoryContract.swift`
- Modify: `SplitApp/Data/Repositories/UsersRepository.swift`
- Modify: `SplitApp/Data/Repositories/FriendsDataRepository.swift`
- Modify: `SplitApp/Features/Friends/ViewModels/FriendsViewModel.swift`
- Create: `SplitApp/Features/Friends/Views/AddFriendView.swift`
- Modify: `SplitApp/Features/Friends/Views/FriendsView.swift`
- Create: `SplitAppTests/FriendSearchTests.swift`

**Interfaces:**
- Produces `UsersRepository.searchUsers(query:)` and `FriendsRepository.createFriendRequest(userId:)`.
- Produces add-friend loading, not-found, duplicate, failure, and success states.

- [ ] **Step 1: Write failing endpoint tests**

```swift
func testSearchUsersEndpointUsesNormalizedPhone() {
    let endpoint = SearchUsersEndpoint(query: "+7 905 469-77-10")
    XCTAssertEqual(endpoint.path, "/api/users/search")
    XCTAssertEqual(endpoint.queryItems, [URLQueryItem(name: "q", value: "+79054697710")])
}
```

- [ ] **Step 2: Run only `FriendSearchTests` and verify compile failure**
- [ ] **Step 3: Implement endpoint and request DTO**

```swift
struct CreateFriendRequest: Encodable {
    let userId: UUID
    enum CodingKeys: String, CodingKey { case userId = "user_id" }
}
```

- [ ] **Step 4: Implement page 3 using real registered-user results**

Use labeled phone input, normalized query, selected result, disabled submit, per-action progress, and Russian errors. Never create an external contact.

- [ ] **Step 5: Run `FriendSearchTests`, `FriendsViewModelTests`, and `FriendsDataRepositoryTests`**

Expected: PASS.

- [ ] **Step 6: Commit with `feat(friends): add registered-user phone search`**

### Task 3: Invitation inbox iOS client

**Files:**
- Create: `SplitApp/Domain/Models/EventInvitation.swift`
- Create: `SplitApp/Domain/Repositories/InvitationsRepositoryContract.swift`
- Create: `SplitApp/Data/DTOs/EventInvitationDTO.swift`
- Create: `SplitApp/Data/Network/Endpoints/InvitationEndpoints.swift`
- Create: `SplitApp/Data/Repositories/InvitationsDataRepository.swift`
- Create: `SplitApp/Features/Events/ViewModels/InboxViewModel.swift`
- Replace: `SplitApp/Features/Events/Views/InboxView.swift`
- Modify: `SplitApp/App/AppDependencies.swift`
- Modify: `SplitApp/Features/Navigation/Views/EventsNavigationView.swift`
- Create: `SplitAppTests/InvitationInboxTests.swift`

**Interfaces:**
- Produces `InvitationsRepository.listPending()`, `accept(token:)`, and `decline(token:)`.
- Produces an inbox view model with per-row mutation state.

- [ ] **Step 1: Write failing DTO and mutation-state tests**

```swift
func testInvitationDTOMapsEventAndCreator() throws {
    let dto = try JSONDecoder.api.decode(EventInvitationDTO.self, from: fixture)
    XCTAssertEqual(dto.eventName, "Поездка на Карпаты")
    XCTAssertEqual(dto.creatorName, "Алексей")
}
```

Test that success removes one row and failure retains it with an inline error.

- [ ] **Step 2: Run only `InvitationInboxTests` and verify failure**
- [ ] **Step 3: Implement DTOs, endpoints, repository, and dependency injection**

```swift
struct ListInvitationsEndpoint: Endpoint {
    let path = "/api/invites"
    let method: HTTPMethod = .GET
}
```

- [ ] **Step 4: Rebuild page 4 with real cards, accept/decline, empty, offline, retry, and refresh states**
- [ ] **Step 5: Run inbox and navigation tests**
- [ ] **Step 6: Commit with `feat(inbox): connect event invitation actions`**

### Task 4: Fonts and PDF design tokens

**Files:**
- Copy: package font `.ttf` files -> `SplitApp/Resources/Fonts/`
- Modify: `SplitApp/Info.plist`
- Replace: `SplitApp/Shared/Theme/AppTheme.swift`
- Create: `SplitApp/Shared/Theme/AppTypography.swift`
- Create: `SplitApp/Shared/Theme/DesignTokens.swift`
- Create: `SplitAppTests/DesignTokenTests.swift`

**Interfaces:** Semantic Montserrat display/title/button tokens and Roboto body/field tokens, plus adaptive PDF palette, spacing, and radius tokens.

- [ ] **Step 1: Write failing `UIFont(name:)` registration tests**
- [ ] **Step 2: Copy/register fonts and implement semantic tokens**
- [ ] **Step 3: Run `DesignTokenTests` and build the app**
- [ ] **Step 4: Commit with `feat(ui): add PDF design system`**

### Task 5: Root shell and shared components

**Files:**
- Modify: `SplitApp/Features/Authorization/Views/LoginView.swift`
- Modify: `SplitApp/App/SplitLaunchView.swift`
- Modify: `SplitApp/Features/Navigation/Views/BottomTabBarView.swift`
- Modify: `SplitApp/Shared/Components/PrimaryButton.swift`
- Modify: `SplitApp/Shared/Components/ParticipantAvatar.swift`
- Create: `SplitApp/Shared/Components/DesignHeader.swift`
- Create: `SplitApp/Shared/Components/DesignField.swift`
- Modify: `SplitAppTests/BottomTabPresentationTests.swift`

**Interfaces:** Preserves the OAuth action and four existing tab IDs while matching pages 5-8 and 12.

- [ ] **Step 1: Extend tab presentation tests for PDF labels/symbols**
- [ ] **Step 2: Rebuild authorization, launch, tab shell, header, field, button, and avatar components**
- [ ] **Step 3: Run auth, launch, and tab tests**
- [ ] **Step 4: Commit with `feat(ui): rebuild app shell from PDF design`**

### Task 6: Home, events, profile, and Splitik

**Files:**
- Modify: `SplitApp/Features/Events/Views/EventsHomeView.swift`
- Modify: `SplitApp/Features/Events/Views/EventsCatalogView.swift`
- Modify: `SplitApp/Features/Events/Views/Components/CurrentEventCardView.swift`
- Modify: `SplitApp/Features/EventPicker/Views/EventPickerView.swift`
- Modify: `SplitApp/Data/DTOs/UserDTO.swift`
- Modify: `SplitApp/Features/UserProfile/Model/CurrentUser.swift`
- Modify: `SplitApp/Features/UserProfile/Views/ProfileScreenView.swift`
- Modify: `SplitApp/Features/Navigation/Views/SplitikChatView.swift`
- Modify: `SplitAppTests/CurrentUserEndpointTests.swift`
- Modify: `SplitAppTests/EventsHomeViewModelTests.swift`

**Interfaces:** Decodes optional `payment_phone`; all PDF sample amounts/names stay preview-only and production uses live state.

- [ ] **Step 1: Add failing payment-phone decoding coverage**
- [ ] **Step 2: Rebuild pages 6-8, 12, and 14 against live models**
- [ ] **Step 3: Render live activity instead of static PDF samples**
- [ ] **Step 4: Run profile, home, and Splitik tests**
- [ ] **Step 5: Commit with `feat(ui): rebuild primary app screens`**

### Task 7: Event, payment, receipt, and reconstructed friend picker flows

**Files:**
- Modify: `SplitApp/Features/BillEntry/Views/BillEntryView.swift`
- Modify: `SplitApp/Features/BillEntry/Views/BillItemRow.swift`
- Replace: `SplitApp/Features/BillEntry/Views/ParticipantPickerSheet.swift`
- Modify: `SplitApp/Features/BillEntry/ViewModels/BillViewModel.swift`
- Modify: `SplitApp/Features/EventPicker/Views/EventPickerView.swift`
- Create: `SplitApp/Features/ReceiptScanner/Views/ReceiptConfirmationView.swift`
- Modify: `SplitApp/Features/Navigation/ViewModels/EventsNavigationViewModel.swift`
- Modify: `SplitApp/Features/Navigation/Views/EventsNavigationView.swift`
- Create: `SplitAppTests/EventCompositionTests.swift`
- Modify: `SplitAppTests/ReceiptPersistenceTests.swift`

**Interfaces:** Reconstructs broken page 2 as a searchable multi-select; preserves receipt idempotency; retries unfinished invitation/payment work without recreating the event.

- [ ] **Step 1: Write failing partial-success orchestration tests**

Assert one event creation across retries, preserved selected friends after targeted-invite failure, and preserved event after optional-payment failure.

- [ ] **Step 2: Run `EventCompositionTests` and `ReceiptPersistenceTests` and verify failure**
- [ ] **Step 3: Implement orchestration and pages 2, 9-11, 13, and 15 with real controls**
- [ ] **Step 4: Run bill, receipt, event, and navigation tests**
- [ ] **Step 5: Commit with `feat(ui): rebuild event and payment flows`**

### Task 8: Full verification and visual QA

**Files:** Modify only files required by failures discovered here.

**Interfaces:** Produces two green repositories and functional mappings for all 15 PDF pages.

- [ ] **Step 1: Run `cd ../SplitAppBackend && make test`**
- [ ] **Step 2: Run all iOS unit tests on the available iPhone 17 Pro simulator**
- [ ] **Step 3: Build and walk OAuth, four tabs, friend search, inbox, event creation, scanner/manual payment, friend picker, profile, and Splitik**
- [ ] **Step 4: Compare simulator captures to all 15 PDF pages and check small/large phones, keyboard, largest Dynamic Type, VoiceOver, reduced motion, dark/light appearance, and safe areas**
- [ ] **Step 5: Run `git diff --check` in both repositories and inspect staged scope before any final commit**

Expected: no whitespace errors, all tests PASS, and unrelated pre-existing changes remain unstaged.
