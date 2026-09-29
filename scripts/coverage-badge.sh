#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Write the shields.io endpoint file for the coverage badge, and fail when
# the coverage is below the floor. The file is written either way, so a
# failing run still shows the number it failed on.
#
#   scripts/coverage-badge.sh PERCENT [OUT]     (OUT defaults to coverage.json)
#   COVERAGE_MIN=85                              the floor, in percent
set -euo pipefail

pct="${1:-}"
out="${2:-coverage.json}"
min="${COVERAGE_MIN:-85}"
[[ "${pct}" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "usage: $0 PERCENT [OUT]" >&2; exit 2; }
[[ "${min}" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "coverage-badge: COVERAGE_MIN must be a number, got '${min}'" >&2; exit 2; }

# The family's colour scale: brightgreen >= 90, green >= 85, yellow >= 70.
colour=$(awk -v p="${pct}" 'BEGIN {
  if (p >= 90) print "brightgreen"; else if (p >= 85) print "green";
  else if (p >= 70) print "yellow"; else print "red" }')
shown=$(awk -v p="${pct}" 'BEGIN { printf "%.1f", p }')

printf '{"schemaVersion":1,"label":"coverage","message":"%s%%","color":"%s"}\n' \
  "${shown}" "${colour}" >"${out}"
echo "coverage-badge: ${shown}% (${colour}) written to ${out}" >&2

if awk -v p="${pct}" -v m="${min}" 'BEGIN { exit !(p < m) }'; then
  echo "coverage-badge: ${shown}% is below the ${min}% floor" >&2
  exit 1
fi
