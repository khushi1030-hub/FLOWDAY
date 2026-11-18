# FlowDay — UI Specification (UI_SPEC.md)

> **Source of truth:** `design/flowday_ux.pdf` (24 screens) and `design/screens/*.png` (01 to 24).  
> **Rule:** Match the designs with pixel-level fidelity. Do not redesign. Colors, text styles, spacing, radii, and layouts are extracted directly from the verified design images.

---

## 1. Design Tokens (Flutter ThemeData Ready)

### 1.1 Color Palette

```dart
class FlowColors {
  // Backgrounds & Surface
  static const Color background = Color(0xFF0B0B14);      // Pure dark background
  static const Color surface = Color(0xFF161426);         // Default card surface
  static const Color surfaceElevated = Color(0xFF1D1B32); // Highlighted / active card surface
  static const Color surfaceDark = Color(0xFF12101F);     // Recessed containers / inputs
  static const Color surfaceBorder = Color(0xFF262244);   // Subtle 1px borders
  static const Color surfaceBorderSubtle = Color(0xFF1D1A33);

  // Brand / Primary Violet
  static const Color primary = Color(0xFF7C6EF6);         // Main CTA / active purple
  static const Color primaryLight = Color(0xFF9B8AFB);    // Lavender accent text & tags
  static const Color primaryDark = Color(0xFF5E4EE6);     // Pressed state
  static const Color primaryContainer = Color(0xFF221F45);// Tinted card backgrounds
  static const Color primaryGlow = Color(0x667C6EF6);     // Glow shadow (40% opacity)

  // Pure Neutrals
  static const Color textPrimary = Color(0xFFFFFFFF);     // Headings, primary titles
  static const Color textSecondary = Color(0xFF9CA3AF);   // Subtitles, metadata, timestamps
  static const Color textMuted = Color(0xFF6B7280);       // Captions, inactive icons
  static const Color textDisabled = Color(0xFF4B5563);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);         // Mint green (Completed, On track)
  static const Color successContainer = Color(0xFF0F2B20);
  static const Color successBorder = Color(0xFF1D4A38);

  static const Color warning = Color(0xFFF59E0B);         // Amber / Orange (Medium priority, Streak, Protected)
  static const Color warningContainer = Color(0xFF2E2015);
  static const Color warningBorder = Color(0xFF4D3418);

  static const Color error = Color(0xFFEF4444);           // Coral / Red (High priority, Overdue, Conflict, Delete)
  static const Color errorContainer = Color(0xFF2D151B);
  static const Color errorBorder = Color(0xFF4D1F28);

  static const Color info = Color(0xFF60A5FA);            // Blue / Teal (Low priority, Shifted, Information)
  static const Color infoContainer = Color(0xFF152238);

  // Task Category Accent Colors (ARGB)
  static const Color catStudy = Color(0xFF818CF8);        // Lavender Blue
  static const Color catWork = Color(0xFF34D399);         // Mint
  static const Color catHealth = Color(0xFFF472B6);       // Soft Pink / Green
  static const Color catPersonal = Color(0xFFFBBF24);     // Warm Amber
  static const Color catSocial = Color(0xFFFB923C);       // Warm Coral
  static const Color catBreak = Color(0xFFD97706);        // Ochre / Coffee Brown
}
```

### 1.2 Typography (Geometric Sans / Inter / Plus Jakarta Sans)

* Font Family: `Inter` or `Plus Jakarta Sans` (fallback system sans-serif).

| Style Token | Size | Weight | Line Height | Color | Usage |
|---|---|---|---|---|---|
| `displayLarge` | 32sp | 700 (Bold) | 38sp | `textPrimary` | Onboarding hero headlines |
| `displayMedium` | 26sp | 700 (Bold) | 32sp | `textPrimary` | Screen hero headers (Personalize, Alarm) |
| `headlineLarge` | 22sp | 700 (Bold) | 28sp | `textPrimary` | Home greeting, Schedule date header |
| `headlineMedium` | 18sp | 700 (Bold) | 24sp | `textPrimary` | Task titles in cards, Section headers |
| `titleMedium` | 15sp | 600 (SemiBold) | 20sp | `textPrimary` | Card titles, Input values |
| `bodyLarge` | 14sp | 400 (Regular) | 20sp | `textSecondary` | Subtitles, descriptive paragraphs |
| `bodyMedium` | 13sp | 500 (Medium) | 18sp | `textSecondary` | Task metadata, list item details |
| `labelLarge` | 15sp | 700 (Bold) | 18sp | `textPrimary` | Primary button text |
| `labelMedium` | 12sp | 600 (SemiBold) | 16sp | `textSecondary` | Chip labels, stat tile titles |
| `labelSmall` | 10sp | 600 (SemiBold) | 14sp | `textMuted` | Uppercase section badges, tracking 1.2 |

### 1.3 Spacing Scale
* `space4`: 4dp (tight icon/label spacing)
* `space8`: 8dp (chip padding, inner tile gaps)
* `space12`: 12dp (card inner padding, list item gaps)
* `space16`: 16dp (standard screen horizontal padding, card content padding)
* `space20`: 20dp (section separation)
* `space24`: 24dp (major block spacing)
* `space32`: 32dp (hero illustration margins)

### 1.4 Corner Radii
* `radiusPill`: 999dp (primary buttons, filter chips, time badges)
* `radiusCard`: 20dp–22dp (Home progress card, Now card, Schedule cards)
* `radiusSheet`: 24dp (top corners of bottom sheets)
* `radiusSquircle`: 16dp (stat tiles, category icon containers, inputs)
* `radiusBadge`: 8dp (priority chips, status tags)

### 1.5 Elevation & Glows
* `cardBorder`: `Border.all(color: FlowColors.surfaceBorder, width: 1.0)`
* `primaryButtonGlow`: `BoxShadow(color: Color(0x667C6EF6), blurRadius: 20, offset: Offset(0, 8))`
* `conflictCardGlow`: `BoxShadow(color: Color(0x33EF4444), blurRadius: 16, offset: Offset(0, 6))`
* `nowCardGlow`: `BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24, offset: Offset(0, 10))`

---

## 2. Shared Components Inventory

| Component Name | Visual Description & Key Specs | Reused on Screens |
|---|---|---|
| **PrimaryButton** | Full-width pill (`h: 56dp`, radius `28dp`), gradient/lavender `#7C6EF6` or white `#FFFFFF`, bold 16sp label with optional icon/arrow. | 02, 03, 04, 05, 06, 09, 10, 11, 13, 14, 15, 16, 18, 19, 20 |
| **SecondaryButton** | Dark card pill (`#1A1828`, border `#2A2640`, radius `28dp`, text `#FFFFFF`) or outline pill. | 09, 10, 15, 18, 19 |
| **PillChip** | Small rounded pill (`h: 28dp`, radius `14dp`), variants: Category, Priority (Low/Med/High), Status (Pending/Done/Overdue/Shifted). | 02, 04, 07, 08, 09, 10, 11, 13, 15, 16, 18, 19, 21, 22 |
| **SegmentedControl** | Dark pill container (`#161424`, radius `16dp`, p4) holding selectable pill buttons with white active background. | 05, 08, 21, 22, 23 |
| **StatTile** | Recessed dark squircle (`#1C1A2F`, radius `14dp`, p10–12) with top label in muted 10sp and bold value in 16–18sp white. | 07, 13, 18, 20, 21, 23 |
| **ProgressRing** | Circular arc indicator with dark background ring and animated lavender/mint gradient arc, center text. | 07, 11, 13, 23 |
| **TimelineRow** | Left time column (11sp `#9CA3AF`), vertical connecting line with node dots (green/purple/grey/orange), and right task card. | 07, 08, 16, 18, 20 |
| **TaskCard** | Rounded surface card (`#161426`, border 1px `#262142`, radius `16dp`) with icon squircle, title, time range, chips, right action/status. | 07, 08, 09, 10, 13, 14, 18, 21, 22 |
| **ToggleRow** | Card row with leading icon squircle, title, subtitle, and right Flutter `Switch.adaptive` (active track `#7C6EF6`). | 05, 06, 09, 11, 24 |
| **ModalBottomSheetContainer** | Bottom sheet with top rounded corners (`24dp`), centered drag handle (`36x4dp`, `#4B5563`), header with close `✕` button. | 15, and all picker sheets |
| **AppBottomNavBar** | Bottom floating/docked bar (`#0B0B14`, top border 1px `#1D1A30`) with 4 items: Home, Schedule, Insights, Settings. Active item has purple dot indicator below. | 07, 08, 21, 23, 24 |

