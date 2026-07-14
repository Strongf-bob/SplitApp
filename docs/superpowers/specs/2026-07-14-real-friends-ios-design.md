# Real Friends in iOS Design

## Goal

Replace the current friend-like view of visible event users with a real friendship UI backed by the existing backend friendship lifecycle.

## Current state

`FriendsViewModel` currently loads `GET /api/users` through `FriendsDataRepository`. This endpoint is visibility-limited and its result is combined with active-event balances to render a screen called "Friends". The backend already provides a separate friendship model and these authenticated endpoints:

- `GET /api/friends` for friendship records;
- `POST /api/friends` to create a request;
- `POST /api/friends/{id}/accept` and `POST /api/friends/{id}/reject`;
- `DELETE /api/friends/{id}` and `POST /api/friends/{id}/block`.

The iOS client does not currently model or call these endpoints.

## Product behavior

The Friends screen has two independent sections:

1. **Friends.** Only accepted friendship records appear here. Pending inbound requests appear in a separate "Requests" section, where the recipient can accept or decline. Pending outbound requests are shown as sent requests, not as friends.
2. **Debts in the active event.** This remains a contextual financial summary calculated from the active event's balances. A debt may be with a real friend or another event participant. It never changes friendship status.

The screen does not use `GET /api/users` as its friend source. It continues using the users endpoint only where a user directory is explicitly needed elsewhere in the app.

## Data and architecture

Add domain models for friendship status and the server friendship record, plus a focused `FriendsRepository` contract that lists and mutates friendship records. Its data implementation owns friendship endpoints and maps their paginated DTOs to domain models.

`FriendsViewModel` loads friendships and, if an event is active, balances concurrently. It derives accepted friends, inbound requests, sent requests, and event debts as distinct presentation data. A successful accept, reject, or remove action reloads the friendship list. Failed requests keep the previous state and show the existing user-friendly error pattern.

The SwiftUI screen composes small sections and uses one sheet route for destructive removal confirmation. It includes accessibility labels for request actions and explicit empty states.

## Boundaries

- This change consumes existing backend friendship endpoints; it does not alter backend API, contacts import, or event membership.
- AirDrop/deep-link invitations are out of this change because the current friendship API creates requests only for an existing target user ID. A secure link-token contract will be specified separately.
- Payment settlement remains event-scoped and keeps its current authorization rules.

## Tests and acceptance criteria

- A repository test verifies friend endpoint request/response mapping and mutation paths.
- View-model tests verify that only accepted friendships populate the Friends section; inbound and outbound requests are separated; and an active-event balance produces debts independently of friendship status.
- Existing debt settlement behavior remains covered and works after the data-source change.
- The app builds and relevant unit tests pass.
