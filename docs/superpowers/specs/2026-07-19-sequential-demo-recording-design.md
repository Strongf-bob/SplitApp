# Sequential SplitApp Demo Recording Design

## Goal

Prepare a deterministic local iOS demonstration of SplitApp that can be recorded one simulator and one role at a time. The visible flow must look like a coherent multi-user interaction while avoiding network, LLM, OAuth, clock, and cross-simulator synchronization dependencies.

The first deliverable is the organizer flow for Ilya. Petya, Vanya, and Katya are recorded afterward as independent local roles.

## Product boundary

This is an explicitly isolated demo runtime, not a replacement for production networking or domain behavior. It is activated only through process launch arguments. Normal launches continue using the current authentication, API, Splitik, invitation, receipt, balance, and payment implementations.

No visible debug menu, role selector, demo badge, clock, carrier, or battery indicator may appear in the recording.

## Chosen architecture

Use a single deterministic demo state machine embedded in the iOS application.

- `SplitAppDemoRole` selects `organizer`, `petya`, `vanya`, or `katya`.
- `SplitAppDemoScene` selects the exact recording state.
- `SplitAppDemoStore` owns role-specific events, invitations, balances, receipts, chat messages, and payment notifications in memory.
- Launch arguments activate demo mode before the normal authentication bootstrap.
- The root application hides the status bar while demo mode is active.
- Each simulator is independent. Apparent cross-user changes are represented by launching the appropriate predefined scene.
- User actions within a scene still mutate real SwiftUI state so taps, loading states, confirmations, and transitions look natural.

The demo must not call the backend, Yandex OAuth, S3, or an LLM.

## Roles and canonical data

### Organizer

- Display name: Илья.
- Existing friends: Петя, Ваня, Катя.
- Existing completed background event: `День рождения Димы`.
- New event: `Поездка за город`.

### Expenses

- Дом: 12 000 ₽, paid by Илья, split equally: 3 000 ₽ each.
- Бензин: 2 000 ₽, paid by Петя, split equally: 500 ₽ each.
- Шашлык: 3 000 ₽, shared by Илья, Петя, Ваня: 1 000 ₽ each.
- Вино: 1 500 ₽, shared by Илья, Петя, Катя: 500 ₽ each.
- Сок: 1 500 ₽, shared by Ваня and Катя: 750 ₽ each.

### Final shares

- Илья: 5 000 ₽.
- Петя: 5 000 ₽, with 2 000 ₽ already paid and 3 000 ₽ remaining.
- Ваня: 5 250 ₽ remaining.
- Катя: 4 750 ₽ remaining.
- Илья receives 13 000 ₽ in total.

## Recording scenes

### Scene 1: Organizer introduction and Splitik plan

Launch role `organizer`, scene `splitik-start`.

1. Show the SplitApp launch presentation.
2. Open the organizer home screen as Илья.
3. Show current balance, `День рождения Димы`, recent activity, and the Splitik tab.
4. Open Splitik.
5. Tap the attachment button and select the bundled demo receipt image.
6. Show an image preview labelled `Чек` above the composer.
7. Enter the exact prompt from the recording guide.
8. Send the message.
9. Run an exactly eight-second deterministic sequence:
   - `Читаю чек…`
   - `Нашёл 3 позиции на сумму 6 000 ₽`
   - `Нахожу Петю, Ваню и Катю среди ваших друзей…`
   - `Распределяю расходы…`
   - `Строю удобный план переводов…`
   - `Готовлю событие…`
10. Present the complete event-plan card with participants, receipts, item allocations, participant shares, and transfer plan.
11. Tap `Подтвердить и отправить приглашения`.
12. Show `Событие создано. Приглашения отправлены Пете, Ване и Кате.`

The attachment picker is intentionally limited to the bundled demo receipt in demo mode. It should look like an in-app receipt selection sheet rather than a debug fixture control.

### Scene 2: Organizer accepts marked payments

Launch role `organizer`, scene `payment-confirmations`.

1. Show `Поездка за город` with four participants and three checks.
2. Show `Вам должны: 13 000 ₽`.
3. Open the in-app notification inbox containing three payment notifications.
4. Open Petya's notification and tap `Деньги получены`; the outstanding amount becomes 10 000 ₽.
5. Open Vanya's notification and tap `Деньги получены`; the outstanding amount becomes 4 750 ₽.
6. Open Katya's notification and tap `Деньги получены`; the outstanding amount becomes 0 ₽.
7. Return to the home screen showing zero debts.

