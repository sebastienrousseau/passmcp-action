#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

load helpers

setup() {
  cd "${BATS_TEST_TMPDIR}" || return 1
  git init -q
  printf 'passmcp\n' >README.md
  git add README.md
}

@test "a tree without the retired name is clean" {
  run "${SCRIPTS}/name-guard.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "name-guard: clean" ]
}

@test "the retired name in a tracked file fails, whatever its case" {
  # Assembled at run time so this file does not trip the guard itself.
  printf 'run %s here\n' "SC""OUT" >notes.md
  git add notes.md
  run "${SCRIPTS}/name-guard.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"notes.md:1:"* ]]
  [[ "$output" == *"1 occurrence(s)"* ]]
}

@test "go.sum files are exempt" {
  printf 'example.com/%s v1\n' "sc""out" >go.sum
  git add go.sum
  run "${SCRIPTS}/name-guard.sh"
  [ "$status" -eq 0 ]
}