---

## 3. Screen-by-Screen Specifications (All 24 Screens)

```
Screen Map Index:
01. Splash (/splash)
02. Onboarding 1 — Plan Your Day (/onboarding/1)
03. Onboarding 2 — Stay on Track (/onboarding/2)
04. Onboarding 3 — Plans Change (/onboarding/3)
05. Personalize Your Flow (/onboarding/personalize)
06. Notification Permissions (/onboarding/permissions)
07. Home Dashboard (/home)
08. Daily Schedule — Today (/schedule)
09. New Task (/task/new)
10. Edit Task — Conflict Resolution (/task/:id/edit)
11. Focus Mode (/focus/:taskId)
12. Alarm — Time's Up! (/alarm/:taskId)
13. Task Completed Celebration (/completed/:taskId)
14. Unfinished / Adjust Schedule (/delay/:taskId)
15. Extra Time Bottom Sheet (modal on /delay/:taskId)
16. Smart Rescheduling (/reschedule)
17. Lockscreen Summary Notification (system tray)
18. Nightly Review — Tomorrow's Plan (/review/:dateKey)
19. New Plan Conflict Resolution (/reschedule/new-plan)
20. Schedule Confirmed (/review/:dateKey/done)
21. Calendar View (/schedule/calendar)
22. Task History (/history)
23. Insights & Analytics (/insights)
24. Settings (/settings)
```

---

### Screen 01: Splash Screen
* **Source Image:** `design/screens/01_splash.png`
* **Route:** `/splash` (Phase 1 / Phase 3)
* **Purpose:** Branded launch entrance while initializing SQLite database, loading shared preferences, and verifying onboarding state.
* **Layout (Top to Bottom):**
  1. Full-screen background: `#0B0B14` with subtle square grid pattern (`#171626` lines) and central soft radial purple glow (`#5E43F3` at 15% opacity).
  2. Centered Logo Squircle: 96x96dp container (`#181528`, border 1px `#2E284A`, corner radius 28dp). Inside: open circular clock stroke (3.5dp `#9B8AFB`) with a checkmark in the center and dot at 12 o'clock.
  3. App Name: Text row centered below logo: "Flow" (36sp, w700, `#FFFFFF`) + "Day" (36sp, w700, `#9B8AFB`).
  4. Subtitle: "Make time for what matters." (14sp, w400, `#8E8CA3`, 12dp below title).
  5. Loading Indicator: 3 small animated pulsing dots (`#453D68` to `#9B8AFB`, 40dp below subtitle).
  6. Bottom Tagline: "PLAN SMART · STAY FLEXIBLE · FLOW BETTER" (11sp, w600, letterSpacing 2.0, `#44415C`, pinned 32dp from bottom).
* **Navigation:** Auto-redirects after initialization (~1.2s):
  * If `onboarding_done == false` -> `/onboarding/1`
  * If `onboarding_done == true` -> `/home`
* **Interactions:** None (passive splash).
* **Data Sources:** Reads `shared_preferences` key `onboarding_done`.
* **States:** Normal loading (shown). Error (proposed): If DB init fails, display a gentle full-screen error card with "Retry" button.
* **Responsive Notes:** Center column vertically centered; bottom tagline pinned to safe area bottom.

---

### Screen 02: Onboarding 1 — Plan Your Day
* **Source Image:** `design/screens/02_onboarding_plan_your_day.png`
* **Route:** `/onboarding/1` (Phase 3)
* **Purpose:** Educate user on building a daily timeline with tasks and breaks.
* **Layout:**
  1. Top Bar: Left mini logo (20dp) + "FlowDay" (15sp w700 white), Right "Skip" text button (`#7D88B5`, 14sp w500).
  2. Hero Mockup Card (`#14131E`, border 1px `#26233B`, radius 24dp):
     * Header: "TUESDAY" (10sp `#6B7280`), "May 14" (22sp w700 white), calendar button (`#221F36`).
     * Date strip: "M 13, T 14, W 15, T 16, F 17".
     * Floating Task 1: Lavender squircle `</>`, "Learn Flutter" (13sp w600 white), "09:00 - 10:00 AM" (10sp `#9CA3AF`). Card `#201D38` with subtle glow.
     * Floating Task 2: Green squircle dumbbell, "Workout", "06:00 - 07:00 PM". Card `#132B23`.
     * Floating Task 3: Coral squircle coffee, "Coffee break", "11:00 - 11:30 AM". Card `#2E181B`.
     * Top-right star badge: `#F59E0B` squircle.
  3. Pager Indicator: Pill (24x6dp `#FFFFFF`) + 2 dots (6x6dp `#2B283E`).
  4. Headline: "Plan your day" (32sp w700 white), "your way." (32sp w700 `#9B8AFB`).
  5. Body: "Build a daily schedule in minutes. Organize every task, break and plan into a calm, clear timeline that fits how you actually live." (14sp w400 `#9CA3AF`).
  6. Action Button: Full-width white pill button (`#FFFFFF`, h56dp, radius 28dp), label "Next ->" (16sp w700 `#0B0B14`).
* **Navigation:** Tap "Next ->" or swipe left -> `/onboarding/2`. Tap "Skip" -> `/onboarding/personalize`.
* **Interactions:** Horizontal swipe gesture between onboarding slides.
* **Data Sources:** 100% static presentation.
* **Responsive Notes:** Flexible spacer between text and bottom button for smaller screens (320dp width).

---

### Screen 03: Onboarding 2 — Stay on Track
* **Source Image:** `design/screens/03_onboarding_stay_on_track.png`
* **Route:** `/onboarding/2` (Phase 3)
* **Purpose:** Introduce the automated end-of-task alerts and real-time adherence checking.
* **Layout:**
  1. Top Bar: Left mini logo + "FlowDay", Right "Skip".
  2. Hero Graphic:
     * Floating notification banner (`#191726`, border `#2D2845`): Bell on `#7C6EF6` squircle, "Time's up · Learn Flutter" (13sp w600 white), "now" (11sp `#71717A`), "Your 60-min session is done. Did you finish?" (12sp `#A1A1AA`).
     * Center Clock Graphic: Concentric purple sound wave circles, clock face `#12111E`, purple arc ring (`#8B7BF7`), clock hands at 10:00 and 12:00.
     * Floating progress card (`#181724`): "Today" (11sp `#71717A`), "3 / 5" (12sp w700 `#34D399`), mint-to-lavender progress bar, "60% on track" (12sp w700 white).
  3. Pager Indicator: Dot + Active Pill (24x6dp) + Dot.
  4. Headline: "Stay on track," (32sp w700 white), "effortlessly." (32sp w700 `#9B8AFB`).
  5. Body: "FlowDay gently lets you know the moment a task's time is up — so you can wrap up, check in, and move on without watching the clock."
  6. Action Button: White pill button "Next ->" (h56dp, radius 28dp).
* **Navigation:** Tap "Next ->" or swipe left -> `/onboarding/3`. Swipe right -> `/onboarding/1`. Tap "Skip" -> `/onboarding/personalize`.
* **Data Sources:** Static illustration.

---

### Screen 04: Onboarding 3 — Plans Change, Schedule Adapts
* **Source Image:** `design/screens/04_onboarding_plans_change.png`
* **Route:** `/onboarding/3` (Phase 3)
* **Purpose:** Explain smart rescheduling that protects breaks and fixed tasks when plans run late.
* **Layout:**
  1. Top Bar: Left mini logo + "FlowDay", Right "Skip".
  2. Hero Graphic:
     * Card `#151322` with "Today" header and chip "🪄 Smart reschedule" (`#262046` background, `#9B8AFB` text).
     * Slots: 09:00 "Morning run" with green checkmark; 10:00 (dotted empty slot); 11:00 "Lunch 🔒" (locked fixed task); curved dotted arrow skipping Lunch to 01:00 "Practice..."; floating card "+ 🎬 Movie with friends 06:00 - 09:00 PM" (`#2B1A1E`).
  3. Pager Indicator: Dot + Dot + Active Pill (24x6dp).
  4. Headline: "Plans change." (32sp w700 white), "Your schedule\nadapts." (32sp w700 `#9B8AFB`).
  5. Body: "Ran over? Something new came up? FlowDay suggests smart shifts that protect your priorities and breaks — and never changes anything without asking."
  6. Action Button: Lavender pill button (`#7C6EF6`, glow shadow `0px 10px 25px rgba(124, 110, 246, 0.4)`), text "Get Started ->" (16sp w700 white).
