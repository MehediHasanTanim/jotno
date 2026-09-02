#!/usr/bin/env bash
#
# The l10n parity gate: every key exists in every locale, or the build fails.
#
# Jotno is a Bangla-first product with English as a setting. A key that exists
# in one ARB and not the other does not fail loudly at runtime — `gen-l10n`
# fills the hole from the template, so a Bangla reader is quietly shown an
# English sentence, or an English reader a Bangla one, on a screen nobody on
# the team happens to open in that language. There is no crash, no log line
# and no test failure. The only place that can be caught is here.
#
# It is a script rather than an inline CI step for the same two reasons
# `no_print_gate.sh` is: a developer can run exactly what CI runs, and
# `test/core/l10n/l10n_parity_gate_test.dart` can plant an unbalanced pair and
# prove the gate fails on it, instead of assuming it would.
#
# Usage:
#   tool/l10n_parity_gate.sh              # checks lib/l10n
#   tool/l10n_parity_gate.sh <dir>        # checks the given directory
set -euo pipefail

arb_dir="${1:-lib/l10n}"

# A missing directory would make the scan blind while still finding nothing to
# complain about. Refuse — the same failure mode the other gates are written to
# avoid.
if [ ! -d "$arb_dir" ]; then
  echo "::error::expected $arb_dir to exist; the l10n parity scan would be blind"
  exit 1
fi

# grep exits 0 on a match, 1 on no match, and >=2 on an error. Only 1 means
# "there are genuinely no ARB files"; >=2 is a broken scan and must not read as
# a clean one.
arb_files=$(find "$arb_dir" -maxdepth 1 -name 'app_*.arb' | sort) || {
  echo "::error::could not list ARB files in $arb_dir"
  exit 1
}

if [ -z "$arb_files" ]; then
  echo "::error::no app_*.arb files in $arb_dir; the parity gate would pass on nothing"
  exit 1
fi

file_count=$(printf '%s\n' "$arb_files" | wc -l | tr -d ' ')
if [ "$file_count" -lt 2 ]; then
  echo "::error::found only $file_count ARB file in $arb_dir; parity needs at least two locales"
  printf '%s\n' "$arb_files"
  exit 1
fi

# ARB is JSON, so it is parsed as JSON. A grep over `"key":` lines would also
# match the nested fields inside an `@key` metadata block ("description",
# "type", "example", every placeholder name) and would break the first time
# somebody reformatted a file — a gate that is wrong about what a key is fails
# the build for the wrong reason and gets switched off.
#
# python3 is already a CI dependency (ci.yaml parses pubspec.yaml with it) and
# ships with macOS and every Linux runner. If it is absent, this exits non-zero
# rather than skipping the check.
python3 - "$arb_files" <<'PY'
import json
import sys
from pathlib import Path

paths = [Path(line) for line in sys.argv[1].splitlines() if line.strip()]

# key -> set of locales that define it. `@key` entries are metadata (the
# description, the placeholder types) and belong to the template only, so they
# are not part of parity. `@@locale` and friends are directives.
keys: dict[str, set[str]] = {}
locales: list[str] = []
failed = False

for path in paths:
    try:
        with path.open(encoding='utf-8') as handle:
            content = json.load(handle)
    except json.JSONDecodeError as error:
        print(f'{path}: not valid JSON — {error}')
        failed = True
        continue

    locale = path.name
    locales.append(locale)
    for key in content:
        if key.startswith('@'):
            continue
        keys.setdefault(key, set()).add(locale)

if failed:
    print('::error::an ARB file could not be parsed; parity is unknown')
    sys.exit(1)

missing = 0
for key in sorted(keys):
    for locale in locales:
        if locale not in keys[key]:
            present = ', '.join(sorted(keys[key]))
            print(
                f'{locale}: missing key "{key}" — it is defined in {present}. '
                f'Add "{key}" to {locale} or remove it from {present}.'
            )
            missing += 1

if missing:
    print(
        f'::error::the l10n parity gate failed on {missing} missing key(s); '
        'every key must exist in every locale, because a key present in one '
        'file only is silently served in the wrong language'
    )
    sys.exit(1)

print(
    f'l10n parity gate: clean — {len(keys)} key(s) present in all '
    f'{len(locales)} locale(s) ({", ".join(sorted(locales))})'
)
PY
