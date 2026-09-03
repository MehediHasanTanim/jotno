---
name: Jotno
description: Bangla-first family health record for Bangladeshi households. Calm and clinical — white ground, one deep green, saturated colour reserved for meaning.
status: final
created: 2026-08-29
updated: 2026-08-30
sources:
  - ../../prds/prd-bmad-test-2026-08-29/prd.md
  - ../../briefs/brief-bmad-test-2026-08-28/brief.md
colors:
  surface-base: '#F7F9F8'
  surface-raised: '#FFFFFF'
  surface-sunken: '#F1F4F3'
  ink-primary: '#14201C'
  ink-secondary: '#5A6B65'
  ink-tertiary: '#8A9691'
  ink-disabled: '#B8C2BE'
  primary: '#2C6355'
  primary-dark: '#1F4A3F'
  primary-tint: '#E8F0ED'
  critical: '#B3261E'
  critical-tint: '#FDECEA'
  critical-border: '#F5D5D1'
  critical-ink: '#8C2C25'
  attention: '#A8600B'
  attention-tint: '#FBF0E2'
  attention-border: '#EFDFC4'
  border-hairline: '#E2E8E5'
  border-hairline-soft: '#EDF1EF'
  border-input: '#C9D3CF'
  chart-secondary: '#A9BDB6'
typography:
  display:
    fontFamily: "'Noto Sans Bengali', 'Noto Sans', system-ui, sans-serif"
    fontSize: 28px
    fontWeight: 600
    lineHeight: 1.4
    note: 'Bangla 1.4 · English 1.3'
  title:
    fontSize: 22px
    fontWeight: 600
    lineHeight: 1.45
    note: 'Bangla 1.45 · English 1.35'
  heading:
    fontSize: 17px
    fontWeight: 500
    lineHeight: 1.5
    note: 'Bangla 1.5 · English 1.45'
  body:
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.75
    note: 'Bangla 1.75 · English 1.6 — the single most important type rule in the system'
  label:
    fontSize: 13px
    fontWeight: 600
    lineHeight: 1.7
  caption:
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.75
  section-label:
    fontSize: 13px
    fontWeight: 600
    letterSpacing: 0.04em
    note: 'ink-tertiary. Section headers inside a screen.'
  numeric:
    note: 'font-variant-numeric: tabular-nums on every measurement, dose, date and time'
rounded:
  xs: 4px
  sm: 6px
  md: 8px
  lg: 14px
  pill: 18px
  full: 9999px
spacing:
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 20px
  '6': 24px
  '8': 32px
  screen-margin: 20px
  header-top: 56px
  safe-bottom: 24px
components:
  button-primary:
    background: '{colors.primary}'
    color: '{colors.surface-raised}'
    height: 52px
    radius: '{rounded.md}'
    fontSize: 16px
    fontWeight: 600
  button-secondary:
    background: '{colors.surface-raised}'
    color: '{colors.primary}'
    border: '1.5px solid {colors.primary}'
    height: 48px
    radius: '{rounded.md}'
  button-tertiary:
    background: '{colors.surface-raised}'
    color: '{colors.ink-secondary}'
    border: '1px solid {colors.border-hairline}'
    height: 48px
    radius: '{rounded.md}'
  button-destructive:
    background: '{colors.critical}'
    color: '{colors.surface-raised}'
    height: 52px
    radius: '{rounded.md}'
  card:
    background: '{colors.surface-raised}'
    border: '1px solid {colors.border-hairline}'
    radius: '{rounded.md}'
    padding: '{spacing.4}'
    shadow: none
  list-row:
    minHeight: 48px
    padding: '13px 14px'
    divider: '1px solid {colors.border-hairline-soft}'
    chevron: '{colors.ink-disabled}'
  input:
    height: 50px
    border: '1px solid {colors.border-input}'
    borderFocus: '1.5px solid {colors.primary}'
    radius: '{rounded.md}'
    fontSize: 16px
  chip-filter:
    height: 32px
    padding: '7px 15px'
    radius: '{rounded.pill}'
    selectedBackground: '{colors.primary}'
    selectedColor: '{colors.surface-raised}'
    restBorder: '1px solid {colors.border-hairline}'
  badge-critical:
    background: '{colors.critical-tint}'
    color: '{colors.critical}'
    radius: '{rounded.xs}'
    fontSize: 12px
    fontWeight: 600
  badge-attention:
    background: '{colors.attention-tint}'
    color: '{colors.attention}'
    radius: '{rounded.xs}'
  badge-done:
    background: '{colors.primary-tint}'
    color: '{colors.primary-dark}'
    radius: '{rounded.xs}'
  sheet:
    background: '{colors.surface-raised}'
    radius: '14px 14px 0 0'
    shadow: '0 -8px 32px rgba(20,32,28,0.13)'
    grabber: '44x4px {colors.border-hairline}'
  tab-bar:
    background: '{colors.surface-raised}'
    borderTop: '1px solid {colors.border-hairline}'
    iconSize: 22px
    labelSize: 11px
    activeColor: '{colors.primary}'
    restColor: '{colors.ink-tertiary}'
  app-icon:
    ground: '{colors.primary}'
    mark: '{colors.surface-raised}'
    strokeAt24: 1.45
    simplifyBelow: 44px
