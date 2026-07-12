# Yandex Profile Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Import Yandex profile data and avatar once into backend-owned storage, then restore the saved profile instantly from an iOS-local cache on later launches.

**Architecture:** The backend validates each explicit OAuth credential but imports fields and avatar only before `yandex_profile_imported_at` exists. It stores `avatar_key` in S3-compatible object storage and serves `/avatars/{user_id}` by redirecting to a short-lived URL. iOS restores its cached profile before it refreshes the stored session and fetches `/api/users/me` only if that cache is missing.

**Tech Stack:** FastAPI, PyMongo/mongomock, httpx, boto3-compatible Yandex Object Storage, Swift, SwiftUI, XCTest, KeychainSwift, UserDefaults.

## Global Constraints

- Validate the Yandex credential on every explicit OAuth login; do not re-import profile data or avatar on repeat login.
- Store an imported avatar as `avatar_key`, never as a Yandex URL; a failed avatar download must not block login.
- Restore a profile cache only when a refresh token exists; clear profile and tokens on failed refresh and logout.
- Do not log OAuth tokens, refresh tokens, or serialized profile data.
- Preserve existing manual profile fields and unrelated dirty files.

---

## Task 1: Backend-owned avatar storage and retrieval

**Files:**
- Create: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/app/services/user_avatar.py`
- Create: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/app/routers/avatars.py`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/app/routers/__init__.py`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/app/main.py`
- Test: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/tests/test_user_avatar.py`

**Interfaces:** `import_yandex_avatar(s3: Any, *, user_id: str, yandex_avatar_url: str | None) -> str | None`; `get_avatar_redirect(db: Database, s3: Any, user_id: str) -> RedirectResponse`; `GET /avatars/{user_id}`.

- [ ] **Step 1: Write the failing tests**

```python
def test_import_yandex_avatar_stores_valid_image(fake_s3, monkeypatch):
    monkeypatch.setenv("S3_BUCKET", "split-bucket")
    monkeypatch.setattr(user_avatar.httpx, "get", lambda *_a, **_kw: FakeImageResponse())
    key = user_avatar.import_yandex_avatar(fake_s3, user_id="user-1", yandex_avatar_url="https://avatars.yandex.net/a.jpg")
    assert key == "users/user-1/avatar.jpg"
    assert fake_s3.objects[("split-bucket", key)]["ContentType"] == "image/jpeg"

def test_avatar_route_redirects_to_presigned_object(db, fake_s3, monkeypatch):
    monkeypatch.setenv("S3_BUCKET", "split-bucket")
    db.users.insert_one({"id": "user-1", "avatar_key": "users/user-1/avatar.jpg"})
    response = user_avatar.get_avatar_redirect(db, fake_s3, "user-1")
    assert response.status_code == 307
    assert response.headers["location"].startswith("https://signed.example/split-bucket/users/user-1/avatar.jpg")
```

- [ ] **Step 2: Verify RED**

Run: `make test ARGS='tests/test_user_avatar.py -q'` in `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend`.

Expected: FAIL because `app.services.user_avatar` does not exist.

- [ ] **Step 3: Implement the minimal bounded import and redirect**

```python
_MAX_AVATAR_BYTES = 2 * 1024 * 1024
def import_yandex_avatar(s3: Any, *, user_id: str, yandex_avatar_url: str | None) -> str | None:
    bucket = _bucket_name()
    if not bucket or not yandex_avatar_url: return None
    try:
        response = httpx.get(yandex_avatar_url, timeout=10.0, follow_redirects=True)
        content_type = response.headers.get("content-type", "").split(";", 1)[0].lower()
        if response.status_code != 200 or not content_type.startswith("image/") or len(response.content) > _MAX_AVATAR_BYTES: return None
        key = f"users/{user_id}/avatar.jpg"
        s3.put_object(Bucket=bucket, Key=key, Body=response.content, ContentType=content_type)
        return key
    except httpx.HTTPError: return None
```

Implement `get_avatar_redirect` with `404` for missing `avatar_key` and a 307 `RedirectResponse` to a 900-second `get_object` presigned URL. Register the router with the existing FastAPI router registrations.

- [ ] **Step 4: Verify GREEN and commit**

Run: `make test ARGS='tests/test_user_avatar.py -q'`

Expected: PASS.

Run: `git add app/services/user_avatar.py app/routers/avatars.py app/routers/__init__.py app/main.py tests/test_user_avatar.py && git commit -m "feat(avatars): serve imported Yandex avatars from backend storage"`

## Task 2: One-time backend Yandex import

**Files:**
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/app/services/auth.py`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/app/services/common.py`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/app/routers/auth.py`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/tests/test_services.py`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/openapi.yaml`

**Interfaces:** `login_with_yandex_oauth(db: Database, oauth_token: str, *, s3: Any) -> dict`; document fields `avatar_key`, `yandex_profile_imported_at`; `avatar_url == "/avatars/{user_id}"`.

- [ ] **Step 1: Write failing first-import/repeat-login tests**

