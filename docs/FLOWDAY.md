# FLOWDAY: MASTER BUILD PROMPT FOR CLAUDE IN GOOGLE ANTIGRAVITY

You are acting as a **Senior Flutter Engineer, Mobile App Architect, UI/UX Implementer, and QA Engineer** in one role. Your job is to **build the complete, working FlowDay mobile application as real files in this workspace**, using the terminal and file tools available to you. Do NOT answer with an architecture document, a tutorial, or isolated code snippets. Create the Flutter project, write every file, run the commands, fix the errors, and verify the result.

---

## 0. NON-NEGOTIABLE WORKING RULES

1. **Build, don't describe.** Every deliverable is a real file in the project. Use `flutter create`, write files, run `flutter pub get`, `flutter analyze`, `flutter test`, and run the app on an emulator/simulator/device when available.
2. **No placeholders.** No `// TODO`, no `throw UnimplementedError()`, no fake or hard-coded data in production paths, no "implement later". Every screen listed below must be functional and wired to real state and the real database.
3. **The attached UX Pilot PDF is the source of truth for UI.** Do not redesign. Do not substitute your own layout, colours, spacing, or icons where the PDF specifies them.
4. **Work in phases (Section 19).** Finish one phase fully, run its verification gate, commit, then report briefly before starting the next. Do not skip ahead. Do not stop between phases to ask permission unless you are blocked.
5. **Fix your own errors.** If `flutter analyze` or a test fails, fix it before moving on. Zero analyzer errors and zero warnings at the end of every phase.
6. **Be honest about limitations.** Where iOS or Android platform rules limit behaviour (Section 13), implement the best compliant approach and document the limitation in `docs/PLATFORM_LIMITATIONS.md`. Never claim something works if you have not run or tested it. If you cannot run an emulator in this environment, say so and rely on analyzer, unit, and widget tests, and list what still needs manual device testing.
7. **Verify package versions.** Use the latest stable compatible versions on pub.dev (check with `flutter pub add` / `flutter pub outdated`). If a package API differs from what you remember, read the package's actual documentation or source in `.pub-cache` rather than guessing.
8. **Never auto-change the user's schedule without explicit confirmation.** This rule applies to the whole app (see Section 12).
9. **Commit discipline.** Initialise git and commit at the end of every phase with a clear message.

---

## 1. PROJECT OVERVIEW

- **App name:** FlowDay
- **Tagline:** *Plan Smart. Stay Flexible. Flow Better.*
- **Purpose:** A smart daily planner and adaptive scheduling app that helps users organise tasks, manage time, stay focused, track productivity, and automatically *suggest* better schedules when plans change.
- **Platforms:** Android and iOS (single Flutter codebase).
- **Offline-first:** Everything works with no backend and no network. No accounts, no cloud, no analytics SDKs.
- **Design style (from the PDF):** Premium, modern **dark-first UI**: near-black background, charcoal rounded cards with hairline borders, a violet/lavender accent with soft glow, mint-green / coral / amber semantic colours, white pill buttons, subtle radial purple glows behind hero elements, beautiful geometric sans typography, minimal professional layout, smooth animations, responsive screens. White is used for primary-on-dark buttons, selected chips and the "NOW" card, not for page backgrounds.

---

## 2. STEP ZERO: ANALYSE THE ATTACHED UX PILOT PDF (MANDATORY BEFORE ANY CODE)

The 15-page UX Pilot PDF of FlowDay's UI designs is attached to this conversation. Section 2A below is a pre-analysis of it that you must verify and refine; if 2A and the PDF disagree, the PDF wins. If it is not in the workspace, ask me to add it, and copy it to `design/flowday_ux.pdf` once available. **Do not start coding until you have studied it.** If you cannot access or read the PDF, STOP and tell me. Do not invent screens.

Do the following and save the results in `docs/UI_SPEC.md`:

1. **Page-by-page inventory.** For each of the 15 pages: screen name, purpose, every visible element (headers, cards, buttons, chips, toggles, icons, charts, bottom bars, illustrations), text content, states shown, and the navigation it implies.
2. **Design tokens extracted from the PDF:** exact colour palette (primary purple, lavender tints, gradient stops and direction, background, surface, text primary/secondary, success/warning/error, priority colours High/Medium/Low, category colours), typography (font family, sizes, weights, line heights), corner radii, spacing scale, elevation/shadow values, icon style, button styles, input styles, bottom navigation style, chart styles. Where a value must be estimated from the image, say so and keep it consistent.
3. **Component inventory:** list every reusable component you will build (e.g. gradient header, stat card, progress ring, task card, priority chip, category chip, timeline slot, time picker field, bottom sheet, primary/secondary button, empty state).
4. **Screen to feature map:** map each PDF page to the features in Section 4, and flag any feature in Section 4 that has **no screen in the PDF**. For those, design the screen yourself strictly in the same visual language, and list them under "Screens not in PDF" so I can review them.
5. **Conflicts or ambiguities:** list anything unclear. Make a reasonable decision, record it, and continue. Do not block on minor ambiguities.

After writing `docs/UI_SPEC.md`, print a concise summary of it and proceed to Phase 1.

**Fidelity target:** Final screens should match the PDF as closely as Flutter allows in layout, colour, typography, spacing, radius, and shadows. Compare each implemented screen against its PDF page at the end of its phase and correct deviations.

---

## 2A. PRE-ANALYSIS OF THE PDF (A HEAD START; VERIFY EVERYTHING AGAINST THE PDF, AND WHERE THEY DIFFER THE PDF WINS)

The PDF has 15 mobile pages, **dark theme only**, made with UX Pilot. All names, dates and times in the PDF (e.g. "Khushi", "Tuesday, May 14", "May 2024", "Learn Flutter", "Practice DSA", "Aarav") are **sample data**. Never hard-code them; the app must show the real user's name, today's real date, and real tasks.