---

# Jotno — Visual Identity

Paired with `EXPERIENCE.md`, which owns behaviour. Where a mock and this file disagree, this file wins.

Composition reference: the published canvas, 39 artboards including the two app-icon boards. Working sources in `.working/`.

## Brand & Style

Jotno holds a family's medical history — a father's diagnosis, a child's vaccination record, the prescription that has to be right. The visual register follows from that: **calm and clinical**. White ground, restrained type, hairline rules, and one deep green that never shouts.

The discipline that makes it work is negative: almost nothing is coloured. Saturated colour in Jotno is *information*, not decoration. Red means a severe allergy. Amber means a dose was missed. Because nothing else competes for those two registers, a stranger reading an emergency card under stress finds the allergy in under a second.

This is deliberately not the warm, rounded, illustrated register of consumer wellness apps. Jotno is closer to a well-kept paper file than to a fitness tracker — which is what it is replacing, and what its users already trust.

Bangla is the primary language, not a translation layer. Every layout is measured against Bangla text; English is the shorter, easier case.

## Colors

- **Primary — deep green (`#2C6355`)** carries every affirmative action, active tab, and selected state. Desaturated and slightly blue-leaning on purpose: a vivid pharmacy green would fight the calm register and, worse, compete with the two colours that must win. **Primary dark (`#1F4A3F`)** is for text on tint; **primary tint (`#E8F0ED`)** fills avatars, selected chips, and confirmation surfaces.

- **Critical — red (`#B3261E`)** has exactly one meaning: *a severe allergy*, plus the destructive-action affordance. It appears on the emergency card header, the severe-allergy badge, the delete path, and nowhere else. It is never used for a generic error, a required field, or a negative number.

- **Attention — amber (`#A8600B`)** has exactly one meaning: *something lapsed or is overdue* — a missed dose, an overdue vaccination, a broken cloud connection, a warning the user should read before proceeding.

- **Ground (`#F7F9F8`)** is the screen behind cards; **raised (`#FFFFFF`)** is every card, sheet, header and tab bar. The tonal step between them is the primary depth cue.

- **Ink** runs `#14201C` → `#5A6B65` → `#8A9691` → `#B8C2BE`. The near-black is green-tinted, not neutral, so text sits in the same family as the ground.

- **Hairline (`#E2E8E5`)** draws every card border and divider. **Soft hairline (`#EDF1EF`)** separates rows *inside* a card, one step lighter so nesting reads without a second border weight.

**Never:** gradients; a second accent hue; red or amber as decoration; colour as the only carrier of meaning (every coloured state also carries a label or an icon); tinted card backgrounds to indicate category.

## Typography

**Noto Sans Bengali** and **Noto Sans** — one superfamily, so Bangla and English share metrics and no substitution jars. Noto Sans Bengali was chosen for complete conjunct coverage (যুক্তাক্ষর render correctly rather than dropping to fallback boxes) and for being present or reliably bundleable on both platforms.

The ramp: display 28 · title 22 · heading 17 · body 15 · label 13 · caption 12.

