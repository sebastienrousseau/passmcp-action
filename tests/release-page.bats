#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

bats_require_minimum_version 1.5.0
load helpers

# The fixtures are the shapes GitHub and a highlights file take: notes with
# a New Contributors section and the runs of blank lines GitHub leaves, and
# highlights under their SPDX header.
setup() {
  setup_tree
  export PATH="${REPO}/tests/bin:${PATH}" GITHUB_REPOSITORY=o/r
  export STUB_GH_LOG="${BATS_TEST_TMPDIR}/gh.log" STUB_NOTES="${BATS_TEST_TMPDIR}/notes.md"
  unset STUB_ASSETS STUB_NO_RELEASE STUB_GH_FAIL STUB_TAMPER
  cat >"${TREE}/docs/releases/v0.0.2.md" <<'EOF'
<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

## Highlights ⭐️

* **One thing**: It changed for the user.
* **Another thing**: So did this.

EOF
  printf '%s\n' "## What's Changed" \
    '* feat: add a check by @alice in https://github.com/o/r/pull/7' \
    '* fix(deps): bump x by @dependabot[bot] in https://github.com/o/r/pull/8' \
    '' '' '## New Contributors' \
    '* @alice made their first contribution in https://github.com/o/r/pull/7' \
    '' '' '**Full Changelog**: https://github.com/o/r/compare/v0.0.1...v0.0.2' >"${STUB_NOTES}"
}

# The page the fixtures make, with the given checksums section body.
expected() {
  cat <<'EOF'
## Highlights ⭐️

* **One thing**: It changed for the user.
* **Another thing**: So did this.

## What's Changed
* feat: add a check by @alice in https://github.com/o/r/pull/7
* fix(deps): bump x by @dependabot[bot] in https://github.com/o/r/pull/8

## New Contributors
* @alice made their first contribution in https://github.com/o/r/pull/7

## Checksums

EOF
  printf '%s\n\n%s\n' "$1" '**Full Changelog**: https://github.com/o/r/compare/v0.0.1...v0.0.2'
}

with_assets() {
  export STUB_ASSETS="${BATS_TEST_TMPDIR}/assets"
  mkdir -p "${STUB_ASSETS}"
  printf 'sums\n' >"${STUB_ASSETS}/checksums.txt"
  printf 'archive\n' >"${STUB_ASSETS}/app_Linux_x86_64.tar.gz"
}

# The script, with its stderr kept apart in a file.
page() { "${SCRIPTS}/release-page.sh" "$@" 2>"${BATS_TEST_TMPDIR}/stderr"; }
errors() { cat "${BATS_TEST_TMPDIR}/stderr"; }

ASSET_SECTION='SHA-256 of every asset attached to this release:

```text
371e16ce98051a3ea7af3eaef8b87d69033154fb5bb33da349d611f0fae061d6  app_Linux_x86_64.tar.gz
c001d0d1d2da2d23b87521529826ff1bb00c6afaac20b652c0871905c84d1508  checksums.txt
```'

@test "prints the page with the release's assets hashed, and writes nothing" {
  with_assets
  run page v0.0.2
  [ "$status" -eq 0 ]
  [ "$output" = "$(expected "${ASSET_SECTION}")" ]
  [ "$(errors)" = "title: passmcp-action 0.0.2" ]
  grep -q '^api repos/o/r/releases/generate-notes -f tag_name=v0.0.2 --jq .body$' "${STUB_GH_LOG}"
  run ! grep -Eq '^release (create|edit)' "${STUB_GH_LOG}"
}

@test "no assets says so, then what is published instead" {
  run page --note "The action runs \`img@sha256:0\`." v0.0.2
  [ "$status" -eq 0 ]
  [ "$output" = "$(expected "$(printf '%s\n\n%s' 'This release attaches no downloadable assets.' "The action runs \`img@sha256:0\`.")")" ]
  run ! grep -q '^release download' "${STUB_GH_LOG}"
}

@test "notes with only the Full Changelog line leave no empty section" {
  printf '%s\n' '**Full Changelog**: https://github.com/o/r/commits/v0.0.2' >"${STUB_NOTES}"
  run page v0.0.2
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' '## Highlights ⭐️' '' '* **One thing**: It changed for the user.' '* **Another thing**: So did this.' '' '## Checksums' '' 'This release attaches no downloadable assets.' '' '**Full Changelog**: https://github.com/o/r/commits/v0.0.2')" ]
}

@test "a tag that does not exist yet is placed at the target commit" {
  STUB_NO_RELEASE=1 run page --target abc123 v0.0.2
  [ "$status" -eq 0 ]
  grep -q -- '-f target_commitish=abc123' "${STUB_GH_LOG}"
}

@test "publish edits the existing release and reads it back" {
  with_assets
  run page --publish v0.0.2
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  grep -Eq '^release edit v0.0.2 -R o/r --title passmcp-action 0.0.2 --notes-file ' "${STUB_GH_LOG}"
  [ "$(cat "${STUB_GH_LOG}.page")" = "$(printf 'passmcp-action 0.0.2\n%s' "$(expected "${ASSET_SECTION}")")" ]
}

@test "publish creates a release that does not exist yet" {
  STUB_NO_RELEASE=1 run page --publish v0.0.2
  [ "$status" -eq 0 ]
  grep -q '^release create v0.0.2 --verify-tag -R o/r --title passmcp-action 0.0.2' "${STUB_GH_LOG}"
}

@test "a published page that is not the composed one fails" {
  STUB_TAMPER=1 run page --publish v0.0.2
  [ "$status" -eq 1 ]
  [[ "$(errors)" == *"the published page of v0.0.2 is not the composed one"* ]]
}

@test "a gh failure names the step" {
  with_assets
  for step in "generate-notes:generate-notes for v0.0.2" "release download:download the assets of v0.0.2" \
    "release edit:publish v0.0.2" "name,body:read back v0.0.2"; do
    STUB_GH_FAIL="${step%%:*}" run page --publish v0.0.2
    [ "$status" -eq 1 ]
    [[ "$(errors)" == *"${step#*:} failed"* ]]
  done
}

@test "highlights without their heading fail" {
  printf '## Changes\n* x\n' >"${TREE}/docs/releases/v0.0.2.md"
  run page v0.0.2
  [ "$status" -eq 1 ]
  [[ "$(errors)" == *"has no '## Highlights ⭐️' heading"* ]]
}

@test "notes without the Full Changelog line fail" {
  printf "## What's Changed\n* x\n" >"${STUB_NOTES}"
  run page v0.0.2
  [ "$status" -eq 1 ]
  [[ "$(errors)" == *"no Full Changelog line"* ]]
}

@test "a tag that is not vX.Y.Z, or a stray argument, is a usage error" {
  for args in "0.0.2" "v0.0.2 extra" "--bogus v0.0.2"; do
    # shellcheck disable=SC2086 # the words are the arguments under test
    run page ${args}
    [ "$status" -eq 2 ]
    [[ "$(errors)" == usage:* ]]
  done
}

@test "without GITHUB_REPOSITORY gh infers the repository" {
  unset GITHUB_REPOSITORY
  run page v0.0.2
  [ "$status" -eq 0 ]
  grep -q '^api repos/{owner}/{repo}/releases/generate-notes' "${STUB_GH_LOG}"
  run ! grep -q -- '-R ' "${STUB_GH_LOG}"
}
