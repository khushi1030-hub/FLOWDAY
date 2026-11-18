# FlowDay — System Design

Offline-first Flutter app (Android first, iOS-compatible). No backend, no cloud.

---

## 1. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| UI | Flutter + Dart | Material 3 base, fully custom dark theme |
| State | flutter_riverpod | `AsyncNotifier` / `StreamProvider` over repositories |
| Navigation | go_router | `ShellRoute` for bottom nav, routes for notification taps |
| Database | sqflite (+ `sqflite_common_ffi` for tests) | Plain SQL, versioned migrations. Simpler to learn than drift |
| Preferences | shared_preferences | Onboarding flag, theme, reminder time, toggles |
| Notifications | flutter_local_notifications + timezone + flutter_timezone | Exact scheduling with `zonedSchedule` |
| Permissions | permission_handler | Notifications, exact alarms |
| Charts | fl_chart | Insights screen |
| Audio | just_audio (or audioplayers) | Alarm tone, focus ambience |
| Misc | intl, uuid, wakelock_plus | Dates, ids, keep screen on during focus |

**Rule:** the agent must run `flutter pub add <pkg>` (not hand-write versions) and verify the build after each addition.

---

## 2. Layered architecture

```
Presentation (screens, widgets)  ->  Riverpod providers (state)
        |                                   |
        v                                   v
Domain (entities, pure engines, use cases)  <- NO Flutter imports, fully unit-testable
        |
        v
Data (repositories, SQLite DAOs, DTO mappers)
        |
        v
Core services (DB, notifications, permissions, clock, audio)
```

Dependency rule: presentation -> domain <- data. The **scheduling engine lives in domain and is pure Dart**: no database, no clock calls (a `Clock` is injected), which makes it deterministic and easy to test.

### Folder structure

```
lib/
  main.dart
  app/            app.dart, router/, theme/
  core/
    constants/  database/  notifications/  permissions/
    services/ (clock, audio)  utils/ (time_utils, date_utils)  widgets/
  features/
    onboarding/  home/  tasks/  schedule/  rescheduling/
    focus/  alarms/  insights/  settings/
      each: data/ (models, dao, repository_impl)
            domain/ (entities, repository interface, use cases)
            presentation/ (screens, widgets, providers)
test/
  domain/ data/ widget/
integration_test/
docs/  design/screens/
```

---

## 3. Time model (decide once, use everywhere)

- A task belongs to one **local calendar day**: `date_key` = `'YYYY-MM-DD'`.
- `start_min` and `end_min` = minutes from local midnight (0–1439). Duration = `end_min - start_min`.
- **Tasks may not cross midnight.** If a delay pushes a task past the day-end boundary, it is carried to tomorrow instead. This removes a whole class of bugs.
- "Day window" (e.g. 05:00–23:30) comes from preferences; the engine never schedules outside it.
- Absolute `DateTime` values are derived only when scheduling notifications.
- Timestamps for history rows (`completed_at`, `created_at`) are stored as epoch milliseconds (UTC).

### Status model

Store only what cannot be derived. Derive the rest from the clock.

| Stored `status` | Meaning |
|---|---|
| `pending` | Not finished |
| `completed` | User marked done |
| `incomplete` | User marked not done (left swipe) |
| `rescheduled` | Moved by a confirmed adjustment (flag also kept as `was_rescheduled`) |
| `postponed` | Moved to a later time/day by the user (shown in Task History with the new time) |
| `skipped` | User chose to skip it |

"Missed / Overdue" (Calendar, Schedule chips) is derived: `pending` and past its end time.

> See `DESIGN_DECISIONS.md` for all changes driven by the final UI (preferences, audio assets, recurrence, derived metrics, screen-to-route map). Where this file and `DESIGN_DECISIONS.md` differ, `DESIGN_DECISIONS.md` wins.

Derived at read time (`TaskStatusResolver`, pure function of `status`, `date_key`, `start/end`, `now`):
**Upcoming** (before start), **In Progress** (between start and end), **Delayed** (past end and still `pending`), plus the stored ones.

---

## 4. Database schema (SQLite, version 1)