* **Navigation:** Tap "Get Started ->" -> `/onboarding/personalize`. Swipe right -> `/onboarding/2`.

---

### Screen 05: Personalize Your Flow
* **Source Image:** `design/screens/05_personalize.png`
* **Route:** `/onboarding/personalize` (Phase 3)
* **Purpose:** Collect initial personal setup (name, sleep rhythm, nightly reminder time, audio sound, break length).
* **Layout:**
  1. Top Bar: Circular back button (`#1D1B2B`, 40dp, chevron-left), progress line (50% purple `#7C6EF6`, 50% dark), step counter "1 of 2" (12sp `#71717A`).
  2. Header: "Let's personalize\nyour flow ✨" (26sp w700 white), Subtitle: "A few details help FlowDay plan around your real rhythm. You can change these anytime." (13sp `#9CA3AF`).
  3. Section "YOUR NAME" (11sp w600 tracking 1.2 `#71717A`):
     * Input box (`#161424`, border `#2A2640`, radius 14dp, h52dp): Person outline icon (`#8B7BF7`), text input starts EMPTY with placeholder "Your name" (required field, never pre-filled; sample names like "Khushi" must not be hardcoded in the app), green check circle (`#10B981`) appears when valid text is entered.
  4. Section "DAILY RHYTHM":
     * 2 Columns (`#161424`, radius 16dp, p16):
       * Left: Sun icon in amber squircle, "Wake-up time" (11sp `#71717A`), bold "07:00 AM" (18sp w700 white). Tapping opens TimePicker.
       * Right: Moon icon in purple squircle, "Sleeping time" (11sp `#71717A`), bold "11:00 PM" (18sp w700 white). Tapping opens TimePicker.
  5. Section "NIGHTLY PLANNING REMINDER":
     * Card (`#161424`, radius 16dp, p16): Bell icon, bold "09:30 PM", Subtitle: "We'll ask you to review tomorrow", chevron right `>`. Opens TimePicker.
  6. Section "NOTIFICATION SOUND":
     * Card container (`#161424`, radius 16dp): 4 sound items with preview play buttons and radio selections:
       * "Soft Chime" (Selected: purple play button `#7C6EF6`, radio button selected with purple dot)
       * "Morning Breeze" (grey play button, unselected radio)
       * "Crystal Bell" (grey play button, unselected radio)
       * "Lo-fi Piano" (grey play button, unselected radio)
  7. Section "DEFAULT BREAK" (right header "between tasks" 11sp `#71717A`):
     * Segmented row of 5 pills: "5m", "10m", "15m" (selected: `#FFFFFF` pill, bold dark text), "20m", "30m" (`#161424` pills).
  8. Bottom Button: Lavender pill button "Continue" (`#7C6EF6`, h56dp, radius 28dp, white text).
* **Navigation:** Tap "Continue" -> saves values to `shared_preferences` and navigates to `/onboarding/permissions`. Tap back -> `/onboarding/3`.
* **Interactions:** Tap name input to type; tap Wake/Sleep/Reminder to open TimePicker modal; tap Play to audition audio; tap break pill to select.
* **Data Sources:** Writes `user_name`, `wake_min`, `sleep_min`, `nightly_review_min`, `notification_sound`, `default_break_min` to `shared_preferences`.

---

### Screen 06: Notification Permissions
* **Source Image:** `design/screens/06_permissions_notifications.png`
* **Route:** `/onboarding/permissions` (Phase 3 / Phase 7)
* **Purpose:** Educate user why notifications are required before requesting system permissions.
* **Layout:**
  1. Top Bar: Circular back button, 100% purple progress line, step counter "2 of 2".
  2. Hero Illustration: Squircle with bell icon + coral alert dot, sound wave rings, floating chips: "▶ DSA starts in 5 min" and "🌙 Review tomorrow?".
  3. Header: "Never miss an\nimportant moment." (26sp w700 white). Subtitle: "FlowDay uses notifications and alarms to keep your day gently on track — only when it matters."
  4. 3 Rationale Cards (`#161424`, radius 16dp, p14, border 1px `#262244`):
     * Clock icon in `#2E2A54` squircle: "Task reminders" (14sp w700 white), Subtitle: "A heads-up before each task begins".
     * Hourglass in `#3B2227` squircle: "End-of-task alarms", Subtitle: "Check in when your time is up — even when locked".
     * Moon in `#332B1E` squircle: "Nightly schedule review", Subtitle: "A calm nudge to plan tomorrow at 09:30 PM".
  5. Privacy Note: Shield icon "No spam. You control every alert in Settings." (11sp `#71717A`).
  6. Action Buttons:
     * Primary: Lavender pill "🔔 Enable Notifications" (`#7C6EF6`, h56dp, white text).
     * Secondary: "Skip for now" text button (14sp w600 `#71717A`).
* **Navigation:** Both "Enable Notifications" and "Skip for now" set `onboarding_done = true` in preferences and navigate to `/home`. "Enable" invokes `permission_handler` first. Tap back -> `/onboarding/personalize`.

---

### Screen 07: Home Dashboard
* **Source Image:** `design/screens/07_home.png`
* **Route:** `/home` (Phase 5, ShellRoute)
* **Purpose:** Daily command center showing current status, NOW task card, and quick swipeable schedule.
* **Layout:**
  1. Top Bar:
     * Left: Circular avatar (42dp, border `#2D2845`, falls back to initials).
     * Center: Subtitle "Tuesday, May 14" (11sp `#9CA3AF`), Title "Good Morning, {user_name}! ☀️" (17sp w700 white, dynamically read from preferences).
     * Right: Bell button (`#1D1B2B`, 40dp) with red notification badge dot.
  2. Progress Card (`#161426`, gradient top-left `#1D1735`, border `#262142`, radius 22dp, p18):
     * Left: Circular progress ring (80dp, stroke 8dp `#8B7BF7`, center "38%" 20sp w700 white, "today" 10sp `#9CA3AF`).
     * Right: Status chip "• On track" (mint green `#10B981` in `#0E2C22` pill, radius 10dp).
     * Title: "3 of 8 tasks\ncompleted" (17sp w700 white). Subtitle: "You're flowing nicely — keep it gentle."
     * 3 Stat Tiles inside card (`#1C1A2F`, radius 14dp, p10):
       * "DONE" / "3"
       * "REMAINING" / "5"
       * "FOCUS" / "1h 24m"
  3. "NOW" Card (distinctive white background `#FFFFFF`, radius 22dp, p18, shadow `0px 10px 30px rgba(0,0,0,0.4)`):
     * Top Row: "• NOW" (11sp w700 `#6366F1`), Right: "High" priority chip (`#FEE2E2` background, `#EF4444` text).
     * Title Row: Dark squircle icon (`#181628`, 40dp, `</>` lavender icon), Title "Learn Flutter" (18sp w700 `#0B0B14`), Subtitle: "09:00 - 10:00 AM · 60 min · Study" (12sp `#6B7280`).
     * Progress Row: "24 min in" (11sp w600 `#4B5563`), Right: "36 min left" (11sp w700 `#0B0B14`). Linear progress bar (h6dp, background `#E5E7EB`, fill `#7C6EF6`, radius 3dp).
     * Actions:
       * "Focus mode" (black pill `#0B0B14`, white text, headphones icon, radius 20dp, h42dp). Opens `/focus/:taskId`.
       * "Mark done" (grey pill `#F3F4F6`, dark text `#1F2937`, checkmark icon, radius 20dp, h42dp). Completes task, opens `/completed/:taskId`.
  4. Section "Today's schedule":
     * Header: "Today's schedule" (17sp w700 white), Right: "See all ->" (13sp w600 `#818CF8`, opens `/schedule`).
     * Subheader: Hand-swipe icon "Swipe right to complete · left to adjust" (11sp `#71717A`).
     * Vertical Timeline List:
       * 07:00 (green dot): "Morning run", "07:00 - 07:30 · 30m", green check circle. (Done card `#14181F`, border `#1B2D26`).
       * 08:00 (green dot): "Read 30 pages", "08:00 - 08:30 · 30m", green check circle.
       * 09:00 (purple ring node): "Learn Flutter", "09:00 - 10:00 · 60m", purple chip "In progress". (Card `#1B192E`, border `#3B3363`).
       * 10:00 (hollow circle): "Practice DSA", "10:00 - 11:00 AM · 60m", chips: "High", "Study", right: drag handle + "Upcoming".
       * 11:00 (dashed orange node): "Break", "11:00 - 11:30 AM · 30m", orange chip "Protected" (`#2E1E17` card).
       * 11:30 (hollow circle): "Project Work", "11:30 AM - 12:30 PM · 60m", chips: "Medium", "Work", right: drag handle + "Upcoming".
       * 04:00 (hollow circle): "Call with mentor" + "NEW" purple badge, "04:00 - 04:45 PM · 45m", chips: "Low", "Personal", right: drag handle + "Upcoming".
  5. Floating Action Button (`+`): Lavender squircle (`#7C6EF6`, 56x56dp, radius 18dp, purple glow). Tapping opens `/task/new`.
  6. Bottom Navigation Bar: 4 tabs (Home active with purple dot).
