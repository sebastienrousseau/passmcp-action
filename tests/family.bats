#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

load helpers

setup() { setup_tree; }

row() {
  printf '{"repositories":[{"name":"passmcp-action","status":"%s","license":"%s","language":"%s","lockstep":%s}]}' "$@"
}

@test "the legacy shipping status passes without a warning" {
  STUB_MANIFEST="$(row shipping Apache-2.0 composite true)" run "${SCRIPTS}/family.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"is true of this tree (Apache-2.0, composite, lockstep=true, shipping)"* ]]
  [[ "$output" != *"::warning::"* ]]
}

@test "the family standard's released status passes without a warning" {
  STUB_MANIFEST="$(row released Apache-2.0 composite true)" run "${SCRIPTS}/family.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"is true of this tree (Apache-2.0, composite, lockstep=true, released)"* ]]
  [[ "$output" != *"::warning::"* ]]
}

@test "a licence the tree does not hold fails" {
  STUB_MANIFEST="$(row shipping MIT composite true)" run "${SCRIPTS}/family.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"the manifest says MIT and LICENSES/ holds Apache-2.0"* ]]
}

@test "a language other than composite fails" {
  STUB_MANIFEST="$(row shipping Apache-2.0 go true)" run "${SCRIPTS}/family.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"the manifest says go"* ]]
}

@test "a row that is not lockstep fails" {
  STUB_MANIFEST="$(row shipping Apache-2.0 composite false)" run "${SCRIPTS}/family.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"lockstep=false"* ]]
}

@test "a status other than released or shipping is a warning, not a failure" {
  STUB_MANIFEST="$(row unreleased Apache-2.0 composite true)" run "${SCRIPTS}/family.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"::warning::family: the manifest still lists passmcp-action as unreleased"* ]]
}

@test "a manifest with no row for this repository fails" {
  STUB_MANIFEST='{"repositories":[]}' run "${SCRIPTS}/family.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"has no row in the family manifest"* ]]
}
