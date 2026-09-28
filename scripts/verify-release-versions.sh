#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Fail unless CHANGELOG.md has a heading for the version being released and
# every `uses:` snippet in README.md and the examples pins that version.
#
#   scripts/verify-release-versions.sh v0.0.1
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
tag="${1:-${GITHUB_REF_NAME:-}}"
[ -n "$tag" ] || { echo "usage: $0 vX.Y.Z" >&2; exit 2; }
ver="${tag#v}"
grep -Eq "^## \[$ver\]" CHANGELOG.md || { echo "CHANGELOG.md has no '## [$ver]' heading" >&2; exit 1; }
if grep -rEo 'passmcp-action@v[0-9]+\.[0-9]+\.[0-9]+' README.md examples templates | grep -v "@v$ver"; then
  echo "a snippet pins a version other than $ver" >&2; exit 1
fi
echo "release versions agree on $ver"
