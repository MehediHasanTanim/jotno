#!/usr/bin/env bash
#
# The logging gate: no direct `print` or `debugPrint` anywhere under `lib/`.
#
# Jotno holds medical records. A console call is a free-text channel straight
# into `adb logcat` and the iOS device console, where anyone with a cable — a
# repair shop, a border officer, a curious relative — can read it, and where
# nothing in the app can redact it afterwards. `AppLogger`
# (`lib/core/logging/app_logger.dart`) has no parameter that can carry text, so
# it cannot be used to leak one. This gate closes the alternative.
#
# It is a script rather than an inline CI step so a developer can run exactly
# what CI runs, and so the accompanying test can prove it fails on a real
# offending file instead of assuming it would.
#
# Usage:
#   tool/no_print_gate.sh              # scans lib/
#   tool/no_print_gate.sh path [...]   # scans the given roots (used by tests)
set -euo pipefail

if [ "$#" -gt 0 ]; then
  roots=("$@")
else
  roots=("lib")
fi

# A missing root would make the scan blind while still exiting 0. Refuse.
for root in "${roots[@]}"; do
  if [ ! -e "$root" ]; then
    echo "::error::expected $root to exist; the print scan would be blind"
    exit 1
  fi
done

# The leading class excludes `sprint(`, `blueprint(`, `footprint(` and any
# `something.print(` — a method named `print` on an object is that object's
# business, not a console write. `debugPrintStack` is caught by the same
# alternation only when written as a call to `debugPrint`, which is the intent:
# the forbidden thing is the console, not the word.
pattern='(^|[^A-Za-z0-9_$.])(print|debugPrint)[[:space:]]*\('

# grep exits 0 on a match, 1 on no match, and >=2 on an error such as an
# unreadable path. Only 1 is success — treating >=2 as "clean" would let the
# gate pass while scanning nothing, which is the failure mode the two existing
# gates in ci.yaml are also written to avoid.
matches=$(grep -R -n -E --include='*.dart' "$pattern" "${roots[@]}") && status=0 || status=$?

case "$status" in
  0)
    while IFS= read -r match; do
      [ -n "$match" ] || continue
      file=${match%%:*}
      rest=${match#*:}
      line=${rest%%:*}
      echo "::error file=$file,line=$line::direct print/debugPrint is forbidden here; record events through AppLogger (lib/core/logging/app_logger.dart), which cannot carry health data"
      echo "$file:$line: direct print/debugPrint"
    done <<<"$matches"
    echo "::error::the logging gate failed: see the file and line above"
    exit 1
    ;;
  1)
    echo "logging gate: no direct print/debugPrint under ${roots[*]}"
    ;;
  *)
    echo "::error::grep failed with exit status $status"
    exit 1
    ;;
esac