### Design tokens (estimated from the images; refine by sampling the PDF)
- **Backgrounds:** page ≈ `#050505`–`#0A0A0C`; card/surface ≈ `#131316`–`#17171B`; inset/tile ≈ `#1C1C21`; hairline border ≈ `#26262D`. Hero areas have a faint radial purple glow (≈ `#2A2150` fading to black).
- **Accent violet:** buttons/selected ≈ `#8B7CF6`; light lavender for headline accents and icons ≈ `#B3A5FF`; primary buttons have a soft violet drop-glow beneath them. The splash/alarm backgrounds use a deeper purple gradient (≈ `#3A2E78` to black).
- **Semantic:** success mint ≈ `#6FD6A8`; danger/overdue/High coral ≈ `#FF8F85`; warning/Medium/Break amber ≈ `#F5A25D`; Low = neutral grey. Text: primary white, secondary ≈ `#9A9AA3`, tertiary ≈ `#6B6B74`. Tinted chip backgrounds are the semantic colour at ~12–18% opacity.
- **Typography:** headings in a geometric grotesque with tight tracking (looks like Plus Jakarta Sans or similar; large bold white headlines with the second line in lavender); body/UI in Inter-like sans. Section labels are small, UPPERCASE, letter-spaced, grey. Times use tabular figures. Pick the closest `google_fonts` match, record it in `docs/UI_SPEC.md`.
- **Shape:** cards ~20 dp radius, buttons ~16–20 dp (full-width pill-ish), chips ~10–12 dp, icon tiles ~12 dp rounded squares, timeline cards ~14 dp. Primary FAB is a 56 dp violet rounded square with glow, bottom-right above the nav bar.
- **Nav bar:** 4 tabs, **Home, Schedule, Insights, Settings**; active tab = white icon + label with a small violet dot beneath; inactive = grey.