* **Interactions:**
  * Swipe right on any task card -> Marks task `completed`, updates progress ring and tiles immediately.
  * Swipe left on any task card -> Marks `incomplete`, navigates to `/delay/:taskId` (Screen 14).
  * Tap card -> opens `/task/:id/edit`.
  * Tap bell -> opens notifications history sheet.
* **Data Sources:** `tasksForDayProvider(today)`, `user_name` preference, `focus_sessions` sum. Real-time clock ticks update the "Now" card progress bar every minute.
* **States:**
  * Empty state (proposed): Friendly graphic + "No tasks scheduled for today. Tap + to add your first task!"
  * All done state: Progress ring at 100%, "All tasks completed! You're flowing great today 🎉".

---

### Screen 08: Daily Schedule — Today
* **Source Image:** `design/screens/08_schedule_today.png`
* **Route:** `/schedule` (Phase 6, ShellRoute)
* **Purpose:** Comprehensive vertical timeline view of the day with time marker, free-time gaps, and overdue task actions.
* **Layout:**
  1. Top Bar: "May 2024" (11sp `#9CA3AF`), Title "Schedule" (24sp w700 white), Right: Search button + Calendar icon button (`#1D1B2B`, opens `/schedule/calendar`).
  2. Tab Bar: Segmented control (`#161424`, radius 16dp, p4): "Today" (selected: white pill `#FFFFFF`, dark text), "Tomorrow", "Calendar".
  3. Week Day Strip: Sun 12 to Sat 18. "Tue 14" selected (lavender pill card `#7C6EF6`, radius 16dp, white text, indicator dot below). Other days show day letter + date number + completion dot below.
  4. Status Filter Chips:
     * "✓ 2 completed" (green border `#1E3A2F`, text `#10B981`)
     * "⭘ 4 pending" (grey border `#2B283E`, text `#9CA3AF`)
     * "⚠ 1 overdue" (coral border `#421D24`, text `#EF4444`)
  5. Timeline:
     * Time column: 07:00, 08:00, 09:00, 10:00, 11:00, 12:00, 01:00, 02:00.
     * 07:00: "Morning run" 30m ✓ (completed card)
     * 08:00: "Read 30 pages" 30m ✓
     * Overdue card: "⚠ Reply to emails" (`#2B161B` card, border `#4A2027`), Right button: coral pill "Reschedule" -> opens `/reschedule`.
     * Current Time Marker: Pink/coral pill "09:24" with horizontal indicator line cutting across timeline.
     * 09:00: "Learn Flutter" (NOW card - lavender `#7C6EF6` filled card, "NOW" badge, "09:00 - 10:00 · 60m · High", white progress bar).
     * 10:00: "Practice DSA", 10:00 - 11:00 · 60m · Study, "High" chip, "⭘ Pending".
     * 11:00: "Break", 20m · protected, coffee icon (`#2A1D1A` card).
     * 12:00: "Project Work", 11:30 - 12:30 · 60m · Work · Flexible, "Medium" chip, "⭘ Pending".
     * 01:00: "Lunch with Aarav", 12:30 - 01:30 · Fixed appointment, lock icon (`#181A22` card).
     * 02:00: "+ Free · 01:30 - 02:30" (dashed outline slot `#2A2640`). Tapping opens `/task/new` prefilled with start=01:30 PM, end=02:30 PM!
  6. FAB (`+`) and Bottom Nav Bar (Schedule active).
* **Interactions:** Tap day in week strip to switch dates; tap "Tomorrow" tab to view next day; tap "+ Free" to insert task in that gap; tap "Reschedule" on overdue task.
* **Data Sources:** `tasksForDayProvider(selectedDate)`, derived current time line from `clockProvider`.

---

### Screen 09: New Task
* **Source Image:** `design/screens/09_new_task.png`
* **Route:** `/task/new` (Phase 4)
* **Purpose:** Complete form to create a task or break, featuring live preview and instant conflict checking.
* **Layout:**
  1. Top Bar: Left close button (`✕` in `#1D1B2B` circle), Center Title "New task" (17sp w700 white), Right magic wand button (smart auto-slot into first free gap).
  2. PREVIEW Card (`#171528`, border `#2D2848`, radius 16dp, p14):
     * Live updating card: icon in squircle, Title "Call with mentor", "04:00 - 04:45 PM · 45m · Today", chips: "Medium" (amber), "Personal", "↔ Flexible", "⏰ 10m before".
  3. Form Fields:
     * "Task title": Input field (`#161424`, border `#2A2640`, radius 14dp, text "Call with mentor").
     * "Description": Multiline area (`#161424`, text "Discuss portfolio review and internship options.").
     * Date & Time Card (`#161424`, radius 16dp, p14):
       * Date row: Calendar icon, "Date", Right: "Today · Tue, May 14 >" (DatePicker).
       * Start / End row (2 columns): "Start: 04:00 PM" and "End: 04:45 PM" (TimePickers).
       * Duration row: Hourglass icon, "Duration", Stepper with `-`, "45 min", `+`.
     * Conflict Check Text: "✓ No conflicts — this slot is free." in mint green `#10B981`. (If conflict: red text).
     * "Category": Chips for "Study", "Work", "Health", "Personal" (selected: white pill `#FFFFFF`, black text), "Break".
     * "Priority": "• Low" (blue), "• Medium" (selected: amber `#F59E0B`), "• High" (coral `#EF4444`).
     * "Flexible task": Subtitle "FlowDay may suggest moving it if plans change", Switch toggle (ON).
     * Card: "Reminder" ("10 min before >") + divider + "End-of-task alarm" (Switch toggle ON).
     * "Repeat": Chips for "Never" (selected: white pill), "Daily", "Weekly", "Custom".
     * Action link: "📝 Add notes" (reveals notes input).
  4. Bottom Bar: "Cancel" (dark pill `#1A1828`) and "✓ Save Task" (lavender pill `#7C6EF6`).
* **Navigation:** "✓ Save Task" validates inputs (title not empty, end > start, within day window, no midnight crossing), writes to SQLite `tasks` table, calls `NotificationScheduler.resyncAll()`, and pops back to caller with a confirmation toast. "Cancel" pops without saving.
* **Data Sources:** Reads `categories` table. Writes to `tasks`.

---

