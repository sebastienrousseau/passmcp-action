#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# The image action.yml pins by digest must be the image passmcp published for
# the version this repository is at. A digest is what makes "this action
# runs what the release signed" true; this is what makes the digest the
# right one.
#
#   scripts/verify-digest.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "${PASSMCP_ACTION_ROOT:-$(dirname "${BASH_SOURCE[0]}")/..}"

version=$(grep -Eo '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | head -1 | tr -d '#[] ' || true)
[ -n "$version" ] || { echo "verify-digest: CHANGELOG.md has no released version heading" >&2; exit 1; }
pinned=$("${here}/pinned-image.sh")
pinned_digest="${pinned#*@}"

# Fetched to a file and parsed from it, never piped into an interpreter:
# that shape reads as download-then-run to a supply-chain scanner.
tokfile=$(mktemp)
trap 'rm -f "$tokfile"' EXIT
curl -fsSL "https://ghcr.io/token?scope=repository:sebastienrousseau/passmcp:pull" -o "$tokfile"
token=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["token"])' "$tokfile")
accept="application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json"
manifest="https://ghcr.io/v2/sebastienrousseau/passmcp/manifests/${version}"
# A version passmcp has not released yet answers 404: say which, not curl's code.
headers=$(curl -fsSI -H "Authorization: Bearer ${token}" -H "Accept: ${accept}" "${manifest}") \
  || { echo "verify-digest: ghcr.io has no image tagged ${version}; the manifest request failed" >&2; exit 1; }
published=$(tr -d '\r' <<<"${headers}" | awk 'tolower($1) == "docker-content-digest:" { print $2 }')
[ -n "$published" ] || { echo "verify-digest: ghcr.io has no image tagged ${version}" >&2; exit 1; }

# The GitLab template pins the same image; one digest, two places.
template=$(sed -n 's/^  PASSMCP_IMAGE: "\(.*\)"$/\1/p' templates/passmcp.gitlab-ci.yml)

fail=0
if [ "$pinned_digest" != "$published" ]; then
  echo "verify-digest: action.yml pins ${pinned_digest} and ghcr.io tags ${version} as ${published}" >&2; fail=1
fi
if [ "$template" != "$pinned" ]; then
  echo "verify-digest: templates/passmcp.gitlab-ci.yml pins ${template}, action.yml pins ${pinned}" >&2; fail=1
fi
[ "$fail" -eq 0 ] && echo "verify-digest: action.yml and the GitLab template pin the image ghcr.io tags ${version} (${published})"
exit "$fail"
