#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Every repository in the passmcp family verifies its own row against the
# manifest passmcp publishes, so the map and the territory cannot drift.
#
#   scripts/family.sh
set -euo pipefail
cd "${PASSMCP_ACTION_ROOT:-$(dirname "${BASH_SOURCE[0]}")/..}"

manifest="${PASSMCP_ECOSYSTEM_URL:-https://raw.githubusercontent.com/sebastienrousseau/passmcp/main/ecosystem.json}"
# Fetched to a file and parsed from it, never piped into an interpreter:
# that shape reads as download-then-run to a supply-chain scanner.
mf=$(mktemp)
trap 'rm -f "$mf"' EXIT
curl -fsSL "$manifest" -o "$mf"
# The row, as "status licence language lockstep", or an exit naming the gap.
pick='import json, sys
rows = [r for r in json.load(open(sys.argv[1]))["repositories"] if r["name"] == "passmcp-action"]
if not rows:
    sys.exit("family: passmcp-action has no row in the family manifest")
r = rows[0]
print(r["status"], r["license"], r["language"], str(r["lockstep"]).lower())'
row=$(python3 -c "$pick" "$mf")
read -r status licence language lockstep <<<"$row"

fail=0
have=$(basename -s .txt LICENSES/*.txt | head -1)
if [ "$licence" != "$have" ]; then
  echo "family: the manifest says $licence and LICENSES/ holds $have" >&2; fail=1
fi
if [ "$language" != "composite" ] || ! grep -q '^  using: "composite"$' action.yml; then
  echo "family: the manifest says $language and action.yml is not a composite action" >&2; fail=1
fi
if [ "$lockstep" != "true" ] || [ ! -x scripts/lockstep.sh ]; then
  echo "family: the manifest says lockstep=$lockstep and this repository carries passmcp's version" >&2; fail=1
fi
# `released` is the family standard's name; `shipping` is what passmcp's
# manifest said before schema_version 2, and main serves it until 0.0.2.
if [ "$status" != "released" ] && [ "$status" != "shipping" ]; then
  echo "::warning::family: the manifest still lists passmcp-action as $status"
fi
[ "$fail" -eq 0 ] && echo "family: the manifest's row for passmcp-action is true of this tree ($licence, $language, lockstep=$lockstep, $status)"
exit "$fail"