### Screen 10: Edit Task — Conflict Resolution
* **Source Image:** `design/screens/10_edit_task_conflict.png`
* **Route:** `/task/:id/edit` (Phase 4 / Phase 9)
* **Purpose:** Edit existing task; if duration expansion creates an overlap with later tasks, display inline conflict resolution options.
* **Layout:**
  1. Top Bar: Left circle chevron-back, Title "Edit task", Right trash can button (Delete -> shows confirmation dialog).
  2. Title Field: "Practice DSA" in rounded box with purple icon.
  3. Date & Time Box: "Date: Today - Tue, May 14", "Start: 10:00 AM", "End · edited: 11:30 AM" (highlighted in red/orange box `#3D1F24`), "Duration: 90 min".
  4. Conflict Resolution Card (`#23151B`, border `#4A2027`, radius 18dp, p16):
     * Warning icon, Title "This overlaps with 2 tasks", Subtitle "Nothing changes until you choose. Here's what we suggest:"
     * Mini Timeline Clash:
       * 10:00: "Practice DSA · 90m" (purple filled `#7C6EF6`)
       * 11:00: "Break · 30m" ✕ (coral outline)
       * 11:30: "Project Work · flexible" ✕ (coral outline)
     * Radio Options:
       * Option 1 (Selected): Radio ON, "Shift Project Work to 11:45 AM", badge "BEST", Subtitle: "Keeps a 15-min break. Lunch stays fixed at 12:30."
       * Option 2: Radio OFF, "Keep DSA at 60 min", Subtitle: "Revert the end time to 11:00 AM."
       * Option 3: Radio OFF, "Keep the overlap", Subtitle: "I'll sort it out myself." (Sets `has_conflict = 1`).
  5. Priority, Category, Reminder selectors.
  6. Bottom Buttons: "Cancel" (dark pill) and "Save Changes" (lavender pill).
* **Navigation:** "Save Changes" applies chosen resolution in a single DB transaction. Trash icon prompts "Delete Task? This cannot be undone." -> deletes task and pops to Schedule.

---

### Screen 11: Focus Mode
* **Source Image:** `design/screens/11_focus.png`
* **Route:** `/focus/:taskId` (Phase 10)
* **Purpose:** Dedicated distraction-free session with circular countdown and audio ambience loops.
* **Layout:**
  1. Top Bar: Left downward chevron (collapses to mini player), Center pill badge "• Starts now", Right `...` menu.
  2. Header: Tag "Time to focus! 🎧" in lavender, Title "Learn Flutter" (24sp w700 white), "09:00 AM - 10:00 AM", chips: "Study" and "High priority".
  3. Countdown Circle Timer:
     * Glowing lavender ring (220dp, stroke 8dp `#8B7BF7`, shadow glow).
     * Center text: "ENDS IN" (11sp `#9CA3AF`), bold "60:00" (44sp w800 white), "at 10:00 AM" (12sp `#9CA3AF`).
  4. Card 1 "TODAY'S GOAL" (`#161424`, radius 16dp, p14):
     * Text from task notes: "Finish the widgets chapter and build a small counter app with state management."
  5. Card 2:
     * Toggle row: Crescent moon icon, "Focus mode", Subtitle "Silence other notifications" (D9), Switch toggle (ON).
     * Ambience sound selector (3 pills):
       * "🌧 Rain" (selected: white pill, black text)
       * "🎵 Lo-fi" (dark pill)
       * "🔇 Silence" (dark pill)
  6. Action Button: Large white pill button "▶ Start Task" (h56dp, radius 28dp).
* **Interactions:**
  * Tap "▶ Start Task" -> Starts countdown, changes button to "⏸ Pause" / "⏹ End Session". Keeps screen awake via `wakelock_plus`.
  * Tapping sound pill switches audio playback loop via `just_audio`.
  * Minimize chevron -> collapses to persistent floating mini-bar while navigating the rest of the app.
* **Data Sources:** Writes to `focus_sessions` table (timestamp-based for restart recovery).

---

### Screen 12: Alarm — Time's Up!
* **Source Image:** `design/screens/12_alarm_times_up.png`
* **Route:** `/alarm/:taskId` (Phase 7)
* **Purpose:** Full-screen alarm experience triggered at task end time.
* **Layout:**
  1. Top Bar: Speaker icon button, Vibrate icon button, Right: "FLOWDAY ALARM".
  2. Central Clock Visualization: Concentric purple sound/glow rings, clock face with marks, bold "10:00 \n AM", small purple indicator dot.
  3. Alarm Copy: "Time's up! ⏰", Title "Learn Flutter" (26sp w700 white), Subtitle: "Your Flutter session is complete · 09:00 - 10:00 AM".
  4. Question: "Did you complete your task?" (16sp w600 white).
  5. Slider: Bi-directional pill slider:
     * Slide left: `< Not completed` (coral) -> opens `/delay/:taskId` (Screen 14).
     * Center: Circular white thumb with `<->` icon.
     * Slide right: `Completed >` (mint green) -> marks completed, opens `/completed/:taskId` (Screen 13).
  6. Backup Action Buttons below slider:
     * "⌛ Not completed" (coral outline pill)
     * "✓ Completed" (green outline pill)
  7. Bottom Quick Row: "⏰ Snooze 5m", "+ 10 min" (extends task end by 10m and reschedules alarm), "Dismiss".
* **Navigation:**
  * Completed -> writes `tasks.status = 'completed'`, opens `/completed/:taskId`.
  * Not completed -> opens `/delay/:taskId`.
  * Dismiss -> returns to Home.
* **Audio:** Plays configured `notification_sound` on loop with vibration until user interacts.

---

### Screen 13: Task Completed Celebration
* **Source Image:** `design/screens/13_task_completed.png`
* **Route:** `/completed/:taskId` (Phase 4 / Phase 12)
* **Purpose:** Reward user, show productivity stats, update daily streak, and suggest next action.
* **Layout:**
  1. Top Bar: Close `✕` circular button (top right).
  2. Celebration Graphic: Mint green circle (80dp, `#34D399`) with black checkmark, surrounded by confetti stars and sparkles.
  3. Copy: "Amazing! 🎉" (26sp w700 white), Subtitle "Task completed." (14sp `#9CA3AF`).
  4. Task Summary Card (`#161424`, radius 18dp, p16):
     * Header: `</>` icon, "Learn Flutter", "09:00 - 10:00 AM · Study", green checkmark.
     * 3 Stat Tiles (`#1E1C2F`, radius 12dp, p10):
       * "Duration" / "60m"
       * "Finished" / "On time"
       * "Deep focus" / "52m" (from focus sessions)
  5. "Today's progress" Card (`#161424`, radius 18dp, p16):
     * Header: "Today's progress", Right badge "🔥 3-day streak" (`#36221A` pill, `#F59E0B` text).
     * Stats: "50%" (28sp w700 white), "+ 12%" (green tag), "4 of 8 tasks".
     * Progress bar: Gradient fill purple to mint.
  6. Next Task Preview: "NEXT Practice DSA 10:00 - 11:00 AM".
  7. Buttons:
     * Primary: White pill button "Continue to Next Task ->" (navigates to next task detail or `/focus/:nextTaskId`).
     * Secondary: Text link "Back to Home" (navigates to `/home`).
* **Data Sources:** Computes actual duration from `task_events`, focus time from `focus_sessions`, daily completion % from `tasks`, streak from `task_events` history.

---

### Screen 14: Unfinished / Adjust Schedule
* **Source Image:** `design/screens/14_unfinished_adjust.png`
* **Route:** `/delay/:taskId` (Phase 8)
* **Purpose:** Calm, guilt-free delay triage when a task is not finished or left-swiped.
* **Layout:**
  1. Top Bar: Left circle chevron-back, Right circle close `✕`.
  2. Hero: Glowing coral squircle with hourglass icon.
  3. Header: "No worries!\nLet's adjust your schedule." (24sp w700 white).
  4. Task Status Card (`#161424`, radius 18dp, p16):
     * Top row: `</>` icon, "Learn Flutter", "Study · High priority", Right red badge "Unfinished".
     * Two columns: "ALLOCATED: 09:00 - 10:00 AM" and "CURRENT TIME: 10:00 AM".
     * Sub-question: "How much work is left?"
     * Pill selector: "15m", "30m" (selected: white pill `#FFFFFF`, black text), "45m", "1h+".
  5. Section "CHOOSE WHAT WORKS":
     * Option 1 (Selected): Lavender square with `+`, "Add Extra Time", Subtitle: "Keep going now · see impact on next tasks", right arrow `>`. Opens Screen 15.
     * Option 2: Clock-arrow icon, "Reschedule Later Today", Subtitle: "Free slot found · 02:00 - 02:30 PM", right arrow `>`.
     * Option 3: Crescent moon icon, "Move to Tomorrow", Subtitle: "Wed, May 15 · 09:00 AM (first slot)", right arrow `>`.
  6. Encouragement Card (`#1A1728`, radius 14dp, p12): Heart icon, "One unfinished task doesn't have to ruin your entire day. Progress counts, too."
  7. Bottom Button: White pill button "Continue".
