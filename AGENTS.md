# FlowDay — Standing Rules for the Coding Agent

Put this file in the project root (and in your Antigravity rules location if your version has one, e.g. `.agent/rules/`). It is read before every task.

## Project
FlowDay: offline-first Flutter daily planner (Android first). Stack: Flutter, Riverpod, go_router, sqflite, shared_preferences, flutter_local_notifications, fl_chart.

## Sources of truth (read before coding)
1. `design/flowday_ux.pdf` and `design/screens/*.png` — UI source of truth (24 screens). Match them. Do not redesign.
1a. `docs/DESIGN_DECISIONS.md` — resolved conflicts between UI and requirements, screen-to-route-to-phase map. Wins over SYSTEM_DESIGN.md if they differ. OPEN items must be asked, not guessed.
2. `docs/UI_SPEC.md` — extracted spec from the images.
3. `docs/SYSTEM_DESIGN.md` — architecture, schema, engine, notification design.
4. `docs/BUILD_PHASES.md` — current phase and its exit checks.
5. `FLOWDAY.md` — product requirements, if present.

If sources conflict, stop and ask. Do not guess.

## Working style (the user is a beginner)
- Work on ONE phase at a time. Never start the next phase without approval.
- Before coding: state the plan and the files you will create/modify.
- After coding: run `flutter analyze` and `flutter test`, fix failures, then summarise in plain language and list manual test steps.
- Give exact commands and say where to run them.
- On errors: read the whole error, find the root cause. Do not reinstall tools, delete the project, or delete unrelated files.
- Do not claim something works unless you ran it. Say what you could not verify (e.g. real-device notification behaviour).

## Hard rules
- Offline only. No Firebase, Supabase, analytics, backend, or cloud auth.
- No fake/hardcoded data in finished features. No non-functional buttons.
- Never silently change a user's schedule. Every reschedule is: proposal -> compare -> confirm -> transactional apply -> undo available.
- Fixed tasks, breaks, and completed tasks are never moved by the engine.
- Tasks never overlap and never cross midnight.
- Nightly review reminder: default 21:30, user-editable, never hardcoded; scheduled only while tomorrow is unconfirmed, cancelled on confirm, restored if tomorrow is edited.
- Swipe right = complete, swipe left = incomplete. Swipe must never delete.
- Scheduling engine is pure Dart (no Flutter, no DB, injected Clock) and has unit tests.
- No logic in widgets. Data access only through repositories.
- Add packages with `flutter pub add`, check the build, justify each one.
- Preserve existing working code. Make small, reviewable changes.

## Code conventions
- Feature-first folders: `features/<name>/{data,domain,presentation}`.
- Colors, text styles, spacing, radii only from the theme tokens — no inline magic values.
- Use `const` constructors, null-safety, small widgets, descriptive names.
- All user-facing errors are friendly messages; no uncaught exceptions on DB or permission failures.

## Definition of done (every phase)
`flutter analyze` clean, tests for the new logic pass, app runs on an emulator, exit checks from BUILD_PHASES.md met, manual test steps given to the user.
