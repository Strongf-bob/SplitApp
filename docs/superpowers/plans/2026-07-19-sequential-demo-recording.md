# Sequential SplitApp Demo Recording Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a deterministic, realistic, sequentially recorded SplitApp demo for organizer Ilya and participants Petya, Vanya, and Katya without network or cross-simulator synchronization.

**Architecture:** Launch arguments select an isolated demo role and scene before authentication. A focused `Features/Demo` module owns canonical data and state transitions, while a demo-only SwiftUI shell reuses SplitApp theme and launch presentation. Production launches remain untouched when demo arguments are absent.

**Tech Stack:** Swift 6, SwiftUI, XCTest, CoreSimulator `simctl`, `xcodebuild`, shell launch helper.

## Global Constraints

- Demo mode is enabled only by `-SplitAppDemoRole` and `-SplitAppDemoScene` launch arguments.
- Demo mode makes no backend, Yandex OAuth, S3, or LLM requests.
- Hide the iOS status bar in demo mode.
- Do not expose a debug menu, role switcher, demo badge, or fixture labels in the recording.
- Splitik processing lasts exactly eight seconds and uses the approved six progress messages.
- Do not show `Все расчёты завершены` after the final payment.
- Production behavior must remain unchanged when demo arguments are absent.
- The first visual verification target is `SplitApp Demo Ilya`; participant simulators follow after organizer verification.

---

### Task 1: Demo configuration and canonical state model

**Files:**
- Create: `SplitApp/Features/Demo/Models/SplitAppDemoConfiguration.swift`
- Create: `SplitApp/Features/Demo/Models/SplitAppDemoModels.swift`
- Create: `SplitApp/Features/Demo/Models/SplitAppDemoStore.swift`
- Test: `SplitAppTests/SplitAppDemoConfigurationTests.swift`
- Test: `SplitAppTests/SplitAppDemoStoreTests.swift`

**Interfaces:**
- Produces: `SplitAppDemoConfiguration(arguments:)`, `SplitAppDemoRole`, `SplitAppDemoScene`, and `@MainActor SplitAppDemoStore`.
- `SplitAppDemoStore` publishes the selected tab, Splitik phase, attachment state, invitation state, payment notifications, and outstanding balance.

- [ ] **Step 1: Write failing configuration and store tests**

```swift
func testParsesOrganizerSplitikScene() {
    let configuration = SplitAppDemoConfiguration(arguments: [
        "SplitApp", "-SplitAppDemoRole", "organizer",
        "-SplitAppDemoScene", "splitik-start"
    ])
    XCTAssertEqual(configuration?.role, .organizer)
    XCTAssertEqual(configuration?.scene, .splitikStart)
}

@MainActor
func testOrganizerConfirmationsReduceOutstandingBalanceOnce() {
    let store = SplitAppDemoStore(role: .organizer, scene: .paymentConfirmations)
    XCTAssertEqual(store.outstandingReceivable, 13_000)
    store.confirmPayment(id: SplitAppDemoFixtures.petyaPaymentID)
    store.confirmPayment(id: SplitAppDemoFixtures.petyaPaymentID)
    XCTAssertEqual(store.outstandingReceivable, 10_000)
}
```

- [ ] **Step 2: Run tests and verify missing demo types fail compilation**

Run:

```bash
xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=SplitApp Demo Ilya,OS=26.5' -only-testing:SplitAppTests/SplitAppDemoConfigurationTests -only-testing:SplitAppTests/SplitAppDemoStoreTests
```

Expected: build failure because the demo types do not exist.

- [ ] **Step 3: Implement typed argument parsing and canonical fixtures**

```swift
enum SplitAppDemoRole: String, CaseIterable { case organizer, petya, vanya, katya }
enum SplitAppDemoScene: String, CaseIterable {
    case splitikStart = "splitik-start"
    case paymentConfirmations = "payment-confirmations"
    case invitation
    case payment
}

struct SplitAppDemoConfiguration: Equatable {
    let role: SplitAppDemoRole
    let scene: SplitAppDemoScene

    init?(arguments: [String]) {
        guard let roleFlag = arguments.firstIndex(of: "-SplitAppDemoRole"),
              arguments.indices.contains(roleFlag + 1),
              let role = SplitAppDemoRole(rawValue: arguments[roleFlag + 1]),
              let sceneFlag = arguments.firstIndex(of: "-SplitAppDemoScene"),
              arguments.indices.contains(sceneFlag + 1),
              let scene = SplitAppDemoScene(rawValue: arguments[sceneFlag + 1])
        else { return nil }
        self.role = role
        self.scene = scene
    }
}
```

Use fixed UUIDs for all demo entities. Represent money as integer rubles because every canonical amount is a whole ruble.

- [ ] **Step 4: Implement idempotent state transitions**

