# Yandex profile persistence design

## Goal

Import a user's Yandex profile and avatar once, when their server account is first created. Keep the durable profile on the SplitApp backend and restore it from an iPhone-local cache on later app launches.

## Scope

The work spans the SplitApp iOS client and its paired SplitAppBackend API.

- First interactive Yandex OAuth login validates the received Yandex credential, obtains the profile, creates the SplitApp user, downloads the avatar, and stores the avatar in backend-owned storage.
- The user document stores the stable Yandex subject identifier, profile fields returned by the API, the backend-owned avatar URL, and the import timestamp.
- On later interactive OAuth logins, the backend validates the credential and resolves the user by Yandex subject identifier. It returns the stored profile without refreshing profile fields or avatar from Yandex.
- The iOS app persists the authenticated profile per account locally. On application launch it restores that cached profile before network work, then refreshes the SplitApp session in the background.
- Logout deletes the local profile cache and tokens from the device. It never deletes the server-side user or avatar.

## Data and API contract

The existing authorization response remains the source of the client profile. It always returns the backend-stored user, including a SplitApp avatar URL rather than an externally hosted Yandex avatar URL.

The backend must make account lookup idempotent: concurrent first logins for the same Yandex subject create at most one user and one durable avatar reference. If avatar download fails, authorization still succeeds with a `null` avatar URL; no retry against Yandex occurs on later logins under this scope.

The server keeps validating a Yandex credential for every explicit OAuth login. "Only once" applies to importing profile data and avatar, not to authentication.

## iOS behavior

`CurrentUserStore` uses an account-scoped cached payload, not a global anonymous value. Bootstrap restores the cached profile immediately when a refresh token exists, then attempts token refresh.

- Refresh succeeds: keep the cached profile visible.
- Refresh fails: remove refresh/access tokens and the cached profile, then require login.
- Interactive login succeeds: replace the cached profile with the backend response.
- Logout: remove the cached profile and all tokens.

Core Data remains the cache for the broader users list. The authenticated user's startup cache remains a small profile payload in local preferences because it is read synchronously and is already established in the app.

## Error handling and privacy

The app must not log Yandex credentials, backend access/refresh tokens, or profile payloads. The backend must not expose an avatar file without the same public-access policy used by the current user-avatar endpoint. Errors importing the avatar are non-blocking and must not block account creation.

## Tests

Backend tests cover first-login creation/import, repeated-login lookup without a second profile/avatar import, and non-blocking avatar-import failure. iOS tests cover cached-profile restoration on a valid refresh session, cache removal on failed bootstrap, replacement on successful login, and removal on logout.

## Out of scope

- Manual profile editing or a "refresh data from Yandex" control.
- Deleting server-side accounts or avatars.
- Migrating contact-import data.
