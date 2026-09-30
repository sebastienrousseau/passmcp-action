#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Compose the release page of a tag in the passmcp family's layout and,
# with --publish, put it on GitHub. The layout: the title
# "passmcp-action X.Y.Z"; the hand-written "## Highlights ⭐️" from
# docs/releases/vX.Y.Z.md; GitHub's generated "## What's Changed" (and
# "## New Contributors" when there are any); a "## Checksums" section with
# the SHA-256 of every asset on the release, or, as for every release of
# this action, the sentence that there are none and the --note saying what
# is published instead; and GitHub's "**Full Changelog**" line last. Only
# the highlights are written by hand. This is the shell twin of the Go
# repositories' scripts/releasepage.
#
#   scripts/release-page.sh [--publish] [--target SHA] [--note TEXT] vX.Y.Z
#
# Without --publish nothing is written: the title goes to stderr and the
# page to stdout. --target places a tag that does not exist yet. A
# published page is read back, and the script fails unless GitHub shows
# what it composed. GitHub's generated notes need a gh token with contents
# access even for a dry run.
set -euo pipefail
shopt -s nullglob
# Byte order for the glob and every comparison, whatever the runner's locale.
export LC_ALL=C
cd "${PASSMCP_ACTION_ROOT:-$(dirname "${BASH_SOURCE[0]}")/..}"

readonly NAME=passmcp-action
readonly HEADING='## Highlights ⭐️'
readonly NO_ASSETS='This release attaches no downloadable assets.'

die() { echo "release-page: $*" >&2; exit 1; }

# nonblank drops leading and trailing blank lines and folds inner runs.
nonblank() { awk 'NF { if (seen && gap) print ""; print; seen = 1; gap = 0; next } { gap = 1 }'; }

# highlights prints the file from its heading on.
highlights() {
  grep -qx "${HEADING}" "$1" || die "$1 has no '${HEADING}' heading"
  sed -n "/^${HEADING}\$/,\$p" "$1" | nonblank
}

# checksums prints the section body for the files in a directory, in
# byte order of their names.
checksums() {
  local files=("$1"/*) f
  if [ ${#files[@]} -eq 0 ]; then
    printf '%s\n' "${NO_ASSETS}"
    [ -z "${note}" ] || printf '\n%s\n' "${note}"
    return 0
  fi
  printf 'SHA-256 of every asset attached to this release:\n\n```text\n'
  for f in "${files[@]}"; do
    printf '%s  %s\n' "$(shasum -a 256 <"${f}" | cut -d' ' -f1)" "${f##*/}"
  done
  printf '```\n'
}

# compose prints the page from the highlights, GitHub's notes and assets.
compose() {
  local generated=$1 assets=$2 full changes
  full=$(tr -d '\r' <"${generated}" | grep -m1 '^\*\*Full Changelog\*\*') || die "GitHub's notes have no Full Changelog line"
  changes=$(tr -d '\r' <"${generated}" | { grep -v '^\*\*Full Changelog\*\*' || true; } | sed 's/[[:space:]]*$//' | nonblank)
  highlights "docs/releases/${tag}.md"
  echo
  [ -z "${changes}" ] || printf '%s\n\n' "${changes}"
  printf '## Checksums\n\n'
  checksums "${assets}"
  printf '\n%s\n' "${full}"
}

# fetch writes GitHub's generated notes and the release's assets to work/.
fetch() {
  local api=(api "repos/${GITHUB_REPOSITORY:-"{owner}/{repo}"}/releases/generate-notes" -f "tag_name=${tag}")
  [ -z "${target}" ] || api+=(-f "target_commitish=${target}")
  gh "${api[@]}" --jq .body >"${work}/generated.md" || die "generate-notes for ${tag} failed"
  mkdir -p "${work}/assets"
  exists=no
  local names
  names=$(gh release view "${tag}" "${repo[@]}" --json assets --jq '.assets[].name' 2>/dev/null) || return 0
  exists=yes
  [ -z "${names}" ] || gh release download "${tag}" "${repo[@]}" -D "${work}/assets" || die "download the assets of ${tag} failed"
}

# publish creates or edits the release, then reads the page back.
publish() {
  local verb=(edit "${tag}") got
  [ "${exists}" = yes ] || verb=(create "${tag}" --verify-tag)
  gh release "${verb[@]}" "${repo[@]}" --title "${title}" --notes-file "${work}/notes.md" >/dev/null || die "publish ${tag} failed"
  got=$(gh release view "${tag}" "${repo[@]}" --json name,body --jq '.name + "\n" + .body') || die "read back ${tag} failed"
  [ "$(printf '%s' "${got}" | tr -d '\r')" = "$(printf '%s\n%s' "${title}" "$(cat "${work}/notes.md")")" ] ||
    die "the published page of ${tag} is not the composed one"
}

main() {
  local publish=no
  target="" note=""
  while [ $# -gt 1 ]; do
    case "$1" in
      --publish) publish=yes; shift ;;
      --target) target=$2; shift 2 ;;
      --note) note=$2; shift 2 ;;
      *) break ;;
    esac
  done
  if [ $# -ne 1 ] || [[ ! "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "usage: $0 [--publish] [--target SHA] [--note TEXT] vX.Y.Z" >&2
    exit 2
  fi
  tag=$1 title="${NAME} ${1#v}"
  repo=()
  [ -z "${GITHUB_REPOSITORY:-}" ] || repo=(-R "${GITHUB_REPOSITORY}")
  fetch
  compose "${work}/generated.md" "${work}/assets" >"${work}/notes.md"
  if [ "${publish}" = yes ]; then publish; return; fi
  echo "title: ${title}" >&2
  cat "${work}/notes.md"
}

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
main "$@"