```swift
func acceptInvitation() {
    guard invitationStatus == .pending else { return }
    invitationStatus = .accepted
}

func markPaymentSent() {
    guard participantPaymentStatus == .unpaid else { return }
    participantPaymentStatus = .awaitingReceiver
}

func confirmPayment(id: UUID) {
    guard let index = paymentNotifications.firstIndex(where: { $0.id == id }),
          paymentNotifications[index].status == .pending else { return }
    paymentNotifications[index].status = .confirmed
}
```

- [ ] **Step 5: Run focused tests and commit**

Expected: configuration parsing, canonical allocation totals, invitation idempotency, payment marking, and `13 000 → 10 000 → 4 750 → 0` all pass.

Commit title: `feat(demo): add deterministic recording state`

### Task 2: Demo app entry and navigation shell

**Files:**
- Modify: `SplitApp/App/SplitAppApp.swift`
- Create: `SplitApp/Features/Demo/Views/SplitAppDemoRootView.swift`
- Create: `SplitApp/Features/Demo/Views/SplitAppDemoTabBar.swift`
- Test: `SplitAppTests/SplitAppDemoConfigurationTests.swift`

**Interfaces:**
- Consumes: `SplitAppDemoConfiguration` and `SplitAppDemoStore` from Task 1.
- Produces: a demo root that bypasses authentication and preserves `SplitLaunchView`.

- [ ] **Step 1: Add a failing test proving production mode stays disabled without flags**

```swift
func testDemoConfigurationIsNilWithoutFlags() {
    XCTAssertNil(SplitAppDemoConfiguration(arguments: ["SplitApp"]))
}
```

- [ ] **Step 2: Wire demo configuration before Yandex activation and bootstrap**

Initialize `demoConfiguration` from `ProcessInfo.processInfo.arguments`. Skip Yandex SDK activation and `bootstrap()` when it is non-nil. Render `SplitAppDemoRootView` beneath the existing `SplitLaunchView`.

- [ ] **Step 3: Hide system status only in demo mode**

```swift
.statusBarHidden(demoConfiguration != nil)
```

- [ ] **Step 4: Implement four-tab demo shell**

Use existing colors, fonts, SF Symbols, 44-point targets, and the labels `Главная`, `Друзья`, `Сплитик`, `События`. Default to Home for all scenes except `splitik-start`, which still begins at Home and lets Ilya visibly tap Splitik.

- [ ] **Step 5: Build and commit**

Run a target Debug build. Expected: production and demo roots compile.

Commit title: `feat(demo): add isolated demo app entry`

### Task 3: Organizer home and deterministic Splitik scene

**Files:**
- Create: `SplitApp/Features/Demo/Views/SplitAppDemoHomeView.swift`
- Create: `SplitApp/Features/Demo/Views/SplitAppDemoSplitikView.swift`
- Create: `SplitApp/Features/Demo/Views/SplitAppDemoPlanCard.swift`
- Create: `SplitApp/Features/Demo/Views/SplitAppDemoReceiptPicker.swift`
- Test: `SplitAppTests/SplitAppDemoStoreTests.swift`

**Interfaces:**
- Consumes: organizer canonical data and store actions.
- Produces: the complete Ilya recording from Home through event confirmation.

- [ ] **Step 1: Add failing tests for the scripted Splitik sequence**

```swift
func testSplitikProgressMessagesUseApprovedOrder() {
    XCTAssertEqual(SplitAppDemoFixtures.splitikProgress.map(\.text), [
        "Читаю чек…",
        "Нашёл 3 позиции на сумму 6 000 ₽",
        "Нахожу Петю, Ваню и Катю среди ваших друзей…",
        "Распределяю расходы…",
        "Строю удобный план переводов…",
        "Готовлю событие…"
    ])
    XCTAssertEqual(SplitAppDemoFixtures.splitikProgress.reduce(0) { $0 + $1.duration }, 8, accuracy: 0.001)
}
```

- [ ] **Step 2: Build organizer home from existing visual tokens**

Show Ilya, balance, active event, `День рождения Димы`, populated activity, and visible Splitik navigation without network-backed view models.

- [ ] **Step 3: Add receipt attachment interaction**

The paperclip/photo button opens a polished bottom sheet with one bundled receipt. Selecting it shows a removable thumbnail and `Чек` above the composer.

- [ ] **Step 4: Add exact prompt and send behavior**

Pre-fill the approved prompt after receipt selection so the operator only verifies it and taps Send. Disable Send until the receipt and non-empty text are present.

- [ ] **Step 5: Add exact eight-second async processing**

```swift
for step in SplitAppDemoFixtures.splitikProgress {
    currentProgressText = step.text
    try? await clock.sleep(for: .seconds(step.duration))
}
splitikPhase = .planReady
```

Use injected sleeping in the model test seam so tests complete immediately while production demo timing remains eight seconds.

- [ ] **Step 6: Add detailed plan card and confirmation**

Render all three checks, product allocations, four shares, transfer plan, total 20 000 ₽, and `Подтвердить и отправить приглашения`. On tap, show `Событие создано` and `Приглашения отправлены Пете, Ване и Кате.`

- [ ] **Step 7: Run tests, build, and commit**

