#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Fail unless every version-bearing place in the tree names one version:
# the CHANGELOG heading, every `uses:` and `include:` snippet in the README,
# the examples and the GitLab template, the README's ecosystem sentence,
# CITATION.cff, and the release highlights. A "Released in" status keeps the
# version the capability first shipped in, so it must name a version the
# CHANGELOG has released, not necessarily this one. The CHANGELOG must also
# keep the `## [Unreleased]` heading the sync workflow opens the next
# section under.
#
#   scripts/verify-release-versions.sh [vX.Y.Z]
#
# Without an argument the version is the newest released CHANGELOG heading.
set -euo pipefail
cd "${PASSMCP_ACTION_ROOT:-$(dirname "${BASH_SOURCE[0]}")/..}"

semver='[0-9]+\.[0-9]+\.[0-9]+'
released=$(grep -Eo "^## \[${semver}\]" CHANGELOG.md | tr -d '#[] ' || true)
newest=$(head -1 <<<"${released}")
tag="${1:-v${newest}}"
ver="${tag#v}"
[[ "${ver}" =~ ^${semver}$ ]] || { echo "usage: $0 vX.Y.Z" >&2; exit 2; }

fail=0
bad() { echo "verify-release-versions: $*" >&2; fail=1; }

# Every match of the pattern in the files whose version is not one of the
# allowed versions (one per line).
mismatches() {
  local re="$1" allowed="$2" hit
  shift 2
  grep -HoE "${re}" "$@" 2>/dev/null | while IFS= read -r hit; do
    grep -qxF "$(grep -oE "${semver}" <<<"${hit#*:}" | tail -1)" <<<"${allowed}" || echo "${hit}"
  done
}

# The pattern must appear in the file, and every appearance must name one
# of the allowed versions.
required() {
  local re="$1" allowed="$2" file="$3" what="$4" off
  grep -qE "${re}" "${file}" || { bad "${file} has no ${what}"; return; }
  off=$(mismatches "${re}" "${allowed}" "${file}")
  [ -z "${off}" ] || bad "${what} names a version it may not: ${off}"
}

grep -qE "^## \[${ver//./\\.}\]" CHANGELOG.md || bad "CHANGELOG.md has no '## [${ver}]' heading"
grep -qE '^## \[Unreleased\]$' CHANGELOG.md || bad "CHANGELOG.md has no '## [Unreleased]' heading for the sync workflow"

snippets=$(mismatches "passmcp-action(@v|/v)${semver}" "${ver}" README.md examples/*.yml templates/*.yml)
[ -z "${snippets}" ] || bad "a snippet pins a version other than ${ver}: ${snippets}"

required "released at \*\*${semver}\*\*" "${ver}" README.md "ecosystem version sentence"
required "^version: \"?${semver}\"?$" "${ver}" CITATION.cff "version"
required "Released in ${semver}" "${released}" README.md "\"Released in\" status"
required "passmcp-action/releases/tag/v${semver}" "${released}" README.md "release link"
[ -f "docs/releases/v${ver}.md" ] || bad "docs/releases/v${ver}.md is missing"

[ "${fail}" -eq 0 ] && echo "verify-release-versions: every version-bearing place names ${ver}"
exit "${fail}"
