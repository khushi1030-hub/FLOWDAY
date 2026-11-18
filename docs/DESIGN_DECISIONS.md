# FlowDay — Design Decisions & Screen Map

Source: `design/flowday_ux.pdf` (24 pages) and `design/screens/01_...24_*.png`.
This file resolves conflicts between the UI, `FLOWDAY.md` and `SYSTEM_DESIGN.md`. **If a decision here is marked OPEN, the agent must ask the user in Phase 0.**

---

## 1. Decisions

| # | Topic | Decision | Status |
|---|---|---|---|
| D1 | Breaks in proposals | Breaks are **never shortened automatically**. A proposal may offer a shorter break only as a clearly labelled option the user must choose. Page 15 ("Break shortened to 15m") is shown as a *preview of an option*, not an automatic result. | Decided |
| D2 | Changing task durations (p19 "Change task durations") | Allowed for **flexible tasks only**, only inside a proposal the user confirms. Fixed tasks and breaks never change. | Decided |
| D3 | "Keep overlap" (p10, p19) | Allowed. Tasks are stored, flagged `has_conflict`, shown with a warning style, and Home/Schedule show an "overlap" badge. Never silent. | Decided |
| D4 | Swipe left (Home says "left to adjust") | Left swipe = mark **incomplete** and open the Unfinished/Adjust screen (p14). Right swipe = complete. Never deletes. | Decided |
| D5 | Account (p24 email, Log out) | Offline app: **remove email and Log out**. Replace "Log out" with "Reset all data" (double confirmation). Name and avatar stored locally. | Decided |
| D6 | Nightly reminder default | Default nightly review time is **09:30 PM (21:30)**. Always read from preferences and editable. | Decided |
| D7 | Light theme (p24 toggle) | **Dark mode only** for v1. Hide the Light/Dark toggle in Settings until light palette is designed. | Decided |
| D8 | Day window | Comes from user's Wake-up (07:00 AM) and Sleeping (11:00 PM) times. "Working hours" (09:00 AM - 06:00 PM) is a separate preference used for Work-category suggestions only. | Decided |
| D9 | Focus "Silence other notifications" (p11) | Android cannot mute other apps without Do Not Disturb access. Implement as: silence FlowDay's own non-alarm notifications during the session; optional deep link to DND settings. | Decided |
| D10 | Task History entry point | Opened from a **history icon at the top-right of Insights**, and linked from Settings. | Decided |
| D11 | Recurrence (p9 Repeat) | Never / Daily / Weekly / Custom (pick weekdays). Generates a rolling 14-day window regenerated on app launch, indexed by series_id. Editing asks "this task / all future". | Decided |
| D12 | Daily summary notification (p17) | Default = nightly_review_min minus 60 min (**08:30 PM**), with its own toggle and editable time. | Decided |
| D13 | Streak | Day counts if completion rate >= 1 task completed AND >= 50% of planned tasks. Computed from `task_events`. | Decided |
| D14 | Avatar | Local image picker (image_picker). Falls back to initials. | Decided |
| D15 | Empty fields & Sample data | The name field starts EMPTY with placeholder ("Your name"), is required, and is never pre-filled. The name "Khushi", the avatar photo, the email and all other sample mockup content must NOT appear as hardcoded data in the app. | Decided |

---

## 2. Schema changes vs SYSTEM_DESIGN.md

- `tasks`: add `alarm_enabled`, `notes`, `icon_key`, `recurrence`, `recurrence_rule`, `series_id`, `has_conflict`.
- Statuses: add `postponed` and `skipped`. "Missed/Overdue" is **derived** (pending + past end).
- `categories` seed: Study, Work, Health, Personal, Social, Break.
- `task_events.event_type`: add `postponed`, `skipped`.
- Preferences (shared_preferences): `user_name`, `avatar_path`, `wake_min`, `sleep_min`, `work_start_min`, `work_end_min`, `default_break_min`, `notification_sound`, `alarm_vibrate`, `task_alarms_enabled`, `nightly_review_enabled`, `nightly_review_min`, `daily_summary_enabled`, `focus_ambience` (rain/lofi/silence), `focus_silence_enabled`, `theme_mode`.
- Bundled audio assets: 4 notification sounds (Soft Chime, Morning Breeze, Crystal Bell, Lo-fi Piano), rain loop, lo-fi loop.
- Derived metrics (no stored numbers): streak, progress delta vs yesterday/last week, "Deep focus" minutes (sum of focus sessions linked to the task), most productive hours (completed_at histogram), average task delay (completed_at - end), protected-breaks ratio (breaks not shortened/moved), weekly productivity %.

---

## 3. Screen map (PDF page -> file -> route -> phase)

| PDF | File | Route | Phase |
|---|---|---|---|
| 1 | `01_splash.png` | `/splash` | 1 (router) / 3 |
| 2 | `02_onboarding_plan_your_day.png` | `/onboarding/1` | 3 |
| 3 | `03_onboarding_stay_on_track.png` | `/onboarding/2` | 3 |
| 4 | `04_onboarding_plans_change.png` | `/onboarding/3` | 3 |
| 5 | `05_personalize.png` | `/onboarding/personalize` | 3 |
| 6 | `06_permissions_notifications.png` | `/onboarding/permissions` | 3 (request wired in 7) |
| 7 | `07_home.png` | `/home` | 5 |
| 8 | `08_schedule_today.png` | `/schedule` | 6 |
| 9 | `09_new_task.png` | `/task/new` | 4 |
| 10 | `10_edit_task_conflict.png` | `/task/:id/edit` | 4 (conflict options use engine in 9) |
| 11 | `11_focus.png` | `/focus/:taskId` | 10 |
| 12 | `12_alarm_times_up.png` | `/alarm/:taskId` | 7 |
| 13 | `13_task_completed.png` | `/completed/:taskId` | 4 / 12 (stats) |
| 14 | `14_unfinished_adjust.png` | `/delay/:taskId` | 8 |
| 15 | `15_extra_time_sheet.png` | bottom sheet on `/delay/:taskId` | 8 |
| 16 | `16_smart_rescheduling.png` | `/reschedule` | 9 |
| 17 | `17_lockscreen_summary_notification.png` | daily summary notification | 7 / 12 |
| 18 | `18_nightly_review.png` | `/review/:dateKey` | 11 |
| 19 | `19_new_plan_conflict.png` | `/reschedule` (new-plan variant) | 9 |
| 20 | `20_schedule_confirmed.png` | `/review/:dateKey/done` | 11 |
| 21 | `21_calendar.png` | `/schedule/calendar` | 6 |
| 22 | `22_task_history.png` | `/history` | 12 |
| 23 | `23_insights.png` | `/insights` | 12 |
| 24 | `24_settings.png` | `/settings` | 13 |

## 4. Screens required but NOT designed (agent proposes, user approves)

Notification bell screen, Profile, Preferences, Help, About, Privacy Policy, Schedule "Tomorrow" tab, Calendar "Week" view, Insights "Day" and "Month", Task detail view, time picker / category picker / reminder picker / custom repeat sheets, Focus running + paused + summary states, empty states, error states, "Reset all data" confirmation, recurrence "this/all future" dialog.

Rule: reuse existing components and tokens; no new visual style.
