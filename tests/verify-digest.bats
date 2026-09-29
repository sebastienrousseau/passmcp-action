#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

load helpers

setup() { setup_tree; export STUB_DIGEST; STUB_DIGEST="$(pinned_digest)"; }

@test "the pinned digest is the one ghcr.io tags for the version" {
  run "${SCRIPTS}/verify-digest.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pin the image ghcr.io tags ${VER}"* ]]
}

@test "a digest ghcr.io does not tag for the version fails" {
  STUB_DIGEST="sha256:$(printf '0%.0s' {1..64})"
  run "${SCRIPTS}/verify-digest.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"action.yml pins $(pinned_digest) and ghcr.io tags ${VER} as sha256:000"* ]]
}

@test "a GitLab template pinning something else fails" {
  edit templates/passmcp.gitlab-ci.yml "passmcp@$(pinned_digest)" "passmcp:0.0.1"
  run "${SCRIPTS}/verify-digest.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"templates/passmcp.gitlab-ci.yml pins ghcr.io/sebastienrousseau/passmcp:0.0.1"* ]]
}

@test "a version ghcr.io has no image for fails" {
  STUB_DIGEST=""
  run "${SCRIPTS}/verify-digest.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ghcr.io has no image tagged ${VER}"* ]]
}

@test "a version ghcr.io answers 404 for fails and names the version" {
  STUB_FAIL="/manifests/" run "${SCRIPTS}/verify-digest.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ghcr.io has no image tagged ${VER}; the manifest request failed"* ]]
}

@test "a refused registry token fails the check" {
  STUB_FAIL="ghcr.io/token" run "${SCRIPTS}/verify-digest.sh"
  [ "$status" -eq 22 ]
}

@test "a CHANGELOG with no released heading fails and says so" {
  printf '# Changelog\n\n## [Unreleased]\n' >"${TREE}/CHANGELOG.md"
  run "${SCRIPTS}/verify-digest.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no released version heading"* ]]
}