**The line-height rule is the most consequential in this system.** Bangla needs a taller line box than Latin at the same size — body sets **15/26 in Bangla against 15/24 in English**. Every container is sized to the *Bangla* measure. This is why switching language never reflows a layout, and why the English build looks slightly generous rather than the Bangla build looking cramped.

Bangla strings also run longer than their English equivalents. Buttons, chips and labels must wrap or accommodate, never truncate — a truncated medication name is a safety problem, not a cosmetic one.

**Numerals are Bengali** (০১২৩৪৫৬৭৮৯) everywhere a number is displayed: doses, times, dates, measurements, counts. Every numeric run sets `tabular-nums` so columns of readings align.

No all-caps in Bangla — the script has no case, and forcing it on the English build creates an inconsistency between languages. Section labels use weight and colour instead, with letter-spacing applied only to the Latin build.

## Layout & Spacing

Scale: 4 / 8 / 12 / 16 / 20 / 24 / 32. Screen margin is 20px. Headers begin 56px from the top — the real status bar renders above it and is never drawn.

Single column throughout. Cards stack; sheets rise from the bottom edge and stack one level only. Content sits between a header and, on the five root surfaces, a tab bar with 24px of bottom safe area.

Sibling groups — chips, action rows, tab items, badge runs — are laid out with flex and `gap`, never with margins or source whitespace.

## Elevation & Depth

**Depth is hairlines, not shadows.** Cards are 1px borders on white against a `surface-base` ground. There is exactly one shadow in the system — `0 -8px 32px rgba(20,32,28,0.13)` on bottom sheets — and it exists to signal that the layer beneath is still live and will return.

No elevation on cards, headers, tab bars, or buttons. Hierarchy comes from tone, type and space.

## Shapes

`xs 4px` badges and small chips · `sm 6px` nested rows and thumbnails · `md 8px` cards, buttons and inputs — the workhorse · `lg 14px` sheets · `pill 18px` filter chips · `full` avatars.

Restrained radii belong to the clinical register; a 16–20px card radius would push the product toward consumer-friendly and away from record-keeping.

## Components

Frontmatter carries the token values. Rules that don't fit in a token:

**Buttons.** Primary is 52px, secondary and tertiary 48px. Destructive uses `critical` fill and only ever appears behind a typed or held confirmation.

**Cards.** 1px hairline, 8px radius, no shadow. Rows inside a card divide with `border-hairline-soft`, never a full hairline.

**Inputs.** 50px, `border-input` at rest, `1.5px primary` on focus — a focus state that is visible without colour alone. 16px text minimum, because iOS zooms anything smaller.

**Badges.** Three semantic fills only: done (primary tint), attention (amber tint), critical (red tint). A badge always carries a word — never a bare colour dot.

**Severe-allergy treatment.** Red fill, red border, bold, and it sorts above every other allergy. It appears identically on the member profile, the emergency card, and the exported PDF, so the same fact looks the same in all three places.

**Tap targets are 48px minimum.** Dose controls run larger — 46–52px with generous horizontal area — because they are used one-handed, in a hurry, often by an older family member.

**App icon.** A heart built from two equal circles on one axis, meeting at the midline: the lobes are leaf tips, not heart bumps. Stroke 1.45 at 24×24, scaled with the canvas. **Below 44px the side veins drop and the stroke thickens** — two source drawings, not one scaled. Android adaptive: mark inside the centre 66dp circle, flat background layer, monochrome variant for the Android 13 tray.

## Do's and Don'ts

**Do**
- Reserve red for severe allergies and destructive actions; amber for lapsed or overdue.
- Size every container to the Bangla measure.
- Use Bengali numerals and tabular figures for all numeric display.
- Pair every colour-carried state with a label or icon.
- Draw depth with hairlines.
- Wrap long strings; never truncate a medication, condition or member name.

**Don't**
- Add a gradient, a second accent, or a shadow beyond the sheet.
- Colour a lab value good or bad — Jotno records, it does not interpret (see `EXPERIENCE.md`).
- Draw a fake status bar or keyboard.
- Use emoji as iconography; icons are stroke SVG on a 24px grid.
- Put dosage, condition or lab detail in a notification preview.
- Let an ad appear on the emergency card, a medication reminder, or any active data-entry screen.