Do not show or automatically set the copy `Все расчёты завершены`.

### Scene 3: Participant accepts invitation

Launch each participant role with scene `invitation`.

1. Open the in-app notification inbox.
2. Show `Илья приглашает вас в событие «Поездка за город»`.
3. Open the compact preview with organizer, participants, three receipts, and the current role's personal share.
4. Tap `Вступить`.
5. Show `Приглашение принято` and add the event to the local home screen.

The existing invitation wording and interaction pattern should be reused where practical. No push-notification arrival animation is required.

### Scene 4: Participant marks money sent

Launch each participant role with scene `payment`.

- Petya sees 3 000 ₽ remaining.
- Vanya sees 5 250 ₽ remaining.
- Katya sees 4 750 ₽ remaining.

Each participant opens the event, taps `Я оплатил`, and sees:

- status `Ожидает подтверждения получателя`;
- confirmation `Платёж отмечен`;
- explanatory copy `Илья должен подтвердить получение денег.`

## Organizer home presentation

The organizer home screen must remain consistent with the current SplitApp visual language. Demo data is injected into existing presentation models when possible instead of replacing the whole navigation shell.

The background event `День рождения Димы` is visible in the event list. The active-card area and recent activity remain readable and populated. Splitik stays in the existing bottom navigation.

## Splitik demo UI

The demo Splitik view keeps the existing chat styling and adds:

- an attachment button with a minimum 44-point touch target;
- a removable receipt preview;
- deterministic progress rows;
- a detailed, scrollable plan card;
- one primary confirmation action;
- an explicit post-confirmation message.

Progress timing is driven by a monotonic async sequence and totals exactly eight seconds from send to final response. Reduced Motion removes decorative transitions but does not change the total scripted duration.

## Payment notifications

Payment notifications are local in-app records, not APNs notifications. They appear in the existing Inbox surface and have stable identifiers, sender names, amounts, event name, status, and an acceptance action.

Accepting a payment is idempotent. A second tap cannot reduce the balance twice. Accepted notifications move out of the actionable list and the organizer balance is recalculated from accepted payment IDs.

## Demo launch and reset

Demo state is reproducible from launch arguments; no manual data cleanup is required. Terminating and relaunching a scene restores its canonical initial state.

Supported arguments:

```text
-SplitAppDemoRole organizer|petya|vanya|katya
-SplitAppDemoScene splitik-start|payment-confirmations|invitation|payment
```

A repository script will build the target, create the requested simulator if missing, install the app, terminate the previous process, and launch the chosen role and scene.

The initial operator workflow creates only `SplitApp Demo Ilya`. The three participant simulators are created after the organizer flow has been visually verified.

## Receipt asset

The repository contains one bundled portrait receipt image with these exact visible values:

```text
МАГАЗИН «ПРОДУКТЫ»

Шашлык                 3 000 ₽
Вино                   1 500 ₽
Сок                    1 500 ₽

ИТОГО                   6 000 ₽
```

Additional date, receipt number, store, cashier, and QR-like decoration may be present, but the three item names and amounts must remain unambiguous.

## Operator documentation

Create `/DEMO_RECORDING_GUIDE.md` containing:

- prerequisites;
- one-command simulator setup;
- one-command launch for every role and scene;
- exact Splitik prompt;
- required tap sequence;
- expected copy and balances after every action;
- recommended shot boundaries and montage continuity notes;
- reset and recovery commands;
- a checklist confirming the status bar is hidden before recording.

## Testing

Unit tests cover:

- launch-argument parsing;
- canonical role and scene fixtures;
- eight-second Splitik progress ordering;
- exact expense allocations and transfer amounts;
- invitation acceptance idempotency;
- participant payment marking idempotency;
- organizer payment confirmation sequence and balances `13 000 → 10 000 → 4 750 → 0`;
- production mode remaining disabled without demo arguments.

Build and simulator verification cover:

- target-based Debug build;
- installation and launch on `SplitApp Demo Ilya`;
- hidden status bar;
- launch presentation;
- organizer Splitik scene;
- organizer payment-confirmation scene;
- later, the three participant roles.

## Success criteria

- The organizer sequence can be re-recorded with identical content and timing.
- Every visible amount and participant name matches the canonical scenario.
- No system time or visible demo/debug controls appear.
- No network, OAuth, LLM, S3, or second simulator is required for the organizer recording.
- Participant invitation and payment scenes can be recorded independently in any order.
- Relaunching a scene resets it to its documented starting point.
- Production launches behave exactly as before when demo arguments are absent.