* **Navigation:**
  * Option 1 -> opens Screen 15 (Extra Time Bottom Sheet).
  * Option 2 -> engine slots task into first free gap, applies change, pops to Home.
  * Option 3 -> moves task to tomorrow's date with carried badge, pops to Home.

---

### Screen 15: Extra Time Bottom Sheet
* **Source Image:** `design/screens/15_extra_time_sheet.png`
* **Route:** Modal bottom sheet on `/delay/:taskId` (Phase 8)
* **Purpose:** Select exact extension duration and preview downstream ripple effect on later tasks and breaks.
* **Layout:**
  1. Sheet Header: Centered drag handle, Title "How much more time\ndo you need?", Subtitle `</>` "Learn Flutter · originally ends 10:00 AM", Right close `✕`.
  2. Grid of 6 Duration Tiles (`#161424`, radius 14dp, p12):
     * "10 minutes", "15 minutes", "30 minutes" (selected: white tile `#FFFFFF`, bold black text), "45 minutes", "1 hour", "Custom" (with sliders icon).
  3. Result Card (`#1B182B`, radius 14dp, p12):
     * "NEW END TIME", Struck-through original "10:00", bold "10:30 AM", Right purple badge "+30 min".
  4. Impact List:
     * "Practice DSA": "10:00 AM -> 10:30 AM", blue chip "Shifted"
     * "Break": "30 min", orange chip "Shortened to 15m" (per D1: preview of option)
     * "Project Work": "11:30 AM -> 11:45 AM", coral chip "Overlaps lunch"
     * "Lunch with Aarav": "12:30 PM", lock icon "Fixed"
  5. Warning Text: Magic wand icon "Project Work would overlap your fixed lunch — Smart Rescheduling will offer options."
  6. Buttons: "Cancel" (dark pill) and "Apply Changes" (lavender pill `#7C6EF6`).
* **Navigation:** If no fixed conflicts exist, "Apply Changes" updates the task and shifts flexible tasks in one transaction. If an overlap with a fixed task occurs, it routes to `/reschedule` (Screen 16).

---

### Screen 16: Smart Rescheduling — Proposals Compare
* **Source Image:** `design/screens/16_smart_rescheduling.png`
* **Route:** `/reschedule` (Phase 9)
* **Purpose:** Multi-plan proposal comparison with side-by-side Before & After timeline and transactional application.
* **Layout:**
  1. Top Bar: Left circle back button, Title "Smart Rescheduling", Right magic wand button.
  2. Hero Card (`#1B182B`, radius 18dp, p16):
     * Pill chip: "⌛ +60 min needed" in coral/lavender pill
     * Title: "Your Flutter task needs more time. Let's protect the rest of your day."
     * Subtitle: "Extending it overlaps 2 tasks. Lunch is a fixed appointment and won't move."
  3. Section "Before & after":
     * Legend: "🔒 Fixed", "↕ Flexible", "🛡 Protected"
     * Two comparison columns:
       * "Before": 09:00 Flutter (High) -> 10:00 DSA (Conflict, hatched) -> 11:00 Exercise (Pushed) -> 12:30 Lunch 🔒 -> 01:30 Free
       * "After": 09:00 Flutter (+60m, purple glow) -> 11:00 DSA (Shifted 1h) -> 12:30 Lunch 🔒 -> 01:30 Exercise (01:30 PM)
     * Note: "✓ No conflicts. High-priority DSA keeps a full hour. Day ends 1h later at 06:00 PM."
  4. Section "Choose a plan":
     * Plan A (Selected, purple border): Purple badge "A", Title "Extend Flutter & shift flexible tasks", green badge "RECOMMENDED", Subtitle: "DSA moves to 11:00. Exercise after lunch. Lunch untouched."
     * Plan B: Dark badge "B", Title "Move a lower-priority task later", Subtitle: "Exercise (low) moves to 06:00 PM. Afternoon stays free."
     * Plan C: Dark badge "C", Title "Postpone Flutter until tomorrow", Subtitle: "Today stays as planned. Flutter gets Wed 09:00 AM."
     * Plan D: Dark badge "D", Title "Keep original & skip for now", Subtitle: "Flutter is saved as unfinished — pick it up anytime."
  5. Footer note: Shield icon "Nothing is deleted or moved without your approval."
  6. Action Button: Lavender pill button "Apply Plan A".
* **Navigation:** Tap "Apply Plan A" -> executes atomic transaction in SQLite (`reschedule_batches` and `reschedule_changes`), un-confirms tomorrow if touched, updates notifications, navigates back to Home with SnackBar: "Schedule updated  [Undo]".

---

### Screen 17: Lockscreen & Summary Notifications
* **Source Image:** `design/screens/17_lockscreen_summary_notification.png`
* **Route:** System Tray / Lockscreen (Phase 7 / Phase 12)
* **Purpose:** System notification integration for evening review and daily summary.
* **Layout:**
  1. System Lockscreen Clock: "Tuesday, May 14", large bold "9:30" with crescent moon graphic.
  2. Notification 1 (Nightly Review Prompt):
     * Header: FlowDay icon + "FLOWDAY", "now"
     * Title: "Your tomorrow, your way! 🌙"
     * Subtitle: "Your schedule for tomorrow is ready. Want to make any changes before you sleep?"
     * Summary Card: "Wed, May 15 · 6 tasks · 1 free slot", segmented color bar, "Starts 08:30 AM with Learn Flutter".
     * Action Buttons:
       * "Review Schedule" -> launches app directly to `/review/:tomorrowDateKey`.
       * "Remind Me Later" -> snoozes notification for 30 minutes.
  3. Notification 2 (Daily Summary):
     * Header: Green checkmark icon, "You completed 7 of 8 tasks today 🎉", "8:30 PM". Tapping opens `/history` or `/insights`.
* **Platform Implementation:** Implemented via `flutter_local_notifications` with actions and custom payload strings.

---

### Screen 18: Nightly Review — Tomorrow's Plan
* **Source Image:** `design/screens/18_nightly_review.png.png`
* **Route:** `/review/:dateKey` (Phase 11)
* **Purpose:** Evening ritual to review, tweak, and lock in tomorrow's schedule.
* **Layout:**
  1. Top Bar: Left close `✕` button, Center pill badge "🌙 Nightly review", Right `...` menu.
  2. Header: "Let's plan tomorrow." (24sp w700 white), Subtitle: "Take a moment to make tomorrow work for you."
  3. Tomorrow Summary Card (`#161426`, radius 18dp, p16):
     * Date badge: "WED 15" in white squircle
     * Title: "Wednesday, May 15", Subtitle: "Wake 07:00 AM · Sleep 11:00 PM"
     * 4 Stat tiles: "Tasks: 6", "Planned: 5.5h", "Breaks: 45m", "Free: 2h"
  4. Section "Tomorrow's tasks" (right note: "Tap : to adjust"):
     * Task 1: "Learn Flutter", orange badge "CARRIED OVER", "09:00 - 10:00 AM · 60m · High", three-dots menu `:`
     * Task 2 (Expanded adjustment panel with purple border):
       * "Practice DSA", "10:00 - 11:00 AM · 60m · High", purple badge "!"
       * 4 action buttons (2x2): "⏰ Change time", "⚑ Priority", "↻ Move to Thu", "✏ Edit"
       * Delete button: "🗑 Delete task" (red outline)
     * Break: Coffee icon "Break 11:00 - 11:15 · 15m"
     * Task 3: "Project Work", 11:15 AM - 12:45 PM · 90m · Medium
     * Task 4: "Lunch", 12:45 - 01:45 PM · Fixed 🔒
     * Free time slot: Green leaf icon, "Free time · 2h", "02:00 - 04:00 PM · tap to fill" `+`
     * Task 5: "Exercise", 06:00 - 07:00 PM · 60m · Low
     * Task 6: "Call family", 07:00 - 07:45 PM · 45m · Medium
  5. Bottom Controls:
     * Two secondary buttons: "+ Add Task" and "✏ Edit Schedule"
     * Primary button: Large lavender pill "✓ Confirm Tomorrow's Plan"
