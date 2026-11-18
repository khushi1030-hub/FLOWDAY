# FLOWDAY — Product Requirements

FlowDay is an offline-first smart daily planner for Android (iOS-ready architecture). It helps a user plan the day on a timeline, get alerted when a task's time is up, handle delays without stress, and confirm tomorrow's plan every night.

Tagline: **Plan smart · Stay flexible · Flow better**

UI source of truth: `design/flowday_ux.pdf` + `design/screens/`. Conflicts between UI and this file are resolved in `docs/DESIGN_DECISIONS.md`.

---

## 1. Product goals

The app must answer, at any moment:
1. What do I need to do today, and at what time?
2. Am I on schedule?
3. What happens if I run late?
4. How are the remaining tasks adjusted?
5. What carries to tomorrow?
6. How am I doing over time?
7. Is tomorrow's schedule ready?

## 2. Principles (non-negotiable)

- **Offline-first.** No backend, cloud, accounts, analytics or ads. All data on device.
- **Never silent.** The app never changes a user's schedule without showing a proposal and getting confirmation.
- **Protect what matters.** Fixed tasks, breaks and completed tasks are never moved by the engine.
- **Real data only.** Every number on screen (progress, streak, insights) is computed from stored data.
- **Calm tone.** Friendly, encouraging copy; no guilt messaging.

## 3. Users and first-run

Single local user. First launch: Splash -> 3 intro screens (skippable) -> Personalize (name, wake-up, sleep, nightly reminder time, notification sound, default break) -> Notification permission (explained first, skippable) -> Home. Onboarding completion is stored; it is never shown again.

## 4. Features

### 4.1 Home
- Greeting with the user's name and today's date.
- Today card: completion % ring, "X of Y tasks completed", status chip (On track / Behind), Done / Remaining / Focus-time tiles.
- "Now" card for the task in progress: priority, category, minutes in, minutes left, progress bar, **Focus mode** and **Mark done** actions.
- Today's schedule: vertical timeline, swipe right = complete, swipe left = incomplete + adjust flow. "See all" opens Schedule.
- Floating "+" opens New Task. Bottom nav: Home, Schedule, Insights, Settings.

### 4.2 Tasks
Create, edit, delete, view. Fields: title, description, date, start, end, duration (+/- stepper), category (Study, Work, Health, Personal, Social, Break), priority (Low/Medium/High), flexible or fixed, start reminder (e.g. 5/10 min before), end-of-task alarm on/off, repeat (Never/Daily/Weekly/Custom), notes.
- Live preview card on the form.
- Live conflict check ("No conflicts — this slot is free" / overlap warning).
- Validation: title required, end after start, within the day, no crossing midnight.
- Overlap while editing offers: shift affected flexible tasks (best), revert the change, or keep the overlap.
- Delete requires confirmation. Swipe never deletes.

Statuses: Upcoming, In Progress, Delayed/Overdue (derived from time); Completed, Incomplete, Postponed, Skipped, Rescheduled (stored).

### 4.3 Schedule
- Header with month, Today / Tomorrow / Calendar tabs, week day strip, chips: completed / pending / overdue.
- Timeline with time labels, current-time marker, task cards (completed struck through, current highlighted with progress, overdue with **Reschedule**, fixed with lock, breaks dashed "protected"), free-time blocks tappable to add a task.
- Calendar: month and week views, coloured dots per day (completed, upcoming, rescheduled, missed), monthly totals, list of the selected day with "Open day".

### 4.4 Alarms and notifications
- Local notifications only. Exact alarms where permitted; graceful fallback otherwise.
- Start reminder before a task (per-task setting).
- **End-of-task alarm** at the end time: full-screen alarm UI showing time, task name, "Did you complete your task?" with slide or buttons for Completed / Not completed, plus **Snooze 5m**, **+10 min**, **Dismiss**.
  - Completed -> Task Completed screen.
  - Not completed -> Unfinished/Adjust screen.
  - +10 min -> extends the task and re-schedules its alarm (impact preview if it collides).
- Daily summary notification (e.g. "You completed 7 of 8 tasks today").
- Nightly review notification (section 4.8).
- Alarm sound (4 options with preview), vibration toggle.
- Notifications are rebuilt from the database on app start, after reboot, after time-zone change and after any schedule change, so duplicates and stale alarms cannot occur.

### 4.5 Task completion
- Completed screen: task summary (duration, on time/late, deep-focus minutes), today's progress and change, streak, next task, **Continue to Next Task**, **Back to Home**.
- Completion writes a history record and updates progress and insights.

