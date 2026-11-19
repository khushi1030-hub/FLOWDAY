# FlowDay — Build Phases

Screen coverage per phase is in `docs/DESIGN_DECISIONS.md` section 3. Phase 12 also includes Task History (p22); Phase 6 also includes the Calendar (p21); Phase 9 includes both reschedule screens (p16 and p19); Phase 7 includes the daily-summary notification (p17); Phase 11 includes the confirmed screen (p20).

Work one phase at a time. A phase is finished only when **every exit check passes**. Commit to git after each phase (`git commit -m "Phase N: ..."`) so you can roll back.

Legend: **Deliverables** = what exists after the phase. **Exit checks** = what you verify before moving on.

---

## Phase 0 — Analysis (no code)
**Deliverables:** `docs/UI_SPEC.md` (every screen from your images), implementation roadmap, list of questions/conflicts.
**Exit checks**
- Every image in `design/screens/` is listed in UI_SPEC with purpose, components, states.
- Colors, fonts, radii, spacing extracted as tokens.
- Open questions are listed; you answered them.
- You said "approved".

## Phase 1 — Foundation
**Deliverables:** architecture folders, dependencies, theme from design tokens, router with placeholder routes, reusable widgets (button, card, task tile, progress ring, input, dialog, bottom nav, app bar, empty state), a `/dev/components` gallery screen.
**Exit checks**
- `flutter pub get`, `flutter analyze` clean.
- App runs on emulator; bottom nav switches between 4 tabs.
- Theme visually matches the design (side-by-side with an image).

## Phase 2 — Database & state
**Deliverables:** `AppDatabase` with schema v1 + migrations, DAOs, repositories, Riverpod providers, seeded categories, `Clock` abstraction.
**Exit checks**
- Repository tests pass (CRUD, transaction rollback).
- Insert a task, kill the app, reopen: it is still there.

## Phase 3 — Onboarding & personalisation
**Deliverables:** onboarding screens per design, name/preferences saved, permission rationale screens, `onboarding_done` flag, router redirect.
**Exit checks**
- Fresh install shows onboarding; second launch skips it.
- Denying permissions does not crash and still lets the user continue.

## Phase 4 — Task management
**Deliverables:** create/edit/delete/detail, validation (title, end > start, within day window), overlap warning, priority, category, fixed/flexible, reminder offset, status resolver, completion + swipe logic (right = complete, left = incomplete, never delete).
**Exit checks**
- Unit tests: create, edit, delete, complete, status changes, conflict detection.
- Widget test: swipe right completes, swipe left marks incomplete, task not deleted.
- Task history row written on completion.

## Phase 5 — Home dashboard
**Deliverables:** greeting, date, progress ring, completed/remaining counts, current/next task, upcoming list, quick actions — all from providers.
**Exit checks**
- Complete a task -> ring and counts change immediately.
- Zero hardcoded numbers (grep for literals).
- Empty day shows the empty state.

## Phase 6 — Daily schedule
**Deliverables:** timeline, time labels, task cards (completed/current/upcoming/delayed/rescheduled/fixed styles), current-time line, free-time gaps, quick-add, day switcher.
**Exit checks**
- Current-time line moves; midnight rollover switches "today".
- Adding a task on Schedule appears on Home without refresh.

## Phase 7 — Notifications & alarms
**Deliverables:** channels, permission flow, `NotificationScheduler.resyncAll()`, start reminders, end-time alarm + alarm screen from design, notification tap routing, boot receiver, Settings note when exact alarms unavailable.
**Exit checks (real device preferred)**
- Task ending in 2 minutes fires an alert with the app closed.
- Editing/deleting a task removes the old notification (no duplicates).
- Reboot -> notifications restored.
- Permission denied path shows guidance, no crash.

## Phase 8 — Smart delay management
**Deliverables:** delayed detection, delay screen (finish now / extra time / adjust / reschedule / carry to tomorrow), extra-time calculator, impact preview.
**Exit checks**
- Your 9:00–12:00 example reproduces: studying past 10:00 shows the affected tasks correctly.
- Unit tests for extra time and multiple delayed tasks.

## Phase 9 — Rescheduling engine
**Deliverables:** pure engine + 3 proposal strategies, compare screen, transactional apply, history, undo, no-valid-schedule explanation.
**Exit checks**
- Property tests: no overlaps, fixed/breaks/completed untouched, durations preserved.
- Transaction failure leaves the DB unchanged (test with a forced error).
- Undo restores exactly; undo blocked after later edits.
- Nothing is applied before confirmation.

## Phase 10 — Focus mode
**Deliverables:** duration picker, start/pause/resume/end, task link, summary, history, restart recovery.
**Exit checks**
- Kill the app mid-session -> reopening recovers correct elapsed time.
- Completed sessions appear in history.

## Phase 11 — Nightly review
**Deliverables:** tomorrow review screen, confirm action, `day_confirmations` logic, scheduling/cancelling rule, settings time picker (default 21:30).
**Exit checks**
- Tomorrow unconfirmed -> notification pending at 21:30.
- Confirm -> pending notification cancelled.
- Edit tomorrow after confirming -> un-confirmed and notification returns.
- Change time to 22:00 -> reschedules. Unit tests cover all four cases.

## Phase 12 — Insights
**Deliverables:** daily/weekly/trend charts, completed vs incomplete, time spent, focus history, adherence.
**Exit checks**
- Numbers match a hand-count from test data.
- Empty state with no data.

## Phase 13 — Settings & polish
**Deliverables:** all settings sections, data export/reset (with confirmation), animations, responsive checks (small/large phones, font scale 1.3), error and empty states everywhere, navigation audit (no dead buttons).
**Exit checks**
- Tap-through checklist of every button passes.
- No overflow errors at 320dp width.

## Phase 14 — Release prep
**Deliverables:** app icon & name, signing config, `flutter build apk --release` / `appbundle`, README with setup and test commands.
**Exit checks**
- `flutter analyze` = 0 issues; `flutter test` all green; integration tests pass.
- Release APK installs and passes the manual checklist on a real phone.

---

## Per-phase workflow (repeat every time)
1. Agent explains the plan + files to touch.
2. Implements.
3. Runs `flutter analyze` and `flutter test`.
4. Fixes failures.
5. Gives you a "how to test manually" list.
6. You test, say "approved" (or report issues).
7. `git commit`.