```python
def test_yandex_login_imports_once_and_reuses_stored_profile(db, fake_s3, monkeypatch):
    profile = {"id": "yandex-1", "first_name": "Alice", "default_avatar_id": "avatar-1"}
    monkeypatch.setattr(auth, "_fetch_yandex_profile", lambda _: profile)
    monkeypatch.setattr(auth, "import_yandex_avatar", lambda *_a, **_kw: "users/user-1/avatar.jpg")
    monkeypatch.setattr(auth, "new_uuid", lambda: "user-1")
    first = auth.login_with_yandex_oauth(db, "token", s3=fake_s3)
    profile["first_name"] = "Changed in Yandex"
    second = auth.login_with_yandex_oauth(db, "token", s3=fake_s3)
    assert first["user"]["avatar_url"] == "/avatars/user-1"
    assert second["user"]["name"] == "Alice"
    assert db.users.find_one({"yandex_id": "yandex-1"})["yandex_profile_imported_at"] is not None
```

Add a second test where `import_yandex_avatar` returns `None`, asserting successful login and `avatar_url is None`.

- [ ] **Step 2: Verify RED**

Run: `make test ARGS='tests/test_services.py -k yandex_login -q'`

Expected: FAIL because login lacks an S3 parameter and overwrites repeat-login fields.

- [ ] **Step 3: Implement idempotent behavior**

Pass `s3: Any = Depends(get_s3)` from `app/routers/auth.py`. Keep `_fetch_yandex_profile` to validate and identify every explicit OAuth login. Add `build_imported_user(fields, *, user_id, now, s3)` to call `import_yandex_avatar` and populate fields, `yandex_profile_imported_at`, and conditional `avatar_key`. New documents use it before `insert_one`; existing documents with the timestamp are returned unchanged; existing documents without it perform one migration import. In `user_to_api_dict`, use `f"/avatars/{user['id']}" if user.get("avatar_key") else user.get("avatar_url")`.

- [ ] **Step 4: Verify GREEN and all backend gates**

Run: `make test ARGS='tests/test_services.py -k yandex_login -q' && .venv/bin/python -c 'import json; from app.main import create_app; print(json.dumps(create_app().openapi(), ensure_ascii=False, indent=2))' > openapi.yaml && make format-check && make lint && make test && git diff --check`

Expected: PASS; repeat login returns stored fields and backend avatar path.

- [ ] **Step 5: Commit**

Run: `git add app/services/auth.py app/services/common.py app/routers/auth.py tests/test_services.py openapi.yaml && git commit -m "feat(auth): persist Yandex profile data on first login"`

## Task 3: Testable local profile cache in iOS

**Files:**
- Create: `/Users/strongf/Developer/SplitApp Yandex/SplitApp/SplitApp/Features/UserProfile/Model/CurrentUserCache.swift`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitApp/SplitApp/Features/UserProfile/Model/CurrentUser.swift`
- Create: `/Users/strongf/Developer/SplitApp Yandex/SplitApp/SplitAppTests/CurrentUserCacheTests.swift`

**Interfaces:** `CurrentUserCaching`; `UserDefaultsCurrentUserCache`; `CurrentUserStore(cache:)`; `restoreCachedUser() -> CurrentUser?`; `clearInMemoryUser()`.

- [ ] **Step 1: Write failing cache tests**

```swift
@MainActor func testCacheRestoresSavedProfile() {
    let cache = InMemoryCurrentUserCache(); let store = CurrentUserStore(cache: cache)
    store.updateFromAuth(User(id: UUID(), name: "Алиса", phoneNumber: "yandex:1", avatarUrl: "/avatars/1"))
    store.clearInMemoryUser()
    XCTAssertEqual(store.restoreCachedUser()?.name, "Алиса")
    XCTAssertEqual(store.restoreCachedUser()?.avatarURL?.path, "/avatars/1")
}
@MainActor func testClearRemovesSavedProfile() {
    let cache = InMemoryCurrentUserCache(); let store = CurrentUserStore(cache: cache)
    store.updateFromAuth(User(id: UUID(), name: "Алиса", phoneNumber: "yandex:1")); store.clear()
    XCTAssertNil(store.restoreCachedUser())
}
```

- [ ] **Step 2: Verify RED**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:SplitAppTests/CurrentUserCacheTests`

Expected: FAIL due to missing cache abstractions.

- [ ] **Step 3: Implement cache ownership**

```swift
protocol CurrentUserCaching: AnyObject { func load() -> CurrentUserData?; func save(_ value: CurrentUserData); func clear() }
final class UserDefaultsCurrentUserCache: CurrentUserCaching {
    private let defaults: UserDefaults; private let key = "currentUser"
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    func load() -> CurrentUserData? { guard let data = defaults.data(forKey: key) else { return nil }; return try? JSONDecoder().decode(CurrentUserData.self, from: data) }
    func save(_ value: CurrentUserData) { guard let data = try? JSONEncoder().encode(value) else { return }; defaults.set(data, forKey: key) }
    func clear() { defaults.removeObject(forKey: key) }
}
```

Make `CurrentUserData` internal. Inject `cache` via `CurrentUserStore.init(cache: CurrentUserCaching = UserDefaultsCurrentUserCache())`; replace direct `UserDefaults` use in update, restore, and clear; make `clearInMemoryUser()` remove only published state. Remove `print` calls from `CurrentUserStore`.

