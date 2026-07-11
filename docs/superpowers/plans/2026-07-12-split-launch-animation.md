# Split Launch Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a brief blue Split launch overlay that reveals its title letter by letter before the application becomes interactive.

**Architecture:** Keep launch presentation local to the app shell. A small reusable `SplitLaunchView` owns only its letter animation, while `SplitAppApp` owns the timed visibility state and removes the overlay after bootstrap has resolved and the minimum display duration has elapsed.

**Tech Stack:** SwiftUI, XCTest, iOS Simulator.

## Global Constraints

- Keep the existing blue visual language from `AppTheme`.
- The overlay remains visible for at least 0.35 seconds and does not delay bootstrap beyond that minimum.
- Respect `accessibilityReduceMotion` by showing the completed title without per-letter motion.
- Commit and push each completed deliverable to `strongf/native-liquid-glass-events`.

---

### Task 1: Model the launch display timing

**Files:**
- Create: `SplitApp/App/SplitLaunchPresentation.swift`
- Create: `SplitAppTests/SplitLaunchPresentationTests.swift`

**Interfaces:**
- Produces: `SplitLaunchPresentation.minimumDuration` and `remainingDuration(since:)` for the app shell.

- [ ] **Step 1: Write the failing test**

```swift
func testRemainingDurationKeepsOverlayVisibleUntilMinimumDuration() {
    let startedAt = Date(timeIntervalSinceReferenceDate: 100)
    let elapsed = Date(timeIntervalSinceReferenceDate: 100.1)

    XCTAssertEqual(
        SplitLaunchPresentation.remainingDuration(since: startedAt, now: elapsed),
        0.25,
        accuracy: 0.001
    )
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -only-testing:SplitAppTests/SplitLaunchPresentationTests`

Expected: FAIL because `SplitLaunchPresentation` is not defined.

- [ ] **Step 3: Write minimal implementation**

```swift
enum SplitLaunchPresentation {
    static let minimumDuration: TimeInterval = 0.35

    static func remainingDuration(since startedAt: Date, now: Date = .now) -> TimeInterval {
        max(0, minimumDuration - now.timeIntervalSince(startedAt))
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -only-testing:SplitAppTests/SplitLaunchPresentationTests`

Expected: PASS.

- [ ] **Step 5: Commit and push timing model**

```bash
git add SplitApp/App/SplitLaunchPresentation.swift SplitAppTests/SplitLaunchPresentationTests.swift
git commit -m "feat(ios): add launch presentation timing"
git push
```

### Task 2: Present and dismiss the blue Split overlay

**Files:**
- Create: `SplitApp/App/SplitLaunchView.swift`
- Modify: `SplitApp/App/SplitAppApp.swift`

**Interfaces:**
- Consumes: `SplitLaunchPresentation.minimumDuration`.
- Produces: an app-wide, non-interactive launch overlay that is removed after bootstrapping.

- [ ] **Step 1: Write the failing view model test**

```swift
func testInitialLaunchStateShowsOverlay() {
    XCTAssertTrue(SplitLaunchPresentation.shouldShowInitially)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -only-testing:SplitAppTests/SplitLaunchPresentationTests`

Expected: FAIL because `shouldShowInitially` is not defined.

- [ ] **Step 3: Implement the overlay**

```swift
ZStack {
    appContent
    if showLaunchOverlay {
        SplitLaunchView()
            .transition(.opacity)
            .zIndex(1)
    }
}
```

`SplitLaunchView` reveals the letters in `Split` with staggered opacity and vertical offset animation. It presents the complete title immediately when Reduce Motion is enabled.

- [ ] **Step 4: Run build and full test suite**

Run: `xcodebuild test`

Expected: all tests pass.

- [ ] **Step 5: Run on iPhone 17 Pro simulator**

Run: `build_run_sim({})`

Expected: blue overlay appears once at launch, title reveals letter by letter, then the login or authenticated screen is usable.

- [ ] **Step 6: Commit and push the launch overlay**

```bash
git add SplitApp/App/SplitLaunchView.swift SplitApp/App/SplitAppApp.swift
git commit -m "feat(ios): animate Split launch overlay"
git push
```