* **Navigation:** Tap "✓ Confirm Tomorrow's Plan" -> writes `day_confirmations.confirmed = 1`, cancels pending nightly reminder notification, navigates to `/review/:dateKey/done` (Screen 20).

---

### Screen 19: New Plan Conflict Resolution
* **Source Image:** `design/screens/19_new_plan_conflict.png`
* **Route:** `/reschedule` (new-plan variant) (Phase 9)
* **Purpose:** Resolve clashes when adding a fixed event (e.g. Movie with friends) that overlaps existing flexible tasks.
* **Layout:**
  1. Top Bar: Circle chevron-back, Title "New plan".
  2. Target Plan Card (`#23161A`, border `#482028`, radius 18dp, p16):
     * Coral film icon in squircle, Title "Movie with friends", "Wed, May 15 · 06:00 - 08:00 PM · 2h", Right edit pencil button
     * Chips: "👥 Social", "🔒 Fixed", "⏰ 30m before"
  3. Conflict Warning Card:
     * Triangle warning icon, Title "Your new plan conflicts with 2 scheduled tasks.", Subtitle "Pick a fix below — nothing changes until you confirm."
     * Timeline clash preview:
       * 05 PM
       * 06 PM: "Movie with friends 06:00 - 08:00 PM" (large glowing coral card spanning 2 hours)
       * Overlapping parallel tasks: "Exercise" (hatched) and "Call family" (hatched)
       * 09 PM
  4. Section "Recommendations" (magic wand icon):
     * Option 1 (Selected, purple border): Purple squircle with arrows, Title "Move flexible tasks", green badge "BEST FIT", Subtitle: "Exercise -> 02:00 PM · Call family -> 05:00 PM"
     * Option 2: Clock arrow, Title "Reschedule tasks", Subtitle: "Exercise -> 04:00 PM · Call family after movie, 08:15 PM"
     * Option 3: Shrink/expand icon, Title "Change task durations" (per D2: flexible tasks only), Subtitle: "Exercise 30m at 05:00 · Call 20m at 08:15"
     * Option 4: Calendar arrow, Title "Move to another day", Subtitle: "Exercise & Call family -> Thu, May 16 evening"
  5. Positive feedback note: "✓ Uses your free afternoon. Both tasks keep their full time and no breaks are lost."
  6. Footer note: Shield icon "We never overwrite your schedule silently."
  7. Bottom Bar:
     * Left: "Keep overlap" (dark pill, per D3: stores tasks with `has_conflict = 1`).
     * Right: "Apply & Save" (lavender pill `#7C6EF6`).
* **Navigation:** "Apply & Save" commits changes transactionally and pops to Schedule. "Keep overlap" saves new plan with conflict flags.

---

### Screen 20: Schedule Confirmed
* **Source Image:** `design/screens/20_schedule_confirmed.png`
* **Route:** `/review/:dateKey/done` (Phase 11)
* **Purpose:** Calming confirmation screen verifying tomorrow's schedule is locked in.
* **Layout:**
  1. Hero Illustration: White calendar badge "WED 15" with green checkmark circle badge attached, tiny star sparkle.
  2. Heading: "Tomorrow is all set!" (24sp w700 white), Subtitle: "Wednesday, May 15 · your plan, your pace."
  3. 4 Stat tiles (2x2 grid):
     * Clock icon: "8h 15m", "Total planned"
     * List icon: "7 tasks", "Including 1 new plan"
     * Coffee icon: "45m", "Break time"
     * Leaf icon: "1h", "Free time"
  4. Conflicts Banner (`#102B21`, border `#1D4A3A`, radius 14dp, p12):
     * Green check icon: "0 conflicts", Right text: "2 resolved with your approval"
  5. "Final timeline" Card (`#161424`, radius 18dp, p16):
     * Timeline list with colored indicator dots:
       * 09:00 (purple dot): Learn Flutter (60m)
       * 10:00 (purple dot): Practice DSA (60m)
       * 11:00 (orange dot): Break (15m)
       * 11:15 (mint green dot): Project Work (90m)
       * 12:45 (grey dot): Lunch 🔒 (60m)
       * 02:00 (pink dot): Exercise [MOVED badge] (60m)
       * 05:00 (orange dot): Call family [MOVED badge] (45m)
       * 06:00 (coral dot): Movie with friends [NEW badge] (2h)
  6. Encouraging Note: "🌙 Sleep well, {user_name}. We'll take it from here." (dynamically reads user_name from preferences).
  7. Buttons:
     * Primary: Lavender pill button "✓ Confirm Schedule" -> navigates to `/home`.
     * Secondary: Text link "Make more changes" -> returns to `/review/:dateKey`.

---

### Screen 21: Calendar View
* **Source Image:** `design/screens/21_calendar.png`
* **Route:** `/schedule/calendar` (Phase 6, ShellRoute subview)
* **Purpose:** Monthly grid overview of scheduled tasks, completion dots, monthly metrics, and selected day agenda.
* **Layout:**
  1. Top Bar: Title "Calendar" (24sp w700 white), Right segmented control "Month" (selected: white pill), "Week".
  2. Month Matrix Card (`#161426`, radius 20dp, p16):
     * Header: Left arrow `< `, "May 2024", Right arrow ` >`
     * Weekday header: Sun, Mon, Tue, Wed, Thu, Fri, Sat
     * Grid dates (1 to 31): Multi-colored activity dots below each day.
     * Selected day: "14" highlighted in lavender squircle `#7C6EF6` with glow.
     * Dot Legend: 🟢 Completed, 🟣 Upcoming, 🟠 Rescheduled, 🔴 Missed.
  3. 3 Monthly Total Stat Tiles (`#161424`, radius 14dp, p12):
     * "64" "Completed" (mint green `#10B981`)
     * "9" "Rescheduled" (orange `#F59E0B`)
     * "4" "Missed" (coral `#EF4444`)
  4. Selected Day Section:
     * Header: "Today · Tue, May 14", Right link: "Open day ->" (opens `/schedule` for selected day).
     * Task List Cards:
       * 09:00: `</>` Learn Flutter, purple badge "In progress"
       * 07:00: 🏃 Morning run, green badge "Completed"
       * 10:00: 💻 Practice DSA, blue badge "Upcoming"
       * 08:30: ✉ Reply to emails, orange badge "Rescheduled"
  5. Bottom Navigation Bar (Schedule tab active).
* **Interactions:** Tap any date on the calendar matrix to select it; tap "Open day ->" to navigate to Schedule; tap `<` or `>` to switch months.
* **Data Sources:** Queries SQLite `tasks` grouped by `date_key` for dot counts and monthly sums.

---

### Screen 22: Task History
* **Source Image:** `design/screens/22_task_history.png`
* **Route:** `/history` (Phase 12, accessible from Insights or Settings)
* **Purpose:** Complete historical audit of past tasks with multi-criteria filtering (timeframe, status, category).
* **Layout:**
  1. Top Bar: Left circle chevron-back, Title "Task History", Right search button (search by task name).
  2. Timeframe Filter Dropdown (`#161424`, radius 14dp, p12): Calendar icon, "This week · May 8 - 14", down chevron.
  3. Status Filter Row (scrollable chips):
     * "All 11" (selected: white pill `#FFFFFF`, black text)
     * "Completed 7"
     * "Incomplete 1"
     * "Postponed 2"
     * "Skipped 1"
  4. Category Filter Row (scrollable chips):
     * "All categories" (selected: purple pill `#7C6EF6`)
     * "Study", "Work", "Health", "Personal", "Social", "Break"
  5. Grouped Task List by Day:
     * "TODAY · TUE, MAY 14":
       * "Morning run", 07:00 - 07:30 · 30m · Health, green badge "✓ Completed"
       * "Read 30 pages", 08:00 - 08:30 · 30m · Personal, green badge "✓ Completed"
       * "Reply to emails", 08:30 - 09:00 · 30m · Work, orange badge "↻ Postponed -> 02:00 PM"
       * "Learn Flutter", 09:00 - 10:00 · 60m · Study, coral badge "✕ Incomplete"
     * "MON, MAY 13":
       * "UI study session", 09:00 - 10:30 · 90m · Study, green badge "✓ Completed"
       * "Team stand-up", 11:00 - 11:15 · 15m · Work, green badge "✓ Completed"
       * "Grocery run", 02:00 - 02:45 · 45m · Personal, orange badge "↻ Postponed -> Wed"
       * "Yoga", 06:00 - 06:45 · 45m · Health, green badge "✓ Completed"
     * "SUN, MAY 12":
       * "Weekly planning", 10:00 - 10:30 · 30m · Personal, green badge "✓ Completed"
       * "Practice DSA", 11:00 - 12:00 · 60m · Study, green badge "✓ Completed"
       * "Swimming", 05:00 - 06:00 · 60m · Health, grey badge "⏭ Skipped"