- [ ] **Step 4: Verify GREEN and commit**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:SplitAppTests/CurrentUserCacheTests`

Expected: PASS.

Run: `git add SplitApp/Features/UserProfile/Model/CurrentUserCache.swift SplitApp/Features/UserProfile/Model/CurrentUser.swift SplitAppTests/CurrentUserCacheTests.swift && git commit -m "feat(profile): persist the authenticated user cache"`

## Task 4: Cache-first iOS session bootstrap and logout

**Files:**
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitApp/SplitApp/Features/Authorization/Services/BootstrapAuthUseCase.swift`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitApp/SplitApp/App/SplitAppApp.swift`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitApp/SplitApp/Features/Authorization/Services/LogoutUseCase.swift`
- Create: `/Users/strongf/Developer/SplitApp Yandex/SplitApp/SplitAppTests/BootstrapAuthUseCaseTests.swift`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitApp/SplitAppTests/LogoutUseCaseTests.swift`

**Interfaces:** `BootstrapAuthResult.authenticated | .unauthenticated`; injected `refresh: () async throws -> Void`; injected `currentUserStore` in `LogoutUseCase`.

- [ ] **Step 1: Write failing session tests**

```swift
func testBootstrapKeepsTokenWhenRefreshSucceeds() async {
    let storage = InMemorySecureStorage(values: ["refresh_token": "refresh"])
    XCTAssertEqual(await BootstrapAuthUseCase(storage: storage, refresh: { }).execute(), .authenticated)
}
func testBootstrapRemovesTokenWhenRefreshFails() async {
    let storage = InMemorySecureStorage(values: ["refresh_token": "refresh"])
    XCTAssertEqual(await BootstrapAuthUseCase(storage: storage, refresh: { throw TestError.failed }).execute(), .unauthenticated)
    XCTAssertNil(storage.get("refresh_token"))
}
```

Extend the logout test to inject `CurrentUserStore(cache: InMemoryCurrentUserCache())` and assert the cache is empty after logout.

- [ ] **Step 2: Verify RED**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -only-testing:SplitAppTests/BootstrapAuthUseCaseTests -only-testing:SplitAppTests/LogoutUseCaseTests`

Expected: FAIL due to missing result type and injected refresh closure.

- [ ] **Step 3: Implement cache-first bootstrap**

```swift
enum BootstrapAuthResult: Equatable { case authenticated; case unauthenticated }
```

Give `BootstrapAuthUseCase` a defaulted injected `refresh` closure, clear the refresh token and `TokenStore` on error, and return the result. In `SplitAppApp.bootstrap`, restore `CurrentUserStore.shared` immediately after finding a refresh token; then refresh. On authenticated result, request `CurrentUserEndpoint` only if no profile was restored and store that response. On unauthenticated result, call `CurrentUserStore.shared.clear()` and show login. Add `currentUserStore: CurrentUserStore = .shared` to `LogoutUseCase` and clear it.

- [ ] **Step 4: Verify GREEN, full tests, build, and commit**

Run: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' && xcodebuild build -project SplitApp.xcodeproj -scheme SplitApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' && git diff --check`

Expected: PASS with no XCTest, build, or whitespace errors.

Run: `git add SplitApp/Features/Authorization/Services/BootstrapAuthUseCase.swift SplitApp/App/SplitAppApp.swift SplitApp/Features/Authorization/Services/LogoutUseCase.swift SplitAppTests/BootstrapAuthUseCaseTests.swift SplitAppTests/LogoutUseCaseTests.swift && git commit -m "feat(auth): restore cached user before session refresh"`

## Task 5: Backend documentation and final checks

**Files:**
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/docs/wiki/Authentication-And-Security.md`
- Modify: `/Users/strongf/Developer/SplitApp Yandex/SplitAppBackend/docs/wiki/Data-Model.md`

- [ ] **Step 1: Document lifecycle**

Document: every explicit OAuth login validates credentials; `yandex_profile_imported_at` gates a one-time profile/avatar import; the avatar object lives at `users/{user_id}/avatar.jpg` and is served at `GET /avatars/{user_id}`; iOS cache is restored only alongside refresh token and cleared on invalid refresh or logout.

- [ ] **Step 2: Run final independent gates**

Run in backend: `make format-check && make lint && make test && git diff --check`

Expected: PASS.

Run in iOS: `xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' && git diff --check`

Expected: PASS.

- [ ] **Step 3: Commit docs**

Run: `git add docs/wiki/Authentication-And-Security.md docs/wiki/Data-Model.md && git commit -m "docs(auth): describe persisted Yandex profiles"`

## Plan self-review

- Tasks 1-2 cover storage, backend route, legacy-user one-time migration, and repeat-login behavior.
- Tasks 3-4 cover cache persistence, missing-cache recovery, refresh failure, interactive-login cache replacement through existing `LoginUseCase`, and logout.
- Tasks 5 documents the contract and repeats backend/iOS gates. The method and route names used by consumers are defined in their preceding tasks.
