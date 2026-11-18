# Prompt 0 (FINAL) — Paste this into Antigravity first

Before pasting: your project must contain `AGENTS.md`, `FLOWDAY.md`, `design/flowday_ux.pdf`, `design/screens/01_...24_*.png`, and `docs/` with `SYSTEM_DESIGN.md`, `BUILD_PHASES.md`, `DESIGN_DECISIONS.md`.

---

```
Read these first, completely: AGENTS.md, FLOWDAY.md, docs/SYSTEM_DESIGN.md, docs/BUILD_PHASES.md, docs/DESIGN_DECISIONS.md.

My UI source of truth is design/flowday_ux.pdf (24 pages) and the matching images in design/screens/ (01 to 24). Open and inspect EVERY page/image. docs/DESIGN_DECISIONS.md section 3 maps each page to a file, route and build phase.

Do NOT write application code. Your task is Phase 0 only.

1. Create docs/UI_SPEC.md with, for every one of the 24 screens:
   - name, source image, route
   - purpose
   - layout from top to bottom
   - every component, with its exact text as shown
   - colors (hex), gradients, typography (family, sizes, weights), corner radii, spacing, shadows/glows, icon style
   - navigation: where it comes from and where each button leads
   - interactions (taps, swipes, toggles, selectors)
   - which data is real/derived (from the database) vs static text
   - empty, loading and error states (mark invented ones "proposed")
   - responsive notes
2. Add "Design tokens" (colors, text styles, spacing, radii, shadows) ready to turn into a Flutter ThemeData.
3. Add "Shared components" (e.g. primary button, task card, timeline row, progress ring, chip, toggle row, bottom sheet, segmented control, stat tile) with which screens use each.
4. Add "Screens required but not designed" using section 4 of docs/DESIGN_DECISIONS.md. For each, write a short description in the SAME visual style. Do not invent a new style.
5. Review docs/DESIGN_DECISIONS.md. For any decision you disagree with or find a problem with, list it with a reason. Do not change decisions silently.
6. Check docs/SYSTEM_DESIGN.md against all 24 screens and FLOWDAY.md. List any missing tables, columns, preferences or assets.
7. Give me an implementation roadmap: for each phase in BUILD_PHASES.md, which screens it covers, estimated effort (S/M/L), and risks.
8. Ask me a short numbered list of questions. Include the OPEN decisions D6, D7, D10, and anything you cannot read clearly from the images.

Then STOP. Do not create the Flutter project structure, do not add packages, and do not write Dart code until I reply "Approved".
```

---

## What to do with the agent's reply
1. Read `docs/UI_SPEC.md` quickly. Open 3 or 4 screens in it and compare with the images.
2. Answer its numbered questions (D6: nightly time 9:30 PM or 10:00 PM, D7: dark only, D10: where Task History lives).
3. Reply:

```
Approved. Update docs/UI_SPEC.md and docs/DESIGN_DECISIONS.md with my answers: <your answers>.
Then start Phase 1 only. Follow the "Generic phase prompt" workflow from docs/PROMPTS.md.
```