* **Interactions:** Tap chips to filter; tap search to type keywords; tap task card to open task detail view.
* **Data Sources:** Queries SQLite `task_events` and `tasks` tables.

---

### Screen 23: Insights & Analytics
* **Source Image:** `design/screens/23_insights.png`
* **Route:** `/insights` (Phase 12, ShellRoute)
* **Purpose:** Weekly productivity reporting, hourly focus distribution, and positive habit reinforcement.
* **Layout:**
  1. Top Bar: "May 8 - 14", Title "Insights" (24sp w700 white), Right segmented control "Day", "Week" (selected: white pill), "Month".
  2. Productivity Hero Card (`#161426`, radius 22dp, p18):
     * "Weekly productivity", large bold "78%", green tag "↗ +6% vs last week".
     * Right: Circular ring chart with "50% today" in mint green arc.
     * Summary text: "A steady, balanced week. You protected your breaks 9 out of 10 times. 🌿"
  3. 4 Analytic Stat Tiles (2x2 grid):
     * Check icon in green squircle: "31", "Tasks completed"
     * Flower icon in purple squircle: "9–11 AM", "Most productive"
     * Hourglass in amber squircle: "8 min", "Avg. task delay"
     * Clock arrow in orange squircle: "6", "Rescheduled"
  4. Chart 1 "Weekly progress" (Subtitle "Completion %"):
     * Vertical bar chart for Wed, Thu, Fri, Sat, Sun, Mon, Tue (built with `fl_chart`). Tue is highlighted with lavender bar and "50%".
  5. Chart 2 "When you focus best" (Subtitle "Tasks done by hour"):
     * Smooth cubic spline curve in mint green `#10B981` with gradient fill to transparent, peaking at 10 AM (value 8). X-axis: 7a, 8a, 9a, 10a, 11a, 12p, 1p, 2p, 3p, 4p, 5p, 6p.
  6. Encouraging Note (`#0E261D`, border `#1B4234`, radius 14dp, p12):
     * Heart icon, "Saturday was lighter — that's okay. Rest days help you flow better the rest of the week."
  7. Bottom Navigation Bar (Insights tab active).
* **Data Sources:** Pure derived calculations over SQLite `task_events`, `tasks`, and `focus_sessions`. Zero fake/hardcoded numbers.

---

### Screen 24: Settings
* **Source Image:** `design/screens/24_settings.png`
* **Route:** `/settings` (Phase 13, ShellRoute)
* **Purpose:** App configuration, notification preferences, schedule defaults, and data management.
* **Layout:**
  1. Top Bar: Title "Settings" (24sp w700 white).
  2. Profile Header Card (`#161426`, radius 20dp, p16):
     * Circular avatar photo (50dp, editable via local image picker per D14, falls back to initials), Title "{user_name}" (from preferences), Subtitle (per D5: email removed), Badge "🔥 3-day streak", Right edit pencil button (`#2A2640`).
  3. Group "ACCOUNT":
     * "Profile >" (opens edit name/avatar sheet)
     * "Name: {user_name} >"
     * "Preferences >"
  4. Group "NOTIFICATIONS":
     * "Task alarms": Subtitle "Full-screen alarm when time's up", Switch toggle (ON)
     * "Nightly schedule review": Switch toggle (ON)
     * "Reminder time": "09:30 PM >" (opens TimePicker)
     * "Alarm sound": "Soft Chime >" (opens audio selector)
     * "Vibration": Switch toggle (OFF)
  5. Group "SCHEDULE":
     * "Default break": "15 min >" (opens duration selector)
     * "Working hours": "9 AM - 6 PM >" (opens start/end time picker)
     * "Wake-up time": "07:00 AM >"
     * "Sleeping time": "11:00 PM >"
  6. Group "APPEARANCE":
     * (Per D7: Dark mode only in v1. Light/Dark toggle hidden until light palette is designed)
  7. Group "OTHER":
     * "Help >"
     * "About FlowDay >" (shows FlowDay v1.0.0, offline description)
     * "Privacy Policy >" (shows 100% offline local privacy policy)
  8. Danger Action Button:
     * Red text pill card: "[-> Reset all data" (per D5: replaces "Log out", requires double confirmation modal).
  9. Footer: "FlowDay v1.0.0 \n PLAN SMART · STAY FLEXIBLE · FLOW BETTER".
  10. Bottom Navigation Bar (Settings tab active).

---

## 4. Screens Required But Not Designed (Harmonized Specifications)

As specified in `docs/DESIGN_DECISIONS.md` section 4, the following required screens and sheets must reuse the exact same tokens and visual components:

1. **Notification Bell Screen / Tray (`/notifications`):**
   * Top bar with back button and "Notifications".
   * Filter chips: "All", "Reminders", "Alarms", "Reviews".
   * Grouped list of past notifications with timestamps, dismiss button, and "Clear all".

2. **Schedule "Tomorrow" Tab:**
   * Same layout as Screen 08 (Schedule Today) but displaying tomorrow's date, tasks, and an info banner: "Tomorrow's Schedule · Unconfirmed (Review at 09:30 PM)" with a quick button "Review Now" -> `/review/:dateKey`.

3. **Calendar "Week" View:**
   * When switching to "Week" on Screen 21, presents a 7-column time grid (Monday to Sunday) with color-coded vertical task blocks, free-time gaps, and current day highlight.

4. **Insights "Day" and "Month" Views:**
   * "Day" View: Hourly timeline chart of tasks done vs planned, focus minutes, adherence score.
   * "Month" View: 4-week bar chart of completion rates, category breakdown pie/donut chart, and monthly streak summary.

5. **Task Detail View (`/task/:id`):**
   * Read-only view with top bar (back, edit icon, delete icon).
   * Large title, category pill, priority badge, time range, status tag.
   * Notes card, focus history on this task, linked repeat series info, and action buttons "Start Focus" and "Mark Done".

6. **Picker Bottom Sheets (Time Picker, Category Picker, Reminder Offset Picker, Custom Repeat Picker):**
   * Consistent `ModalBottomSheetContainer`:
     * TimePicker: Wheel or dial with AM/PM toggle and "Done" button.
     * CategoryPicker: Grid of 6 categories with colored icon squircle, name, and color dot.
     * ReminderPicker: List options (None, At time of task, 5 min before, 10 min before, 15 min before, 30 min before).
     * CustomRepeatPicker: Day selector (M, T, W, T, F, S, S) with frequency dropdown.

7. **Focus Active, Paused, and Summary States:**
   * *Active:* Pulsing outer ring, "Pause" button, "End" button, active sound wave animation.
   * *Paused:* Amber accent ring, "Resume" button, "End" button.
   * *Summary:* Opens Screen 13 celebration with recorded session minutes.

8. **"Reset All Data" Double Confirmation Dialog:**
   * Modal dialog with red warning icon, title "Reset All Data?", description "This will permanently delete all tasks, categories, and history from this device. This cannot be undone.", input typing "RESET" or two-step confirmation buttons: "Cancel" and "Permanently Delete".

9. **Recurrence Edit Scope Dialog ("This / All Future"):**
   * Dialog when editing or deleting a recurring task:
     * "Edit this task only"
     * "Edit all upcoming tasks in this series"
     * "Cancel"