```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  color INTEGER NOT NULL,          -- ARGB
  icon_key TEXT NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE tasks (
  id TEXT PRIMARY KEY,             -- uuid
  title TEXT NOT NULL CHECK(length(trim(title)) > 0),
  description TEXT,
  date_key TEXT NOT NULL,
  start_min INTEGER NOT NULL CHECK(start_min BETWEEN 0 AND 1439),
  end_min INTEGER NOT NULL CHECK(end_min BETWEEN 1 AND 1440),
  priority INTEGER NOT NULL DEFAULT 1,     -- 0 low, 1 medium, 2 high
  kind TEXT NOT NULL DEFAULT 'task',       -- 'task' | 'break'
  is_fixed INTEGER NOT NULL DEFAULT 0,
  category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  was_rescheduled INTEGER NOT NULL DEFAULT 0,
  alarm_enabled INTEGER NOT NULL DEFAULT 1,   -- end-of-task alarm toggle (design p9)
  notes TEXT,
  icon_key TEXT,
  recurrence TEXT NOT NULL DEFAULT 'never',   -- never | daily | weekly | custom
  recurrence_rule TEXT,                       -- e.g. weekday list for custom
  series_id TEXT,                             -- links generated instances
  has_conflict INTEGER NOT NULL DEFAULT 0,    -- user chose "Keep overlap"
  reminder_offset_min INTEGER,             -- start reminder: minutes before start, NULL = none
  completed_at INTEGER,
  carried_from_date_key TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  CHECK(end_min > start_min)
);
CREATE INDEX idx_tasks_date ON tasks(date_key, start_min);

CREATE TABLE task_events (          -- completion / status history, never deleted with the task's meaning lost
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id TEXT NOT NULL,            -- no FK cascade: history survives task deletion
  task_title TEXT NOT NULL,
  date_key TEXT NOT NULL,
  event_type TEXT NOT NULL,         -- completed | marked_incomplete | extended | moved | carried_forward | deleted
  planned_minutes INTEGER,
  actual_minutes INTEGER,
  occurred_at INTEGER NOT NULL
);

CREATE TABLE focus_sessions (
  id TEXT PRIMARY KEY,
  task_id TEXT,                     -- optional association
  planned_seconds INTEGER NOT NULL,
  elapsed_seconds INTEGER NOT NULL DEFAULT 0,
  state TEXT NOT NULL,              -- running | paused | completed | abandoned
  started_at INTEGER NOT NULL,
  last_resumed_at INTEGER,          -- for restart recovery
  ended_at INTEGER
);

CREATE TABLE day_confirmations (
  date_key TEXT PRIMARY KEY,
  confirmed INTEGER NOT NULL DEFAULT 0,
  confirmed_at INTEGER
);

CREATE TABLE reschedule_batches (
  id TEXT PRIMARY KEY,
  reason TEXT NOT NULL,             -- delay | extra_time | conflict | carryover
  trigger_task_id TEXT,
  proposal_label TEXT,
  created_at INTEGER NOT NULL,
  undone_at INTEGER                 -- non-null once undone
);

CREATE TABLE reschedule_changes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_id TEXT NOT NULL REFERENCES reschedule_batches(id) ON DELETE CASCADE,
  task_id TEXT NOT NULL,
  old_date_key TEXT NOT NULL, old_start_min INTEGER NOT NULL, old_end_min INTEGER NOT NULL,
  new_date_key TEXT NOT NULL, new_start_min INTEGER NOT NULL, new_end_min INTEGER NOT NULL
);
```

**shared_preferences keys:** `onboarding_done`, `user_name`, `day_start_min`, `day_end_min`,
`nightly_review_enabled` (default true), `nightly_review_min` (default 1290 = 21:30 per D6),
`notification_sound`, `alarm_vibrate`, `task_alarms_enabled`, `daily_summary_enabled`, `default_break_min`,
`wake_min`, `sleep_min`, `work_start_min`, `work_end_min`, `focus_ambience`, `focus_silence_enabled`,
`default_focus_minutes`, `theme_mode`, `default_reminder_offset`, `avatar_path`.

**Migrations:** `onUpgrade` runs numbered migration functions (`_migrate1to2`, ...) inside a transaction. Never drop tables to "fix" a schema.

