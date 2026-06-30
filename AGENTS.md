# AGENTS.md — routine_controller

## Quick start

```powershell
flutter pub get          # install deps
flutter analyze          # lint (uses flutter_lints v6)
flutter test             # single smoke test
flutter run              # run on connected device/emulator
```

## Architecture

- **All state lives in `_RoutineControllerAppState`** (`lib/main.dart`). No state management library. State flows down via constructor props.
- **4 screens** (Home, Habits, Stats, Profile) switched via `BottomNavbar` + `currentIndex`.
- **Services** are stateless static classes in `lib/services/`. No DI, no singletons beyond the static classes themselves.
- **No routing package**, no code generation, no SQLite. All persistence is `shared_preferences`.

## Init order (main.dart:24-31) — MUST follow this sequence

```dart
await NotificationService.init();  // timezone db + notification channels
await BlockListService.init();     // zo_app_blocker + block screen callback
await TimeBlockService.init();     // workmanager registration
```

## Entry-point functions (must stay top-level, annotated with `@pragma`)

| File | Function | Purpose |
|------|----------|---------|
| `lib/services/time_block_service.dart` | `callbackDispatcher()` | Workmanager background task — applies penalty if block not started after 30 min |
| `lib/services/block_list_service.dart` | `onBlockScreenRequested()` | zo_app_blocker isolate callback — shows overlay when user opens blocked app |

Both use `@pragma('vm:entry-point')`. Moving them into classes will break the feature.

## Time block flow

1. User creates a mission with a start time → `_addMission` calls `_startMonitoringMission`
2. 4 escalating OS notifications scheduled at: T-5min, T, T+5min, T+15min
3. If user toggles mission complete before T+30min → `markTimeBlockStarted` cancels penalty + notifications
4. If deadline passes → `callbackDispatcher` fires → `PenaltyService.applyPenalty`:
   - Locks own app for 15 min
   - Resets streak to 0
   - Blocks distracting apps via `zo_app_blocker`

## App blocking (`lib/services/block_list_service.dart`)

Blocked packages: `com.instagram.android`, `com.facebook.katana`, `com.zhiliaoapp.musically` (TikTok), `com.google.android.youtube`, `com.iMe.android`, `org.telegram.messenger`.

Requires Usage Stats + Overlay permissions. Permission banners shown on home screen if missing.

## Escalating notification IDs

Each mission gets `missionId.hashCode.abs() % 100000` as base, then +1 through +4 for the 4 notification slots. Penalty notification uses hardcoded `id: 9999`.

## Lock screen

When `PenaltyService.isAppLocked()` is true, `build()` returns `_buildLockScreen()` instead of the normal app. Lock screen polls every 1s while locked. Lock expires → `PenaltyService` auto-unblocks apps and removes lock.

## Noteworthy conventions

- Dark theme only. Uses custom `AppColors` class with Material You-style color roles.
- Debounced save: `saveMissions()` uses a 300ms `Timer` to batch writes (main.dart:282-301).
- Undo snackbars for both mission and habit deletion.
- Midnight habit reset: checks `lastHabitCheckDate` on load, resets `isCompletedToday` + zeroes streak if incomplete.

## Tests

Only one test (`test/widget_test.dart`) — smoke test that pumps `RoutineControllerApp` and asserts it renders. No widget or unit tests for services.
