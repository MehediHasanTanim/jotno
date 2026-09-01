#!/usr/bin/env bash
#
# The logging gate: nothing under `lib/` writes to the device log except the
# one writer that is allowed to.
#
# Jotno holds medical records. Anything that reaches `adb logcat` or the iOS
# device console can be read by anyone with a cable — a repair shop, a border
# officer, a curious relative — and nothing in the app can redact it
# afterwards. `AppLogger` (`lib/core/logging/app_logger.dart`) has no parameter
# that can carry text, so it cannot be used to leak a diagnosis. This gate
# closes the alternatives.
#
# There are more doors than `print`, and the analyzer guards only one of them:
# `avoid_print` covers `print` and says nothing about `debugPrint`,
# `debugPrintStack`, `stdout.writeln`, `stderr.writeln`, or `dart:developer`'s
# `log`. All of them end up in the same place. So this scans for all of them,
# and allows `dart:developer` in exactly one file — the writer that needs it.
#
# It is a script rather than an inline CI step so a developer can run exactly
# what CI runs, and so `test/tool/no_print_gate_test.dart` can prove it fails
# on real offending files instead of assuming it would.
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
    echo "::error::expected $root to exist; the logging scan would be blind"
    exit 1
  fi
done

# The one file permitted to import `dart:developer`: the writer whose whole job
# is to be the single place a line reaches the log. Matched as a path suffix so
# it works whatever root the scan was pointed at.
developer_allowlist='core/logging/log_writer\.dart:'

offences=0

# Prints one `file:line: reason` per match and counts it.
#
# Deliberately not a `::error file=,line=` annotation. CI runs with
# `working-directory: jotno`, but GitHub resolves annotation paths from the
# repository root, so every annotation would point at a file that does not
# exist. The two gates already in ci.yaml print their matches plainly and
# follow with a single `::error::`; this does the same.
report() {
  local matches="$1" hint="$2"
  local match file rest line
  while IFS= read -r match; do
    [ -n "$match" ] || continue
    file=${match%%:*}
    rest=${match#*:}
    line=${rest%%:*}
    echo "$file:$line: $hint"
    offences=$((offences + 1))
  done <<<"$matches"
}

# grep exits 0 on a match, 1 on no match, and >=2 on an error such as an
# unreadable path. Only 1 is clean — treating >=2 as "clean" would let the gate
# pass while scanning nothing, which is the failure mode the two existing gates
# in ci.yaml are also written to avoid.
scan() {
  local label="$1" pattern="$2" hint="$3"
  local matches status
  matches=$(grep -R -n -E --include='*.dart' "$pattern" "${roots[@]}") && status=0 || status=$?
  case "$status" in
    0) report "$matches" "$hint" ;;
    1) echo "logging gate: clean — $label" ;;
    *)
      echo "::error::grep failed with exit status $status scanning for $label"
      exit 1
      ;;
  esac
}

# Same as `scan`, minus the one file allowed to match.
scan_allowlisted() {
  local label="$1" pattern="$2" hint="$3" allowed="$4"
  local matches status filtered filter_status
  matches=$(grep -R -n -E --include='*.dart' "$pattern" "${roots[@]}") && status=0 || status=$?
  case "$status" in
    0) ;;
    1)
      echo "logging gate: clean — $label"
      return
      ;;
    *)
      echo "::error::grep failed with exit status $status scanning for $label"
      exit 1
      ;;
  esac

  filtered=$(printf '%s\n' "$matches" | grep -v -E "$allowed") && filter_status=0 ||
    filter_status=$?
  case "$filter_status" in
    0) report "$filtered" "$hint" ;;
    1) echo "logging gate: clean — $label (allowlisted file only)" ;;
    *)
      echo "::error::grep failed with exit status $filter_status applying the $label allowlist"
      exit 1
      ;;
  esac
}

# 1. The console functions. The leading class excludes `sprint(`, `blueprint(`
#    and any `something.print(` — a method named `print` on an object is that
#    object's business, not a console write.
scan 'console calls' \
  '(^|[^A-Za-z0-9_$.])(print|debugPrint|debugPrintStack|debugPrintThrottled|debugPrintSynchronously)[[:space:]]*\(' \
  'direct console call is forbidden; record events through AppLogger (lib/core/logging/app_logger.dart), which cannot carry health data'

# 2. `dart:io` standard streams. On Android and iOS these land in the same
#    device log as `print`, and neither the analyzer nor the check above sees
#    them.
scan 'stdout/stderr writes' \
  '(^|[^A-Za-z0-9_$.])(stdout|stderr)[[:space:]]*\.[[:space:]]*(write|writeln|writeAll|writeCharCode|add|addStream)[[:space:]]*\(' \
  'writing to stdout/stderr reaches the device log; record events through AppLogger (lib/core/logging/app_logger.dart)'

# 3. `dart:developer`. Banned by import rather than by call site: the call can
#    be spelled `log(...)`, `developer.log(...)` or `dev.log(...)` depending on
#    the prefix, but it cannot be made without the import.
scan_allowlisted 'dart:developer imports' \
  '^[[:space:]]*import[[:space:]]+['\''"]dart:developer' \
  'only lib/core/logging/log_writer.dart may import dart:developer; everything else records through AppLogger' \
  "$developer_allowlist"

if [ "$offences" -gt 0 ]; then
  echo "::error::the logging gate failed on $offences line(s); see the file and line above"
  exit 1
fi
