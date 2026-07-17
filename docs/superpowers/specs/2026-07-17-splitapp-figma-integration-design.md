# SplitApp Figma Integration Design

## Goal

Replace the current native SwiftUI presentation with the 15-screen design from `SplitAppDesign.pdf` while preserving the application's existing authentication, event, receipt, payment, friendship, profile, and Splitik behavior.

The generated `SplitAppUI` package is a visual reference only. Its fixed 402x874 coordinate layers are not integrated directly because they contain no controls, state, navigation, accessibility, or live data. Existing feature views remain the product architecture and are restyled with adaptive SwiftUI components.

## Visual System

- Preserve the design's Montserrat and Roboto fonts, packaged as application resources and exposed through semantic typography tokens.
- Use the PDF's blue palette, rounded cards, field shapes, hierarchy, and spacing as the visual source of truth.
- Use semantic colors and adaptive layout where the design does not specify dark mode or non-phone form factors.
- Keep system navigation, sheets, lists, fields, buttons, safe areas, Dynamic Type, VoiceOver labels, and 44pt minimum touch targets.
- Treat duplicate frames as states of the same flow rather than separate destinations.

## Screen Mapping

- Authorization -> existing Yandex OAuth flow.
- Home -> existing balance summary, current event, receipts/activity, and navigation.
- Events -> existing event catalog and event selection.
- Create event -> name, friend selection, optional payment creation, and Splitik-assisted creation.
- Add payment -> existing manual/scanner receipt flow and participant assignment.
- Receipt preview -> confirmation step before the editable bill flow when scanner data is available.
- Friends -> accepted friendships, requests, debts, and registered-user search.
- Add friend -> search registered users by phone and create a friendship request. No SMS or external-contact invitation is created.
- Friend picker -> reconstruct the broken PDF page as a searchable multi-select sheet using existing friends, checkmarks, cancel, and confirm actions.
- Inbox -> real server-backed event invitation inbox with accept and decline actions.
- Splitik -> existing live chat and plan confirmation behavior, restyled to the PDF.
- Profile -> current user data plus payment phone fields already supported by the backend contract.

## New Functional Work

### Registered-user friend search

The backend already supports `GET /api/users/search` and `POST /api/friends`. The iOS app needs endpoints, repository methods, view-model state, validation, loading/error states, duplicate-request handling, and the add-friend screen.

Phone input is normalized for search. A missing user produces a clear not-found state; it never creates a placeholder friend or sends an external invitation.

### Server-backed invitation inbox

The current backend supports token preview/accept/decline but has no authenticated paginated inbox. Add an authenticated endpoint that lists pending event invitations addressed to the current user. Each item contains stable invitation identity, event summary, inviter summary, timestamps, current state, and the information required for accept/decline.

The endpoint must be actor-scoped and paginated. Accept and decline remain server-authorized operations. The OpenAPI document, backend tests, iOS DTOs/endpoints/repository, and inbox UI change together.

### Event composition

The backend already has event creation, participant addition, receipt creation, and Splitik plan APIs. The iOS flow orchestrates those existing primitives: create the event first, add selected registered friends, then create an optional payment. Partial failure is surfaced with a retryable state without duplicating the already-created event.

### Profile and activity

The iOS model is extended to decode payment-phone data already present in the backend user schema. Existing backend event activity support is used for live home activity where applicable; no static sample activity ships in production.

## Navigation and State

The existing root authentication gate and `TabView` remain. Each tab owns its `NavigationStack`. Create/edit surfaces use sheets or full-screen covers according to the PDF, but system dismissal and back gestures remain intact.

Feature view models continue to own async state. Views render explicit loading, empty, offline, partial-success, and retry states. Sample values from the PDF are preview fixtures only.

## Error Handling

- Disable submit actions while requests are running.
- Map 404 search results, duplicate friendship requests, permission failures, expired invitations, offline state, and validation errors to specific Russian copy.
- Refresh affected lists after successful mutations.
- Preserve created resources after partial multi-step failure and retry only the unfinished operation.

## Testing

- Backend service/router tests for inbox actor scoping, pagination, pending-state filtering, accept/decline transitions, and unauthorized access.
- Backend OpenAPI regression coverage.
- iOS endpoint/DTO/repository tests for user search, friend requests, inbox listing, and invitation mutations.
- View-model tests for loading, empty, error, success, duplicate, and partial-success states.
- Existing unit tests remain green.
- Simulator verification covers all 15 mapped screens, navigation, keyboard behavior, small/large phone layouts, Dynamic Type, light/dark appearance, and core happy paths.

## Delivery Boundaries

Backend and iOS changes are developed on matching `strongf/feat-new-figma-ui` branches. Existing unrelated dirty files are preserved and excluded from commits unless a required integration overlaps them; overlapping edits are reviewed and staged deliberately.