**Seed data:** default categories (Study, Work, Health, Personal, Break...) on first create.

---

## 5. Scheduling engine (pure Dart, deterministic)

Location: `features/rescheduling/domain/`.

### Types
- `ScheduleItem` (id, start, end, priority, isFixed, kind, status)
- `DaySchedule` (date, items, dayWindow)
- `Proposal` (label, moves: `List<TaskMove>`, unchanged ids, carryForward: `List<CarryOver>`, impactSummary, `isValid`)
- `TaskMove` (taskId, oldStart/End, newStart/End)

### Immovable set (never modified by any proposal)
`completed` items, `isFixed` items, `kind == break` items, and anything already in the past.

### Core functions
1. `detectConflicts(DaySchedule)` -> pairs of overlapping items.
2. `freeSlots(DaySchedule, from)` -> gaps between immovable items inside the day window.
3. `applyExtraTime(task, extraMinutes)` -> new end, then computes which later items now overlap.
4. `generateProposals(schedule, trigger)` -> up to 3 valid proposals:

| Proposal | Strategy |
|---|---|
| **A. Shift forward (keep order)** | Push affected flexible tasks later, in original order, into the next free slots. Stops at immovable items (jumps over them). |
| **B. Priority first** | Re-place affected flexible tasks by priority (high -> low), ties by original order. Lowest-priority ones that no longer fit go to tomorrow. |
| **C. Protect the evening / carry lowest** | Keep as many tasks as possible in place, move only the minimum number of lowest-priority flexible tasks to tomorrow. |

Rules every proposal must satisfy (property-tested):
- No overlaps with each other or with immovable items.
- Task durations unchanged.
- Everything inside the day window.
- Fixed tasks and breaks identical before/after.
- Completed tasks untouched.
- If nothing fits, `Proposal.noValidSchedule` with an explanation + carryover suggestion.

5. `proposeCarryover(task, tomorrowSchedule)` -> first free slot tomorrow (preferring the original time of day), plus list of tomorrow's tasks that would conflict.

### Apply flow (never silent)
```
Trigger (alarm tap / delay banner / manual)
  -> user picks extra time or "reschedule"
  -> engine returns proposals
  -> Compare screen (before vs after, moved tasks, impact, tomorrow items)
  -> user selects + confirms
  -> ApplyProposalUseCase: ONE sqflite transaction
        1. re-read current tasks, verify proposal is still valid (stale check)
        2. insert reschedule_batch + reschedule_changes
        3. update tasks (+ was_rescheduled, status)
        4. insert task_events
        5. un-confirm tomorrow if tomorrow was touched
     commit -> then reschedule notifications (outside the transaction)
  -> SnackBar "Schedule updated  [Undo]"
```
**Undo:** `UndoBatchUseCase` reads `reschedule_changes`, restores old values in one transaction, sets `undone_at`. Refuse undo if any affected task was changed since (show a clear message). Undo window: until the next batch or 30 minutes.

---

## 6. Notifications & alarms design

### Channels (Android)
- `task_reminders` (default importance)
- `task_end_alarm` (max importance, alarm sound, full-screen intent)
- `nightly_review` (default)
- `focus` (low)

### Scheduling
- Use `zonedSchedule` with `AndroidScheduleMode.exactAllowWhileIdle` when exact alarms are granted, else fall back to `inexactAllowWhileIdle` and show a note in Settings.
- Notification id = stable hash of `(taskId, kind)` so rescheduling replaces instead of duplicating.
- A single `NotificationScheduler.resyncAll()` rebuilds every pending notification from the DB. Call it: after any task/schedule change, on app start, after boot (`RECEIVE_BOOT_COMPLETED`), and after timezone/time change. This is the cure for duplicates and stale alarms.
- Android 13+ needs `POST_NOTIFICATIONS`; Android 12+ needs `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` handling; add `USE_FULL_SCREEN_INTENT` for the alarm screen.
- Manufacturer battery optimisation (Xiaomi, Oppo, Samsung...): Settings screen explains and links to battery settings.

### End-time alarm
At `end_min` of each pending task: notification with actions **Done** / **+10 min** / **Adjust**. Tapping opens `/alarm/:taskId` (the alarm screen from the design). Foreground: an in-app timer also surfaces the same screen.

