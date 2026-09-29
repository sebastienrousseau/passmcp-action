#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

load helpers

setup() { cd "${BATS_TEST_TMPDIR}" || return 1; unset COVERAGE_MIN; }

badge() { cat "${BATS_TEST_TMPDIR}/coverage.json"; }

@test "90 and above is brightgreen" {
  run "${SCRIPTS}/coverage-badge.sh" 93.456
  [ "$status" -eq 0 ]
  [ "$(badge)" = '{"schemaVersion":1,"label":"coverage","message":"93.5%","color":"brightgreen"}' ]
}

@test "85 up to 90 is green" {
  run "${SCRIPTS}/coverage-badge.sh" 85
  [ "$status" -eq 0 ]
  [[ "$(badge)" == *'"message":"85.0%","color":"green"'* ]]
}

@test "below the floor is written and fails" {
  run "${SCRIPTS}/coverage-badge.sh" 72.1
  [ "$status" -eq 1 ]
  [[ "$(badge)" == *'"message":"72.1%","color":"yellow"'* ]]
  [[ "$output" == *"below the 85% floor"* ]]
}

@test "below 70 is red" {
  COVERAGE_MIN=0 run "${SCRIPTS}/coverage-badge.sh" 12
  [ "$status" -eq 0 ]
  [[ "$(badge)" == *'"color":"red"'* ]]
}

@test "the output path is the second argument" {
  run "${SCRIPTS}/coverage-badge.sh" 100 "${BATS_TEST_TMPDIR}/out.json"
  [ "$status" -eq 0 ]
  grep -q '"message":"100.0%"' "${BATS_TEST_TMPDIR}/out.json"
}

@test "a percentage that is not a number is a usage error" {
  run "${SCRIPTS}/coverage-badge.sh" lots
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage:"* ]]
}

@test "a floor that is not a number is refused" {
  COVERAGE_MIN=high run "${SCRIPTS}/coverage-badge.sh" 90
  [ "$status" -eq 2 ]
  [[ "$output" == *"COVERAGE_MIN must be a number"* ]]
}