### Screen inventory (PDF page → what to build)
1. **Welcome slide 1, "Plan your day your way."** FlowDay logo tile + wordmark top-left, "Skip" top-right, hero illustration (phone mock of a day timeline with floating task cards "Learn Flutter", "Workout", "Coffee break" and a star badge), 3-dot page indicator (active dot is an elongated white pill), headline (second line lavender), body text, white "Next →" button.
2. **Welcome slide 2, "Stay on track, effortlessly."** Hero = glowing alarm clock illustration with a notification card ("Time's up · Learn Flutter"), and a floating "Today 3 / 5, 60% on track" mini progress card. Build the hero illustrations with Flutter `CustomPaint`/widgets (no image assets available).
3. **Welcome slide 3, "Plans change. Your schedule adapts."** Hero = "Today" timeline card with a "Smart reschedule" pill, a completed "Morning run", a highlighted violet "Practice DSA" card with a "moved" badge, a locked "Lunch", and a dashed arrow showing the move. Button becomes violet **"Get Started →"**. "Skip" jumps to personalization.
4. **Personalize (step 1 of 2).** Back button, 2-segment progress bar ("1 of 2"), headline "Let's personalize your flow ✨", **Your name** field (focused violet border, green check when valid), **Daily rhythm** two tiles (Wake-up time default 07:00 AM, Sleeping time default 11:00 PM, each opens a time picker), **Nightly planning reminder** row (time + "We'll ask you to review tomorrow", chevron → time picker), **Notification sound** radio list with play/preview buttons: *Soft Chime, Morning Breeze, Crystal Bell, Lo-fi Piano*, **Default break** chips *5m 10m 15m 20m 30m* (15m selected default, selected = white chip), violet **Continue** button (scrolls; keep the button pinned).
5. **Notifications (step 2 of 2), "Never miss an important moment."** Bell hero with two floating chips ("DSA starts in 5 min", "Review tomorrow?"), three explainer rows (Task reminders; End-of-task alarms, "even when locked"; Nightly schedule review at the chosen time, dynamic text), "No spam. You control every alert in Settings.", violet **Enable Notifications** button (triggers the real OS permission flow, plus exact-alarm guidance on Android) and a **Skip for now** text button.
6. **Home.** Avatar (user photo placeholder/initial) + date line + "Good Morning, {name}! ☀️" (time-aware emoji/greeting) + bell with unread dot. Summary card with progress ring (percentage + "today"), status pill ("On track" / other states), "{n} of {m} tasks completed", encouraging sub-line, and three stat tiles **DONE / REMAINING / FOCUS (1h 24m)**. White **NOW** card: "NOW" dot label, priority chip (High), task icon tile, title, "09:00 – 10:00 AM · 60 min · Study", "24 min in / 36 min left" with progress bar, buttons **Focus mode** (black) and **Mark done** (grey). **Today's schedule** (+ "See all →" to the Schedule tab) with hint "Swipe right to complete · left to adjust", then a **vertical timeline with a time rail and status dots** (green = done, violet = in progress, hollow = upcoming, amber = break). Cards: completed (struck-through, green check), in-progress (violet border + "In progress" pill), upcoming (priority + category chips, "Upcoming", drag handle), **Break** (dashed amber border, "Protected"), a **NEW** badge on tasks created today. Swipe actions: right = Complete (green), left = Adjust (opens extra-time/reschedule). FAB (+) opens New task.
7. **Schedule tab.** Header "Schedule" with month-year label, search and calendar icon buttons; segmented control **Today / Tomorrow / Calendar**; horizontal week strip (Sun–Sat, selected day = violet rounded tile, small dots = day has tasks, green dot = completed day); status chips "2 completed", "4 pending", "1 overdue"; **hourly timeline** with a red **current-time pill ("09:24")** and line; task blocks sized to duration: completed (struck-through, green left bar), **overdue** (coral border, warning icon, **Reschedule** pill), NOW (solid violet with progress bar), upcoming (title, "10:00 – 11:00 · 60m · Study", priority chip, "Pending"), Break (dashed amber, "30m · protected"), **fixed appointment** (lock icon, "Fixed appointment"), and a dashed **free slot** ("+ Free · 01:30 – 02:30", tap to create a task there). Today/Tomorrow share this layout; **Calendar** = month grid + selected-day list (design it in the same language; not in the PDF).
8. **New task.** Close (X) and a magic-wand (smart suggestion) button; **live Preview card**; Task title; Description; grouped card with **Date** row, **Start/End** time tiles and **Duration stepper (– 45 min +)**; green "No conflicts — this slot is free." line (turns into a coral conflict message with the reschedule options when overlapping); **Category** chips *Study, Work, Health, Personal, Break* (selected = white); **Priority** *Low / Medium / High* (selected tinted amber/coral); **Flexible task** switch ("FlowDay may suggest moving it if plans change", off = Fixed); **Reminder** row ("10 min before", chevron) and **End-of-task alarm** switch; **Repeat** chips *Never, Daily, Weekly, Custom*; dashed **Add notes** button; sticky bottom bar **Cancel / Save Task**.
9. **Edit task (with conflict resolution).** Back + red delete button; Title field with category icon; Date row; Start / **End · edited (coral)** / Duration tiles; a **coral-bordered conflict card "This overlaps with 2 tasks. Nothing changes until you choose."** with a mini timeline (edited task in violet, affected items dashed with ×) and three radio options: **"Shift Project Work to 11:45 AM" (BEST, "Keeps a 15-min break. Lunch stays fixed at 12:30.")**, **"Keep DSA at 60 min" (revert end time)**, **"Keep the overlap" ("I'll sort it out myself.")**; then Priority, Category, Reminder rows; **Cancel / Save Changes**. This card is the inline surface for the rescheduling engine's ranked proposals (the radio options are generated, not static). The engine may offer more than three; show the best ones plus "Keep my schedule as is" and "Keep the overlap".
10. **Focus (pre-start state).** Chevron-down (minimise) and "⋯" menu; "Starts now" pill; "Time to focus! 🎧"; big task title, time range, category + priority chips; **large circular countdown** ("ENDS IN 60:00 at 10:00 AM") in violet; **TODAY'S GOAL** card (from the task's goal/notes); **Focus mode** card (moon icon, "Silence other notifications" switch) with **Rain / Lo-fi / Silence** chips; white **Start Task** button. After starting: ring depletes, button becomes Pause/Stop, goal items checkable. (Implement "silence other notifications" as: suppress FlowDay's non-critical notifications during the session, and on Android optionally request Do-Not-Disturb access; on iOS say plainly it cannot control system DND.)
11. **Alarm ("FLOWDAY ALARM").** Purple gradient top, sound and vibration toggle icons top-left, glowing clock ring with the big time (e.g. "10:00 AM"), "Time's up! ⏰", task title, "Your {task} session is complete · 09:00 – 10:00 AM", question **"Did you complete your task?"**, a **slide-to-answer control** (drag left = Not completed, drag right = Completed), plus two tap buttons (**Not completed** coral, **Completed** green) as the accessible alternative, then **Snooze 5m**, **+ 10 min** (adds 10 extra minutes to the task, which goes through the impact check, see Section 4J) and **Dismiss**. Your brief also requires a 10-minute snooze: add **Snooze 10m** as a long-press/menu option on the Snooze chip and as a notification action. Record this as a deliberate deviation in `docs/UI_SPEC.md`.
12. **Task completed.** Close button, glowing green check hero with confetti stars, "Amazing! 🎉 Task completed.", result card (icon, title, time, category, green check; three tiles **planned Duration / "On time" or "+8m late" Finished / Deep focus minutes**), **Today's progress** card (percentage with ↑ delta vs yesterday, "{n} of {m} tasks", gradient violet→mint bar, "N-day streak" chip), **NEXT** row (next task and time), white **Continue to Next Task →**, "Back to Home".
13. **Task not completed, "No worries! Let's adjust your schedule."** Back/close, hourglass hero, task card with "Unfinished" chip, **ALLOCATED** and **CURRENT TIME** tiles, **"How much work is left?"** chips *15m, 30m, 45m, 1h+*, then **CHOOSE WHAT WORKS** option cards: **Add Extra Time** ("Keep going now · see impact on next tasks"), **Reschedule Later Today** ("Free slot found · 02:00 – 02:30 PM", computed from real free slots; disabled with explanation if none), **Move to Tomorrow** ("Wed, May 15 · 09:00 AM (first slot)", computed), an encouraging note ("One unfinished task doesn't have to ruin your entire day. Progress counts, too."), and a white **Continue** button.
14. **Extra-time bottom sheet, "How much more time do you need?"** Grab handle, close; "{task} · originally ends 10:00 AM"; 3×2 grid **10 / 15 / 30 / 45 min, 1 hour, Custom** (selected = white); **NEW END TIME** card (old time struck through, new time, "+30 min" pill); **Impact on upcoming tasks** list with per-row status (**Shifted**, **Shortened to 15m**, **Overlaps lunch**, **Fixed** with lock), a hint "…Smart Rescheduling will offer options." when a fixed task is hit, **Cancel / Apply Changes**. When the impact contains a fixed-task collision or unresolved overlap, Apply opens the proposals screen (Section 12) instead of applying directly.
15. **Splash.** Dark purple radial glow with faint grid, glowing rounded-square logo tile, three animated loading dots, spaced uppercase tagline **"PLAN SMART · STAY FLEXIBLE · FLOW BETTER"**.

### Screens required by the brief but NOT in the PDF (design them in this exact dark visual language; list them in `docs/UI_SPEC.md` for my review)
**Insights tab** (daily/weekly toggle, productivity ring, completed vs pending, focus-hours chart, completion %, streak card, task history list with filters), **Settings tab and sub-pages** (profile, wake/sleep, default break, notification preferences, alarm/notification sound picker reusing the onboarding list, vibration, nightly reminder time + toggle, theme, data management), **Calendar** (month + week views), **Nightly review screen** for tomorrow with a **Confirm schedule** button, **Task details** screen, **full-screen reschedule proposals** screen (ranked proposal cards with before/after mini-timelines using the same visual patterns as pages 9 and 14), **category management**, **permission-denied banners/dialogs**, **empty states**, **delete/recurring-scope dialogs**, and **Import/Export/Clear data** dialogs.

### Behaviour implied by the PDF that must be implemented
- **Productivity % is count-based** (38% = 3 of 8, 50% = 4 of 8). Breaks and skipped items are not counted as tasks.
- Home "Focus" = total focus time today; "Deep focus" on the completion screen = that task's focused minutes (from focus sessions); "↑12%" = change vs yesterday's productivity.
- Swipe-to-complete / swipe-to-adjust on home timeline cards; drag handles on upcoming cards allow reordering/moving (any move goes through conflict detection and confirmation).
- A **Break** is a first-class protected item (category Break, amber dashed style, "Protected"); the engine shrinks or moves it only as a last resort and always shows that in the impact.
- Tasks have `alarm_enabled` (End-of-task alarm switch) and a `reminder_offset` (default 10 min) in addition to the columns in Section 6. Each task has an `icon_key` derived from its category/title.
- Task categories: **Study, Work, Health, Personal, Break** (seed these five with the PDF's icons/colours; custom categories optional).
- Notification sounds seeded: **Soft Chime, Morning Breeze, Crystal Bell, Lo-fi Piano** (preview playback in onboarding and Settings).
- **Conflict between brief and PDF:** the PDF shows the nightly reminder as 09:30 PM, while the brief says the default is **10:00 PM**. Use **10:00 PM as the default**, show the user's chosen time everywhere dynamically (never hard-code "09:30 PM"), and note this in `docs/UI_SPEC.md`.
- **Light theme is not designed.** Build the dark theme exactly; implement `ThemeMode` plumbing with dark as the only polished theme. If a light theme is added later it must be flagged as undesigned.

---

## 3. TECHNOLOGY STACK (REQUIRED)

| Area | Choice |
|---|---|
| Framework / language | Flutter (latest stable), Dart (null-safe, strict analysis) |
| UI | Material 3 (`useMaterial3: true`), custom `ThemeData` built from extracted tokens; **dark theme is the primary and only designed theme** (per the PDF) |
| State management | **Riverpod** (`flutter_riverpod`; use `Notifier`/`AsyncNotifier`/`StreamProvider`; code generation optional, keep it simple and consistent) |
| Local database | **SQLite** via `sqflite` (+ `path`); schema versioning and migrations |
| Settings | `shared_preferences` |
| Navigation | `go_router` with a `StatefulShellRoute` for the bottom navigation |
| Notifications / alarms | `flutter_local_notifications`, `timezone`, `flutter_timezone`, `permission_handler`; exact alarm scheduling on Android; `vibration` for vibration patterns |
| Audio | `just_audio` or `audioplayers` for focus sounds and alarm tones (bundled assets) |
| Charts | `fl_chart` |
| Calendar | `table_calendar` (style it to match the PDF) |
| Utilities | `intl`, `uuid`, `equatable`, `collection`, `wakelock_plus`, `google_fonts` (or bundled fonts matching the PDF) |
| Testing | `flutter_test`, `mocktail`, `integration_test`, `sqflite_common_ffi` for DB tests |
| Lints | `flutter_lints` or `very_good_analysis` with strict casts/inference/raw-types |

Do not add a backend, Firebase, or any network dependency. Keep the dependency list minimal and justified.

Bundle all audio (rain, lo-fi, alarm tones, notification sounds) as **royalty-free or self-generated assets** under `assets/audio/`, and document sources and licences in `docs/ASSET_LICENSES.md`. If you cannot obtain suitable files, generate simple looping tones/noise programmatically (e.g. with a script) and say so. Never use copyrighted audio.

---

## 4. FEATURE REQUIREMENTS (ALL MUST BE IMPLEMENTED)

### A. Onboarding
- Welcome screens (swipeable, with page indicator) and app introduction, as shown in the PDF.
- Personalization flow collecting: **user name**, **wake-up time**, **sleeping time**, **notification preferences** (task reminders, end-of-task alarms, nightly review, with OS permission requests at the right moment), **default break duration**, **nightly reminder settings** (enabled toggle and time, default 10:00 PM).
- Validation (name required, sleep and wake times sensible, handle a sleep time after midnight).
- Persist results; show onboarding only on first launch; make it re-enterable from Settings only where the PDF or sensible UX implies it.

### B. Home Dashboard
- Time-aware greeting ("Good morning / afternoon / evening, {name}") and the current date.
- Daily productivity percentage (defined in Section 11), completed tasks count, remaining tasks count, focus time today.
- **Current active task** card: title, category, priority, time range, **live remaining time countdown**, progress bar, and a **Mark complete** button. Handle "no active task" gracefully (show the next task or an empty state).
- Upcoming tasks list (today), each tappable.
- Daily progress overview (ring/bar as in the PDF).
- Updates live as time passes and tasks change (no manual refresh needed).

### C. Task Management
- Create, edit, delete (with confirmation and undo) tasks.
- Fields: title (required), description, notes, **start time and end time** with **automatic duration calculation** (editing duration updates end time and vice versa), date, category, priority (High / Medium / Low), **fixed vs flexible**, reminder(s), recurrence, completion status.
- Categories: seeded defaults (e.g. Work, Study, Health, Personal, Meeting, Other) with the colours from the PDF; allow adding custom categories if consistent with the PDF/UX.
- Reminders: choose offset before start (at start, 5, 10, 15, 30 min, custom).
- Recurring tasks: daily, weekdays, weekly (choose days), monthly, optional end date or count. Editing/deleting a recurring task must ask: "This task only / This and future / All".
- Validation: end after start, no task crossing into impossible states, warn on conflicts (do not hard-block unless a fixed task would be overlapped. In that case show the conflict and require explicit acknowledgement).

### D. Smart Schedule
- **Today** and **Tomorrow** views, **Weekly calendar**, **Monthly calendar**, **Hourly timeline** (vertical, scrollable, current-time indicator, tasks as positioned blocks sized by duration, fixed tasks visually distinct).
- **Task conflict detection** (visual flag on overlapping tasks) and **available time-slot detection** (show free gaps, tappable to create a task in that slot).
- Schedule management: drag/tap to edit, quick-add, and a way to **confirm tomorrow's schedule** (feeds the nightly review, Section 4K).
- Month view shows per-day task indicators; tapping a day opens that day's schedule.

### E. Smart Rescheduling (CORE FEATURE, see Section 12 for the full algorithm)
When a task runs longer than expected: detect conflicts, calculate affected tasks, find available slots, protect fixed appointments, preserve breaks where possible, prioritise important tasks, generate multiple alternative schedules, show the impact of every change, and **require user confirmation before applying anything**.

### F. Focus Mode
- Full-screen immersive interface (matching the PDF), keeps screen awake.
- Countdown timer tied to the current task (pause/resume/stop), current task info and **task goals** (user can list goals per task; checkable in focus mode).
- Sound selector: **Rain, Lo-fi, Silence**. Loops seamlessly, fades in/out, stops cleanly on exit, respects audio focus/interruptions.
- Focus session tracking: record start, end, planned vs actual seconds, sound used, completed flag. Sessions survive app backgrounding (timer is computed from timestamps, not tick counts).
- Finishing a session leads into the Task Completion flow (4H).

### G. Notifications and Alarms
- **Task-start reminders** and **end-of-task alarms** with configurable sounds and vibration.
- Notification actions: **Completed**, **Not Completed**, **Snooze 5 min**, **Snooze 10 min**.
- Work when the app is backgrounded or killed, subject to platform limitations (Section 13).
- Reschedule everything after device reboot (Android), timezone change, and app update. Re-sync scheduled notifications whenever tasks or settings change.

### H. Task Completion
On completion: congratulations screen/animation (as in the PDF), **actual completion time** vs planned, update daily progress, calculate **focus duration**, and show the **next task** with a start button.

### I. Incomplete Task Management
When "Not Completed": ask **how much time is left**, then offer: **Add extra time**, **Reschedule later today**, **Move to tomorrow**. Always show the **scheduling impact** (affected tasks, moved tasks, breaks changed) before applying. Confirmation required.

### J. Extra Time Management
Options: **10 min, 15 min, 30 min, 45 min, 1 hour, custom**. Calculate the new end time, detect overlapping tasks, show affected tasks, and suggest smart adjustments via the rescheduling engine. Confirmation required.

### K. Nightly Schedule Review
- Default reminder time **10:00 PM**; user-customisable in Settings (and onboarding).
- Check whether **tomorrow's schedule is confirmed**. **Send the reminder only if it is unconfirmed.** Do **not** send it if already confirmed.
- The reminder opens a **review screen** for tomorrow where the user can view, add, edit, and delete tomorrow's tasks, then tap **Confirm schedule**.
- Implementation approach (important, because a local notification cannot run logic when the app is killed): schedule one nightly-review notification **per upcoming date** (rolling 7-day window, deterministic IDs by date). Whenever tomorrow's schedule is confirmed, **cancel that night's pending reminder**; when a confirmed day is edited or becomes unconfirmed again, **re-schedule it**. Re-sync this window on app launch, resume, settings change, and reboot. A day with zero tasks counts as unconfirmed. Define and document "confirmed" in `docs/BUSINESS_RULES.md`. Editing a confirmed day's tasks resets it to unconfirmed unless the user re-confirms.

### L. Insights and Analytics
Daily productivity, weekly productivity, completed tasks, pending tasks, focus hours, completion percentage, **productivity streak**, progress charts (bar/line/ring per the PDF), and **task history** (filterable list by date/category/status). Include empty states. All figures derive from real DB data using the formulas in Section 11.

### M. Settings
Profile management (name), wake-up and sleeping time, default break duration, notification preferences, alarm sounds (with preview), vibration, nightly reminder settings, theme preferences, **data management** (export to JSON, import from JSON, clear all data with double confirmation).

---

## 5. ARCHITECTURE: CLEAN ARCHITECTURE, FEATURE-BASED

Three layers per feature, with dependencies pointing inward only:

- **presentation**: widgets, screens, Riverpod notifiers/providers (UI state)
- **domain**: entities, value objects, repository **interfaces**, use cases (pure Dart, no Flutter or sqflite imports). The scheduling engine lives here and must be a **pure, deterministic, fully unit-tested** module.
- **data**: SQLite data sources, DAOs, models/mappers, repository **implementations**

Rules: no business logic in widgets; no DB access from presentation; repositories return domain entities; use a `Result`/sealed-class pattern (or `AsyncValue`) for failures instead of throwing across layers; inject everything through Riverpod providers so every dependency can be overridden in tests. Inject a `Clock` abstraction everywhere time is used so time-dependent logic is testable.

### Folder structure (create exactly this, extend as needed)

```
flowday/
  design/flowday_ux.pdf
  docs/ (UI_SPEC.md, ARCHITECTURE.md, BUSINESS_RULES.md, PLATFORM_LIMITATIONS.md,
         ASSET_LICENSES.md, TEST_REPORT.md)
  assets/ (audio/, images/, icons/, fonts/)
  lib/
    main.dart
    app/ (app.dart, router/, di/)
    core/
      constants/  error/  utils/ (clock, date/time helpers)  widgets/ (shared components)
      theme/ (colors, gradients, typography, spacing, radii, shadows, app_theme.dart)
      services/ (notification_service, alarm_service, audio_service, permission_service)
      database/ (app_database.dart, migrations/, tables/)
    features/
      onboarding/      {data, domain, presentation}
      home/            {data, domain, presentation}
      tasks/           {data, domain, presentation}
      schedule/        {data, domain (conflict + free-slot detection), presentation}
      rescheduling/    {domain (engine), presentation (proposal/impact UI)}
      focus/           {data, domain, presentation}
      notifications/   {data, domain, presentation (alarm screen, snooze)}
      completion/      {domain, presentation (celebration, incomplete, extra time)}
      nightly_review/  {data, domain, presentation}
      insights/        {data, domain, presentation}
      settings/        {data, domain, presentation}
  test/ (unit/, widget/, golden/ optional, helpers/)
  integration_test/
  android/ ios/   (configured per Section 14)
```

Write `docs/ARCHITECTURE.md` (short) describing layers, providers, and data flow as actually built.

---

## 6. DATABASE DESIGN (SQLite)

Use `sqflite`, `PRAGMA foreign_keys = ON`, a versioned `onCreate`/`onUpgrade` with migration files, indexes on date/time columns, and **all multi-step writes inside transactions**. Store timestamps as **epoch milliseconds (UTC)** plus a `date_key` (`yyyy-MM-dd`, local) for fast day queries. Handle DST and timezone changes safely.

Tables (adjust column details sensibly, but keep these concepts):

- **categories**(id, name, color_value, icon_key, is_default, sort_order)
- **tasks**(id, title, description, notes, category_id→categories, priority [0 low/1 medium/2 high], is_fixed, date_key, start_at, end_at, planned_duration_min, status [pending / in_progress / completed / not_completed / rescheduled / skipped], actual_start_at, actual_end_at, actual_duration_min, completed_at, series_id (nullable), is_series_exception, created_at, updated_at)
- **task_goals**(id, task_id, text, is_done, sort_order)
- **task_reminders**(id, task_id, offset_minutes, notification_id)
- **recurrence_rules**(id, frequency, interval, weekdays_mask, day_of_month, start_date, end_date, count, template_json)
  Recurring tasks are **materialised** as concrete `tasks` rows for a rolling window (e.g. 30 days ahead), regenerated on launch and nightly. Exceptions edit single rows.
- **focus_sessions**(id, task_id, started_at, ended_at, planned_seconds, actual_seconds, sound, completed)
- **day_confirmations**(date_key PK, is_confirmed, confirmed_at)
- **reschedule_log**(id, created_at, trigger_task_id, strategy, proposal_json, applied, applied_at) for history and undo
- **scheduled_notifications**(id, task_id nullable, kind [start/end/nightly/snooze], fire_at, notification_id) so the app can reconcile and cancel precisely

SharedPreferences keys (via a typed `SettingsRepository`): onboarding_completed, user_name, wake_time, sleep_time, default_break_min, notifications_enabled (+ per-kind toggles), alarm_sound, vibration_enabled, nightly_enabled, nightly_time (default 21:30 per D6), theme_mode, focus_default_sound, last_sync_window.

Provide DAOs/repositories with: CRUD, queries by day/range/status/series, overlap query, aggregates for insights, export/import (JSON with schema version), and `clearAll()`. Write migration tests.

---

## 7. STATE MANAGEMENT (RIVERPOD)

- Providers for: database, repositories, services, `clockProvider`, settings, onboarding status.
- Notifiers for: tasks by date (stream-backed so UI updates reactively), current active task (re-evaluates every second via a ticker provider that is auto-disposed when unused), schedule view state (selected date, view mode), task form state, focus session state, reschedule proposal state, nightly review state, insights aggregates, settings.
- Use `AsyncValue` for loading/error/data with proper UI for each. Use `ref.listen` for side effects (navigation, snackbars). Keep providers small, scoped, and testable with `ProviderContainer` overrides.

---

## 8. NAVIGATION STRUCTURE

`go_router` with:
- Redirect logic: first launch → onboarding; afterwards → home. Guard against deep-link entry before onboarding.
- Bottom navigation shell (match the PDF exactly for tabs, icons, and any centre action): typically **Home, Schedule, Insights, Settings** with an add-task action. Preserve tab state.
- Full-screen routes outside the shell: onboarding, task create/edit, task details, focus mode, task-completed celebration, incomplete-task sheet/screen, extra-time sheet, reschedule proposal, nightly review, alarm screen, settings sub-pages.
- **Notification deep links:** tapping a notification or an action must route correctly in all app states (foreground, background, terminated), e.g. end-of-task alarm → alarm/completion screen, nightly reminder → nightly review for the correct date, start reminder → task details/focus start.
- Smooth transitions (shared-axis/fade-through per Material 3), hero/animated transitions only where they match the PDF.

---

## 9. UI/UX IMPLEMENTATION INSTRUCTIONS

- Build `core/theme` **first** from the extracted tokens (Section 2) and build every screen only from theme tokens and shared components. No hard-coded colours/sizes in screens.
- Dark surfaces on a near-black background, violet/lavender accents, soft violet glows under primary buttons and behind hero elements, and violet-to-mint gradients on progress bars, exactly as in the PDF. Do not introduce light backgrounds.
- Typography: use the PDF's font (or the closest available match via `google_fonts`/bundled font) with a consistent type scale.
- **Animations:** animated progress ring/bars, count-ups for stats, smooth page transitions, bottom-sheet motion, a tasteful completion celebration (confetti/check animation using Flutter's own animation tools, no heavy dependencies), animated list insert/remove, press feedback on cards/buttons. Keep animations 150–400 ms, 60 fps, and respect "reduce motion" accessibility settings.
- **Responsive:** support small phones to large phones, text scale up to 1.3×, portrait primarily; tablets should not break (constrain content width). No overflow errors on any screen, including with long titles.
- **Accessibility:** semantic labels, minimum 48 dp touch targets, sufficient contrast, screen-reader-friendly timers (avoid announcing every second).
- **States everywhere:** loading skeletons or indicators, empty states (with illustration/message and call to action), error states with retry, offline is the normal state.
- Time formatting respects the device's 12/24-hour setting; date formatting via `intl` and the device locale.
- Provide a debug-only "preview/time travel" option (behind `kDebugMode`) to simulate time for testing alarms and rescheduling. It must be absent from release builds.

---

## 10. BUSINESS LOGIC (document in `docs/BUSINESS_RULES.md`, implement in domain layer)

- **Duration** = end − start; editing either keeps the model consistent. Minimum duration 5 minutes. Tasks may not span beyond the sleep boundary without a warning.
- **Task statuses and transitions:** pending → in_progress → completed | not_completed → rescheduled / (moved to tomorrow). Only valid transitions are allowed.
- **Active task:** the task whose [start, end) contains now, or one explicitly started via focus mode. If several overlap, prefer the one with a running focus session, then higher priority, then earlier start.
- **Conflict:** two tasks on the same day overlap if `a.start < b.end && b.start < a.end`. Back-to-back tasks are not conflicts.
- **Free slot:** a gap within the user's waking window (wake→sleep) of at least a minimum length (default 15 min) not occupied by any task.
- **Break:** the user's default break duration is the desired buffer between consecutive flexible tasks. Breaks are treated as soft constraints the engine tries to preserve.
- **Fixed vs flexible:** fixed tasks are never moved or resized by the app automatically. Flexible tasks may be moved only through a confirmed proposal.
- **Day confirmation rules:** see Section 4K.

---

## 11. PRODUCTIVITY AND ANALYTICS FORMULAS

- **Daily productivity %** = round(100 × completed tasks ÷ total non-skipped, non-break tasks that day). This is **count-based** to match the PDF (3 of 8 → 38%, 4 of 8 → 50%). Define and document the handling of days with no tasks (show 0% / "no tasks" state, don't divide by zero) and of tasks moved to another day (they count for their new day, not the old one). Status pill thresholds (e.g. "On track") must be defined in `BUSINESS_RULES.md` (compare actual vs expected progress for the time of day).
- **Completion %** = completed ÷ total tasks (count-based) for the period.
- **Focus time** = Σ `actual_seconds` of focus sessions (include partial sessions).
- **Weekly productivity** = average of daily values over days that had tasks, plus per-day bars.
- **Productivity streak** = consecutive days (ending today or yesterday) where daily productivity ≥ a documented threshold (default 60%). Today does not break the streak until the day ends.
- Insights charts must handle ranges with no data and a single data point gracefully.

---

## 12. SMART RESCHEDULING ALGORITHM REQUIREMENTS (HIGHEST PRIORITY)

Implement as a **pure Dart domain module** (`features/rescheduling/domain/`) with no UI or DB dependency, taking an immutable snapshot of the day and returning proposals. It is triggered by: extra time added (4J), task "Not Completed" with remaining time (4I), a running task exceeding its end time, or a manual "Optimise my day".

### Inputs
Day's tasks (with priority, fixed/flexible, status, start/end), the trigger (task + new required end time or remaining minutes), `now`, wake/sleep window, default break duration, minimum free-slot size.

### Required behaviour
1. **Detect conflicts:** compute the extended task interval and every task it newly overlaps or pushes into.
2. **Calculate affected tasks:** the transitive set of tasks that must move because of the overlap (cascade), excluding completed and past tasks.
3. **Find available slots:** compute free gaps in the remaining waking window of today (and tomorrow's window if needed).
4. **Protect fixed appointments:** fixed tasks are immovable obstacles. If an extension itself collides with a fixed task, report an explicit **fixed-conflict** and offer choices (shorten the extension, end earlier, move the extended task's remainder elsewhere). Never move the fixed task.
5. **Preserve breaks:** keep the configured break between flexible tasks; when time is insufficient, shrink breaks down to a documented minimum (e.g. 5 min) **before** dropping tasks, and report each reduced break in the impact.
6. **Prioritise important tasks:** order for placement by priority (High > Medium > Low), then original start time. Low-priority flexible tasks are the first candidates to be deferred to tomorrow when today is too full. High-priority tasks should keep today's slots where possible.
7. **Generate alternatives:** produce **2–4 distinct proposals** with different strategies, for example:
   - **Minimal shift:** push affected flexible tasks later, preserving order, changing as little as possible.
   - **Priority first:** reorder so High-priority tasks keep their slots/earliest times; lower ones move.
   - **Protect breaks:** keep all breaks, defer lowest-priority tasks to tomorrow if needed.
   - **Compress:** shrink breaks (never below the minimum) to keep everything today.
   Deduplicate identical proposals. Rank by a documented scoring function (fewer moved tasks, fewer deferrals, no fixed conflicts, preserved breaks, priority respected, finishing before sleep time).
8. **Show impact of every change:** each proposal exposes a structured diff: per task `before → after` (time, day), counts of moved/deferred/shrunk items, breaks reduced, high-priority tasks affected, new end-of-day time, and any warnings (e.g. "ends after your sleep time").
9. **Ask for confirmation:** the UI presents the proposals (cards with a before/after timeline preview and impact summary) and an option **Keep my schedule as is / Cancel**. **Nothing is written to the database until the user taps Apply.** Applying is **one atomic transaction**, logged in `reschedule_log`, followed by notification re-sync, and followed by a **snackbar with Undo** that restores the previous state.
10. **Edge cases that must be handled and tested:** no free slot anywhere; extension runs past sleep time; multiple fixed tasks in a chain; extension across midnight; already-completed or already-started tasks; zero affected tasks (just apply extension after confirmation); overlapping tasks that already existed; DST day; a recurring task instance; user cancels; stale proposal (schedule changed after the proposal was generated → regenerate and tell the user).

Produce `docs/BUSINESS_RULES.md` sections explaining the scoring function and each strategy. Write extensive unit tests (Section 16) covering every rule above.

---

## 13. TIMER, ALARM AND NOTIFICATION IMPLEMENTATION

**Timers:** Never rely on `Timer.periodic` tick counts for correctness. Store target end timestamps and compute remaining time from the `Clock` on each tick and on app resume, so timers stay correct after backgrounding, device sleep, and process death. Active focus session state must be persisted so it can be restored.

**Notification service (`core/services/notification_service.dart`):**
- Initialise `flutter_local_notifications` with the `timezone` database and the device's local timezone; update on timezone change.
- Channels (Android): `task_reminders`, `task_alarms` (high importance, alarm sound/vibration, full-screen intent where permitted), `nightly_review`, `focus_session` (ongoing, low importance). iOS: categories with actions, Time Sensitive interruption level where applicable.
- Use **exact scheduling** (`zonedSchedule` with `AndroidScheduleMode.exactAllowWhileIdle`/alarm-clock mode) for start reminders and end alarms.
- **Actions:** Completed, Not Completed, Snooze 5, Snooze 10. Handle taps/actions in foreground, background (top-level `@pragma('vm:entry-point')` handler that can open the DB and update state safely), and terminated states. Snooze reschedules a new notification (tracked in `scheduled_notifications`). "Completed" marks the task complete and cancels remaining notifications for it. "Not Completed" opens the app to the incomplete-task flow.
- A central **`NotificationScheduler`** reconciles desired notifications (derived from tasks + settings) against `scheduled_notifications`, adding, updating, and cancelling to match. Call it after any task/setting/confirmation change, on app start/resume, after boot, and on timezone change. Use deterministic notification IDs. Respect the **iOS limit of 64 pending local notifications** by scheduling the soonest first and refilling on app launch/resume.
- Alarm sound and vibration selectable per settings; vibration patterns via `vibration`. Provide an in-app **alarm screen** (matching the design language) shown when an alarm is tapped, with the four actions.
- **Permission flows:** Android 13+ `POST_NOTIFICATIONS`; Android 12+ exact alarm permission (`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` as appropriate), battery-optimisation guidance; iOS notification authorisation. Request them in context, explain why, and handle denial gracefully with a settings deep link and a degraded-mode banner. Never crash if permission is denied.
- **Android manifest/config:** receivers for scheduled notifications and boot completed (reschedule after reboot), permissions (`VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`, exact alarm, `USE_FULL_SCREEN_INTENT`, `WAKE_LOCK` if needed), core library desugaring if required.
- **iOS config:** `UNUserNotificationCenter` delegate setup in `AppDelegate`, `Info.plist` entries, notification sounds in the bundle (under the iOS length limit), background modes only if justified.
- **Document limitations honestly** in `docs/PLATFORM_LIMITATIONS.md`: iOS has no true alarm API (notifications may be silenced by Focus/Do Not Disturb or the silent switch, sounds are limited to ~30 s, 64 pending limit); OEM battery managers on Android can delay or kill alarms; exact alarms can be revoked by the user; notifications cannot execute arbitrary logic at fire time (hence the pre-computed nightly-review approach in Section 4K).

---

## 14. ANDROID AND iOS COMPATIBILITY

- Android: minSdk 23 or higher (choose per package requirements), target the latest stable SDK, Gradle/AGP/Kotlin versions compatible with the installed Flutter, adaptive launcher icon, splash screen (Android 12+ splash API), release build config with R8/ProGuard rules that don't break plugins.
- iOS: deployment target per the plugins' requirements, `Info.plist` usage strings, app icon set, launch screen matching the PDF's splash, CocoaPods integrated.
- Generate app icons and splash screens from FlowDay's branding in the PDF (`flutter_launcher_icons` / `flutter_native_splash` as dev dependencies).
- Verify `flutter build apk --debug` succeeds; attempt `flutter build ios --no-codesign` if on macOS; otherwise state it was not run.
- Handle safe areas, notches, gesture navigation, edge-to-edge, and system font scaling on both platforms.

---

## 15. ERROR HANDLING

- Typed failures (`DatabaseFailure`, `ValidationFailure`, `PermissionFailure`, `SchedulingFailure`, `NotificationFailure`) mapped to friendly, actionable user messages. Never show raw exceptions.
- Global error capture (`FlutterError.onError`, `PlatformDispatcher.instance.onError`, `runZonedGuarded`) writing to a local log; a polished fallback error screen instead of the red screen in release.
- Validate all user input at the form level and again in domain use cases.
- DB: migration failure strategy (back up, then recreate with a user warning only as a last resort), transactional writes, handle corrupt/missing data without crashing.
- Notification/permission failures degrade gracefully with in-app banners, never silent failure.
- Import/export: validate JSON schema/version, show a preview of what will be imported, and never partially apply a bad import.
- Destructive actions require confirmation; deletes of tasks support Undo.

---

## 16. TESTING REQUIREMENTS

Write real, passing tests and report results in `docs/TEST_REPORT.md`.

- **Unit tests (high coverage on domain):** duration calculation; conflict detection; free-slot detection (including midnight, wake/sleep bounds); recurrence generation (daily/weekly/monthly, DST, end date/count); productivity formulas and streak; day-confirmation logic; nightly-reminder decision logic (unconfirmed → scheduled, confirmed → cancelled, re-unconfirmed → re-scheduled); notification ID/reconciliation logic; **the rescheduling engine** (every rule and edge case in Section 12, including: fixed protected, breaks preserved/compressed, priority ordering, deferral to tomorrow, no-slot case, determinism, multiple distinct proposals, impact diff accuracy).
- **Database tests** using `sqflite_common_ffi`: CRUD, migrations, transactions/rollback, overlap queries, aggregates, export/import round trip.
- **Widget tests:** task form validation and auto-duration; task card; home dashboard states (active/none/loading/error); timeline rendering; proposal/impact screen (nothing applied until confirm); extra-time sheet; nightly review confirm flow; settings changes persisting.
- **Integration tests (`integration_test`):** onboarding → create task → appears on Home and Schedule; complete task → progress updates → next task shown; extend task with conflicts → proposals shown → apply → schedule updated → undo; focus session start/stop recorded; settings change reschedules notifications (with the notification service faked).
- Run `flutter analyze` and `flutter test --coverage`; target ≥ 80% coverage on `domain/` and ≥ 70% overall. Fix flakiness; use the injected `Clock` rather than real time.
- Manual QA checklist in `docs/TEST_REPORT.md` for things you cannot automate (real alarm firing on device, vibration, background/terminated behaviour, reboot rescheduling, iOS silent switch), clearly marked as "needs device verification".

---

## 17. PERFORMANCE AND QUALITY BAR

Cold start under ~2 s on mid-range devices; no jank on the timeline and calendar (use `const` constructors, `ListView.builder`, avoid rebuilding whole screens each second; isolate the ticking widget); database queries indexed; no memory leaks (dispose controllers, audio players, tickers, and wakelocks); app works fully in airplane mode; no network permission requested.

---

## 18. DELIVERABLES CHECKLIST (the project is "done" only when ALL are true)

- [ ] `docs/UI_SPEC.md` written from the PDF; every PDF page implemented and visually compared
- [ ] Every feature A–M implemented, wired to real data, and manually exercised
- [ ] Smart rescheduling engine complete with multiple proposals, impact preview, confirmation, atomic apply and undo
- [ ] Nightly review sends only when tomorrow is unconfirmed; configurable time; confirmed days cancel the reminder
- [ ] Notifications/alarms with all four actions working through the app-state matrix (as far as testable) and rescheduled after reboot/timezone change
- [ ] Focus mode with Rain / Lo-fi / Silence and session tracking
- [ ] `flutter analyze` clean; `flutter test` green; coverage targets met
- [ ] `flutter build apk --debug` succeeds (and iOS build attempted where possible)
- [ ] All docs present (`ARCHITECTURE`, `BUSINESS_RULES`, `PLATFORM_LIMITATIONS`, `ASSET_LICENSES`, `TEST_REPORT`) plus a `README.md` with setup/run/test instructions
- [ ] Final report: what was built, what was verified and how, known limitations, and anything needing manual device testing

---

## 19. DEVELOPMENT PHASES (EXECUTE IN ORDER; VERIFY AND COMMIT AT EACH GATE)

**Phase 0: PDF analysis and plan.** Complete Section 2. Check `flutter doctor`; report any environment problems. Output `docs/UI_SPEC.md`. *Gate: spec written; environment confirmed.*

**Phase 1: Project scaffold and design system.** `flutter create`, git init, dependencies, lints, folder structure, DI, router skeleton, `core/theme` from tokens, shared components (buttons, cards, chips, progress ring, gradient header, bottom nav, sheets, empty/error/loading states), a hidden debug "component gallery" screen to compare against the PDF. *Gate: app runs; gallery matches PDF; analyzer clean.*

**Phase 2: Data layer and core domain.** Database, migrations, DAOs, entities, repositories, settings repository, `Clock`, seeding categories, recurrence materialiser, export/import. *Gate: DB and domain unit tests pass.*

**Phase 3: Onboarding and Settings.** All onboarding steps with validation and persistence; full Settings screens (profile, times, breaks, notifications, sounds, vibration, nightly reminder, theme, data management). *Gate: first-launch flow works; settings persist across restarts; widget tests pass.*

**Phase 4: Task management.** Task form (create/edit), validation, auto-duration, categories, priority, fixed/flexible, reminders, recurrence (with scope prompts), notes/goals, details screen, delete with undo. *Gate: full CRUD works; tests pass.*

**Phase 5: Home dashboard.** Greeting, date, stats, active-task card with live countdown and Mark complete, upcoming list, progress overview, live updates. *Gate: matches PDF; reacts live to changes.*

**Phase 6: Smart schedule views.** Today, Tomorrow, week, month, hourly timeline, conflict flags, free-slot detection and quick add, tomorrow confirmation control. *Gate: all views match PDF; conflicts and free slots accurate (tests).*

**Phase 7: Notifications and alarms.** Services, channels, permissions, scheduler/reconciler, actions (Completed/Not Completed/Snooze 5/10), deep links, alarm screen, boot/timezone rescheduling, platform configs, limitations doc. *Gate: scheduling logic tests pass; manual device checklist prepared.*

**Phase 8: Focus mode.** Full-screen UI, timestamp-based countdown, goals, Rain/Lo-fi/Silence audio, session persistence and tracking, wakelock, interruption handling. *Gate: sessions recorded; timer correct after backgrounding.*

**Phase 9: Completion, incomplete-task and extra-time flows.** Celebration screen, actual time and focus duration, next task; "how much time is left?"; extra-time options with overlap detection (before the engine is attached, show conflicts; the engine plugs in during Phase 10). *Gate: flows work end to end.*

**Phase 10: Smart rescheduling engine and UI.** Pure engine, strategies, scoring, diffs, proposal screen, confirmation, atomic apply, undo, log, stale-proposal handling, integration with Phases 9 and 7. *Gate: exhaustive engine tests pass; integration test passes; nothing changes without confirmation.*

**Phase 11: Nightly schedule review.** Rolling-window scheduling, confirmed/unconfirmed logic, cancel/re-schedule on changes, review screen, settings integration. *Gate: decision-logic tests pass; confirmed day produces no reminder.*

**Phase 12: Insights and analytics.** Formulas, charts, streak, history with filters, empty states. *Gate: figures verified against seeded test data.*

**Phase 13: Polish.** Animations, accessibility, responsive checks, text-scale checks, error handling and global error capture, performance pass, icons and splash, remove dead code (the PDF is dark-only, so no light theme work is needed). Compare every screen to the PDF one final time. *Gate: no overflows; analyzer clean; visual fidelity pass.*

**Phase 14: Testing, builds, and handover.** Full test run with coverage, integration tests, debug builds, finalise docs, README, `TEST_REPORT.md`, manual device checklist, final report. *Gate: Section 18 checklist fully satisfied or exceptions explicitly listed.*

---

## 20. HOW TO REPORT PROGRESS

After each phase, post a short report: what was built (files/features), commands run and their results (analyze/test/build), deviations from the PDF with reasons, and the next phase. Keep it concise. Do not paste whole files into chat; the files are in the workspace.

**BEGIN NOW with Phase 0. Read the PDF first, then proceed phase by phase until FlowDay is a complete, working, tested Flutter application.**