### Nightly review (important constraint)
A local notification **cannot check a condition when it fires**. So the rule "only notify when unconfirmed" is implemented by **scheduling/cancelling**:
- Always keep exactly one pending nightly notification for the *next* occurrence of the reminder time, only if tomorrow is **unconfirmed**.
- On confirm tomorrow -> cancel that notification.
- On any edit that un-confirms tomorrow (add/move/delete a task on tomorrow's date) -> set `confirmed = false` and re-schedule (if the reminder time hasn't passed).
- On changing the reminder time in Settings -> cancel and re-schedule.
- `resyncAll()` re-applies the rule on every app open/boot.
- Reminder time is read from preferences; `21:30` is only the default value.

### Navigation from notifications
Payload = `route` string (e.g. `/alarm/abc`, `/review/2026-11-18`). Handle both app-launched-from-notification and foreground/background taps.

---

## 7. Focus mode

- Timer is computed from timestamps, not by counting ticks: `elapsed = saved_elapsed + (now - last_resumed_at)`. This survives app kill/restart.
- On launch, if a `running` session exists, resume it (or finish it if time has elapsed) and show a recovery prompt.
- Finish writes `focus_sessions` + optionally logs time on the linked task.
- Ongoing low-importance notification while running; `wakelock_plus` optional.

---

## 8. Insights (all queries on real data)

| Metric | Source |
|---|---|
| Daily completion % | `tasks` where `kind='task'` for the date |
| Weekly bar chart | group by `date_key`, last 7 days |
| Completed vs incomplete | `tasks.status` |
| Time on tasks | sum of `actual_minutes` in `task_events`, fallback to planned |
| Focus history | `focus_sessions` |
| Schedule adherence | % of tasks completed within their planned window (`completed_at` <= end) |
| Trend | 4-week moving completion rate |

Empty state when no data — never placeholder numbers.

---

## 9. Routing map (go_router)

```
/onboarding            welcome -> benefits -> personalise -> permissions
/ (ShellRoute, bottom nav)
  /home
  /schedule
  /focus
  /insights
  /settings
/task/new, /task/:id, /task/:id/edit
/alarm/:taskId
/delay/:taskId         extra time + options
/reschedule/:batchKey  proposals compare + confirm
/review/:dateKey       nightly review
/settings/notifications, /settings/data, /settings/about
```
`redirect` sends to `/onboarding` until `onboarding_done` is true.

---

## 10. State management pattern

- One repository interface per feature in `domain`, implemented in `data`.
- Providers: `databaseProvider`, `clockProvider`, `taskRepositoryProvider`, `tasksForDayProvider(dateKey)` (stream), `dayProgressProvider(dateKey)`, `schedulerProvider`, `proposalsProvider`, `settingsProvider`.
- The Home and Schedule screens watch the same `tasksForDayProvider`, so one change updates every screen. Invalidate on write.
- A `clockProvider` ticking each minute drives "current time" UI and delayed detection.

---

## 11. Testing strategy

| Level | What |
|---|---|
| Unit (domain) | Engine: conflicts, free slots, extra time, 3 proposals, fixed/break protection, carryover, status resolver, nightly rule |
| Property-style | Randomised schedules: every proposal obeys the invariants in section 5 |
| Data | sqflite_common_ffi in-memory DB: CRUD, transactions rollback on failure, undo, migrations |
| Widget | Swipe right/left behaviour, task form validation, proposal compare screen |
| Integration | Create task -> complete -> progress updates; delay -> reschedule -> undo |
| Manual device | Notifications (killed app, reboot, battery saver), exact alarms, Android 13/14 permissions |

---

## 12. Known risks & decisions to confirm with the designs

1. Tasks cannot cross midnight (section 3) — confirm that is acceptable.
2. Alarm full-screen behaviour differs per Android vendor; needs a real device.
3. iOS has no exact-alarm equivalent; iOS support is "architecture-ready", not tested.
4. Breaks are stored as tasks with `kind='break'` and immovable in the engine.
5. Custom categories: design may only show fixed ones — match the designs.