### 4.6 Smart delay management
Triggered by the end-time alarm, the Overdue card, left swipe, or "Not completed".
- Screen "No worries! Let's adjust your schedule": task, allocated time vs current time, "How much work is left?" (15m / 30m / 45m / 1h+), and three choices:
  1. **Add Extra Time** -> sheet with 10 / 15 / 30 / 45 / 1h / Custom, new end time, **impact on upcoming tasks** (shifted, break affected, overlaps, fixed), Apply or Cancel.
  2. **Reschedule Later Today** -> first free slot that fits.
  3. **Move to Tomorrow** -> first free slot tomorrow with its conflicts shown.
- If extra time collides with a fixed task, the user is routed to Smart Rescheduling.
- Never auto-move an important task to another day.

### 4.7 Smart rescheduling
Deterministic, rule-based engine (no AI, no randomness).
- **Immovable:** completed, fixed, breaks, past time.
- Screen: reason header (e.g. "+60 min needed"), **Before & after** timeline, a "no conflicts" summary, and a list of plans (A recommended, B, C, D). Examples: extend and shift flexible tasks; move a lower-priority task later; postpone to tomorrow; keep original and mark unfinished.
- New-plan variant: when a new fixed plan conflicts with tasks, offer: move flexible tasks (best fit), reschedule, change durations (flexible only, user-confirmed), move to another day, or keep the overlap.
- Apply is one atomic transaction, with history stored and **Undo** available.
- If no valid plan exists, explain why and suggest carrying forward.
- Footer message: "Nothing is deleted or moved without your approval."

### 4.8 Nightly review
- Default reminder time is configurable (see decisions D6). Editable in Settings and onboarding.
- Sent **only if tomorrow is unconfirmed**. If confirmed, no reminder. If the user edits a confirmed day, it becomes unconfirmed again and the reminder is restored (when its time has not passed).
- Review screen: tomorrow's date, wake/sleep, stats (tasks, planned, breaks, free), task list with carried-over badges, free-time blocks (tap to add), per-task menu (Change time, Priority, Move to next day, Edit, Delete), **Add Task**, **Edit Schedule**, conflicts shown, **Confirm Tomorrow's Plan**.
- Confirmed screen: "Sleep well" message, Confirm Schedule / Make more changes.

### 4.9 Focus mode
- Opens for a task: title, time range, category, priority, countdown ring ("Ends in"), today's goal (task notes), focus toggle (silence FlowDay's other notifications), ambience: Rain / Lo-fi / Silence, **Start Task**.
- Controls: start, pause, resume, end. Timer survives app restart (computed from timestamps).
- On finish: saves the session and offers to mark the task complete.
- Focus time feeds the Home "Focus" tile, "Deep focus" and Insights.

### 4.10 Insights
- Day / Week / Month switch.
- Weekly productivity % with change vs previous period and a friendly summary.
- Tiles: tasks completed, most productive hours, average task delay, rescheduled count.
- Charts: weekly completion % bars; tasks done by hour curve.
- Encouraging note on light days.
- **Task History**: filters by period, status (All, Completed, Incomplete, Postponed, Skipped) and category; grouped by day with postponed target shown.

### 4.11 Settings
Profile (name, avatar), Preferences. Notifications: task alarms, nightly review, reminder time, alarm sound, vibration. Schedule: default break, working hours, wake-up, sleeping time. Appearance (dark; see decisions). Help, About, Privacy Policy, Reset data. Version footer.

## 5. Data (stored locally)

Tasks, categories, task events/history, focus sessions, day confirmations, reschedule batches and changes, recurring series, and preferences. Schema and migrations: `docs/SYSTEM_DESIGN.md`.

## 6. Worked example (must be a test)

Schedule: 09:00-10:00 Study, 10:00-10:30 Breakfast, 10:30-11:30 Assignment, 11:30-12:00 Break (protected), 12:00-13:00 Exercise (fixed).
User is still studying at 10:00 and asks for +30 min.
Expected: Study ends 10:30; Breakfast and Assignment (flexible) shift later; Break unchanged; Exercise unchanged; if something no longer fits it is offered for tomorrow; user sees before/after and confirms; one transaction; Undo available.

## 7. Edge cases to handle

Late finish, early finish, multiple delayed tasks, fixed vs flexible conflicts, no free slots, carry to tomorrow, midnight rollover, notification permission denied, exact alarm unavailable, app killed during focus or during a task, duplicate reminders, editing a confirmed day, overlaps kept by the user, DB errors, empty days, invalid data. The app must never crash; show clear, kind messages.

## 8. Out of scope (v1)

Cloud sync, accounts/login, sharing or collaboration, widgets, wearables, calendar import, AI/LLM features, iOS testing (architecture stays compatible).

## 9. Quality bar

`flutter analyze` clean, unit tests for scheduling/status/nightly rules/transactions/undo, widget tests for swipe and forms, integration tests for key flows, manual test on a real Android device for alarms and reboot behaviour.
