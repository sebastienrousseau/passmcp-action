#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

load helpers

setup() { setup_tree; }

@test "the tree names one version everywhere" {
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"every version-bearing place names ${VER}"* ]]
}

@test "without an argument it checks the newest CHANGELOG version" {
  run "${SCRIPTS}/verify-release-versions.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"names ${VER}"* ]]
}

@test "a version that is not X.Y.Z is a usage error" {
  run "${SCRIPTS}/verify-release-versions.sh" main
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage:"* ]]
}

@test "a version with no CHANGELOG heading fails" {
  run "${SCRIPTS}/verify-release-versions.sh" v9.9.9
  [ "$status" -eq 1 ]
  [[ "$output" == *"no '## [9.9.9]' heading"* ]]
}

@test "a CHANGELOG without the Unreleased heading fails, because the sync workflow needs it" {
  edit CHANGELOG.md "## [Unreleased]" "## Pending"
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no '## [Unreleased]' heading"* ]]
}

@test "a uses: snippet on another version fails, even one sharing a prefix" {
  edit examples/scheduled.yml "passmcp-action@v${VER}" "passmcp-action@v${VER}0"
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"scheduled.yml:passmcp-action@v${VER}0"* ]]
}

@test "a GitLab include on another version fails" {
  edit templates/passmcp.gitlab-ci.yml "passmcp-action/v${VER}/" "passmcp-action/v9.9.9/"
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"passmcp-action/v9.9.9"* ]]
}

@test "the ecosystem sentence on another version fails" {
  edit README.md "released at **${VER}**" "released at **9.9.9**"
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ecosystem version sentence names a version it may not"* ]]
}

@test "a README without the ecosystem sentence fails" {
  edit README.md "released at **${VER}**" "released together"
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"README.md has no ecosystem version sentence"* ]]
}

@test "a Released in status or release link on an unreleased version fails" {
  edit README.md "Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1)" "Released in 9.9.9](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v9.9.9)"
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"\"Released in\" status names a version it may not"* ]]
  [[ "$output" == *"release link names a version it may not"* ]]
}

@test "a Released in status on an earlier release still passes" {
  printf '\n## [0.0.0] — 2026-01-01\n' >>"${TREE}/CHANGELOG.md"
  edit README.md "Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1)" "Released in 0.0.0](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.0)"
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 0 ]
}

@test "CITATION.cff on another version fails" {
  edit CITATION.cff "version: ${VER}" "version: 9.9.4"
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"CITATION.cff:version: 9.9.4"* ]]
}

@test "missing release highlights fail" {
  rm "${TREE}/docs/releases/v${VER}.md"
  run "${SCRIPTS}/verify-release-versions.sh" "v${VER}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"docs/releases/v${VER}.md is missing"* ]]
}
