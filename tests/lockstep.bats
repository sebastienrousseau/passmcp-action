#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

load helpers

setup() { setup_tree; unset GITHUB_TOKEN; }

@test "the version is passmcp's latest release" {
  STUB_RELEASE="{\"tag_name\":\"v${VER}\"}" run "${SCRIPTS}/lockstep.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"${VER} matches passmcp's latest release"* ]]
}

@test "a token, when set, is used for the API call" {
  GITHUB_TOKEN=t STUB_RELEASE="{\"tag_name\":\"v${VER}\"}" run "${SCRIPTS}/lockstep.sh"
  [ "$status" -eq 0 ]
}

@test "behind passmcp's latest release fails and says what to run" {
  STUB_RELEASE='{"tag_name":"v9.9.9"}' run "${SCRIPTS}/lockstep.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"at ${VER} and passmcp's latest release is 9.9.9; run the sync workflow"* ]]
}

@test "a CHANGELOG with no released heading fails" {
  printf '# Changelog\n\n## [Unreleased]\n' >"${TREE}/CHANGELOG.md"
  run "${SCRIPTS}/lockstep.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no released version heading"* ]]
}
