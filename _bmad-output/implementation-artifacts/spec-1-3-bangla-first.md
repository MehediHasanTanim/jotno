---
title: 'Story 1.3 — The app speaks Bangla first'
type: 'feature'
created: '2026-09-01'
status: 'in-review'
baseline_commit: 'cbdcb0981b2aab9572fbf32a50da9ec85933281a'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Eleven localisation keys exist and nothing resolves them. Every string the app can currently show is hardcoded English, in a product whose primary audience reads Bangla — and retrofitting a second language after fifty-six more stories is the failure this ordering exists to avoid.

**Approach:** Wire the localisation mechanism now, with both locales complete and a CI gate that fails on any key present in one and missing from the other. Bangla is the default; English is a setting.

## Boundaries & Constraints

**Always:**
- Bangla renders unless the device locale is English. Not "unless the device locale is Bangla" — the default is Bangla for everyone else.
- Both ARB files are complete. A key in one and not the other fails the build.
- Bengali numerals (০–৯) in the Bangla locale, through one shared formatter. No raw `toString()` on a number reaches the UI.
- Body text sets the Bangla line height (15/26) against English (15/24), and containers size to the Bangla measure so a language switch never reflows.
- Long strings wrap. Truncating a medication or member name is a safety defect, not a cosmetic one.
- The startup error surface resolves its locale **without** the database, because it is what renders when the database will not open.

**Ask First:**
- Adding any dependency beyond `flutter_localizations` and `intl` — the architecture pins the set.
- Changing where the user's language choice is stored (see Design Notes: the encrypted database, not a new preferences package).

**Never:**
- Build the Settings screen. This story provides the mechanism and persistence; Story 1.3 has no UI beyond making existing surfaces localised.
- Translate strings that do not exist yet. Only the eleven live keys plus what the current screens render.
- Bundle a Bengali font. The platform provides one; a bundled face is a Story 1.4 decision.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Fresh install, device locale Bangla | no stored choice | Bangla | N/A |
| Fresh install, device locale English | no stored choice | English | N/A |
| Fresh install, device locale Arabic | no stored choice | **Bangla** — the default, not a fallback to English | N/A |
| User picks English, relaunches | stored choice = en | English, regardless of device locale | N/A |
| Language switched at runtime | stored choice changes | Every string updates without restart | N/A |
| Database will not open | startup error surface | Renders in the device-derived locale; no stored choice is readable | Must not itself throw |
| Number rendered in Bangla | `124` | `১২৪`, tabular figures | N/A |
| Key missing from one ARB | `bn` has it, `en` does not | CI fails, naming the key and the file | N/A |

</frozen-after-approval>

## Code Map

- `jotno/lib/main.dart` — `StartupFailure` reasons carry `localisationKey`; `startupSurface()` returns the widget. Both surfaces here (`JotnoApp`, `DatabaseUnavailableApp`) render hardcoded English today.
- `jotno/lib/core/result/app_failure.dart` — five `failure*` keys.
- `jotno/lib/core/database/app_database.dart` — schema v1. A settings row lands here (see Design Notes).
- `.github/workflows/ci.yaml` — the logging gate and `tool/no_print_gate.sh` are the pattern the parity gate follows: a script CI invokes, driven by a test, with grep exit 1 distinguished from ≥2.
- `jotno/pubspec.yaml` — `intl` is not yet a dependency; `flutter_localizations` ships with the SDK.

New: `jotno/l10n.yaml`, `jotno/lib/l10n/app_bn.arb`, `jotno/lib/l10n/app_en.arb`, `jotno/lib/core/l10n/locale_controller.dart`, `jotno/lib/core/l10n/number_format.dart`, `jotno/tool/l10n_parity_gate.sh`.

## Tasks & Acceptance

**Execution:**
- [x] `jotno/pubspec.yaml` + `jotno/l10n.yaml` — add `flutter_localizations` (SDK) and `intl`; configure generation with `bn` as template
- [x] `jotno/lib/l10n/app_bn.arb` / `app_en.arb` — the eleven live keys plus the strings the two current screens render, complete in both
- [x] `jotno/lib/core/l10n/locale_controller.dart` — resolve locale: stored choice, else device locale if English, else Bangla; expose a runtime switch
- [x] `jotno/lib/core/database/app_database.dart` — a settings table holding the language choice; schema bump with generated migration
- [x] `jotno/lib/core/l10n/number_format.dart` — one formatter producing Bengali numerals in `bn`; the only way a number reaches the UI
- [x] `jotno/lib/main.dart` — wire delegates and `locale`; render both surfaces from ARB; the error surface resolves locale without the database
- [x] `jotno/tool/l10n_parity_gate.sh` + `.github/workflows/ci.yaml` — fail on any key in one ARB and not the other, naming key and file
- [x] `jotno/test/core/l10n/` — locale resolution matrix, the formatter, and a test driving the parity gate against a deliberately unbalanced pair

**Acceptance Criteria:**
- Given a device locale that is neither Bangla nor English, when the app opens with no stored choice, then it renders Bangla.
- Given a stored choice of English, when the app opens on a Bangla device, then it renders English.
- Given the language is switched at runtime, when the change commits, then every visible string updates without a restart and survives relaunch.
- Given a key added to one ARB only, when the parity gate runs, then it fails naming the key and the missing file — proven by planting one, not assumed.
- Given the Bangla locale, when any number renders, then it uses Bengali numerals; a raw `toString()` on a number in a widget fails review.
- Given the database cannot be opened, when the error surface renders, then it is localised and does not itself throw.

## Spec Change Log

## Design Notes

**Where the language choice lives: the encrypted database, not a new preferences package.** AD-1 makes the local database the only source of truth, and adding `shared_preferences` would put one user-visible setting outside it and add an unpinned dependency. The cost is the chicken-and-egg the matrix names: the startup error surface renders precisely when the database will not open, so it cannot read a stored choice. It resolves from the device locale instead. That is the right trade — the error surface has five fixed strings, and a user who has chosen English but sees the Bangla error once on a broken build has lost very little.

**The default is Bangla, not "Bangla if the device says Bangla".** A Bangladeshi user on a phone set to English is the common case, and the requirement is a Bangla-first product, so only an explicit English device locale opts out.

## Verification

**Commands:**
- `cd jotno && flutter analyze --fatal-infos` · `flutter test` · `dart format --output=none --set-exit-if-changed .`
- Plant a key in `app_bn.arb` only, run `bash tool/l10n_parity_gate.sh` — expected: fails naming the key. Remove it.