Commit title: `feat(demo): build organizer Splitik recording flow`

### Task 4: Invitation and payment notification UI

**Files:**
- Create: `SplitApp/Features/Demo/Views/SplitAppDemoInboxView.swift`
- Create: `SplitApp/Features/Demo/Views/SplitAppDemoEventView.swift`
- Modify: `SplitApp/Features/Demo/Views/SplitAppDemoHomeView.swift`
- Test: `SplitAppTests/SplitAppDemoStoreTests.swift`

**Interfaces:**
- Consumes: invitation and payment state from `SplitAppDemoStore`.
- Produces: actionable participant invitation, participant `Я оплатил`, and organizer `Деньги получены` flows.

- [ ] **Step 1: Add failing tests for role-specific shares and statuses**

Assert Petya `3_000`, Vanya `5_250`, Katya `4_750`, and the accepted/pending status transitions.

- [ ] **Step 2: Implement participant invitation preview**

Reuse the existing inbox card tone. Show Ilya as organizer, all participants, all receipts, and the selected participant's personal share. The primary action is `Вступить`.

- [ ] **Step 3: Implement participant payment action**

Show `Я оплатил`, then `Ожидает подтверждения получателя`, `Платёж отмечен`, and `Илья должен подтвердить получение денег.`

- [ ] **Step 4: Implement organizer payment notifications**

Show three pending cards. Opening one exposes `Деньги получены`. Confirming it updates both the card and Home balance exactly once.

- [ ] **Step 5: Verify zero-balance copy**

The final Home state says `Вы никому не должны` and `Вам никто не должен`; it never says `Все расчёты завершены`.

- [ ] **Step 6: Run tests, build, and commit**

Commit title: `feat(demo): add invitation and payment recording scenes`

### Task 5: Receipt image, operator script, and recording guide

**Files:**
- Create: `SplitApp/Assets.xcassets/DemoReceipt.imageset/Contents.json`
- Create: `SplitApp/Assets.xcassets/DemoReceipt.imageset/demo-receipt.png`
- Create: `scripts/demo_simulator.sh`
- Create: `DEMO_RECORDING_GUIDE.md`
- Test: shell syntax and simulator launch commands.

**Interfaces:**
- Produces: the visible receipt fixture and repeatable build/install/launch workflow.

- [ ] **Step 1: Create the portrait receipt image**

Generate a realistic paper receipt with the exact approved item names and values. Visually inspect the rendered image before bundling it.

- [ ] **Step 2: Implement simulator helper**

```bash
./scripts/demo_simulator.sh organizer splitik-start
./scripts/demo_simulator.sh organizer payment-confirmations
./scripts/demo_simulator.sh petya invitation
./scripts/demo_simulator.sh petya payment
```

The helper maps roles to device names, creates missing devices using iOS 26.5, boots one device, builds with `-target SplitApp`, installs `SplitApp.app`, terminates `tech.splitapp`, and launches with both demo arguments.

- [ ] **Step 3: Write exact operator guide**

Include prerequisites, exact prompt, every tap, expected copy and amount, shot boundary, role/scene launch command, reset behavior, and recovery instructions.

- [ ] **Step 4: Validate shell and documentation**

Run:

```bash
zsh -n scripts/demo_simulator.sh
rg -n "13 000|10 000|4 750|0 ₽|Подтвердить и отправить приглашения" DEMO_RECORDING_GUIDE.md
```

Expected: shell syntax exit 0 and all continuity amounts present.

- [ ] **Step 5: Commit**

Commit title: `docs(demo): add repeatable recording workflow`

### Task 6: Simulator and full-flow verification

**Files:**
- Modify only files required by defects found during verification.

**Interfaces:**
- Consumes: all prior tasks.
- Produces: a verified organizer simulator first, then three participant simulators.

- [ ] **Step 1: Run the full unit suite**

Run:

```bash
xcodebuild test -project SplitApp.xcodeproj -scheme SplitAppUnitTests -destination 'platform=iOS Simulator,name=SplitApp Demo Ilya,OS=26.5'
```

Expected: all tests pass with zero failures.

- [ ] **Step 2: Build and launch organizer Splitik scene**

Run `./scripts/demo_simulator.sh organizer splitik-start`. Verify launch screen, hidden status bar, Home, attachment, exact prompt, eight-second progress, plan card, and confirmation.

- [ ] **Step 3: Launch organizer payment scene**

Run `./scripts/demo_simulator.sh organizer payment-confirmations`. Confirm all three payments and verify `13 000 → 10 000 → 4 750 → 0`.

- [ ] **Step 4: Create and launch participant scenes**

Create Petya, Vanya, and Katya simulators only after organizer visual verification. Verify invitation and payment scenes for each role.

- [ ] **Step 5: Run repository checks**

Run `git diff --check`, inspect the final diff, and confirm only demo-scoped production changes plus documentation are present.

- [ ] **Step 6: Commit verification fixes**

Commit title, only if fixes were required: `fix(demo): polish recording continuity`
