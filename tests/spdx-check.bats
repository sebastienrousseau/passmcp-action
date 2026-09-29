#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

load helpers

# Assembled at run time so the REUSE linter does not read these fixtures'
# headers as this file's own licence expression.
tag="SPDX-License-Identifier"

setup() {
  TREE="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${TREE}/LICENSES"
  git -C "${TREE}" init -q
  printf '# %s: Apache-2.0\necho hi\n' "${tag}" >"${TREE}/ok.sh"
  printf 'licence text\n' >"${TREE}/LICENSE"
  printf 'licence text\n' >"${TREE}/LICENSES/Apache-2.0.txt"
  printf 'x/\n' >"${TREE}/.gitignore"
  git -C "${TREE}" add -A
  export PASSMCP_ACTION_ROOT="${TREE}"
}

@test "every tracked file with a header, or covered by REUSE.toml, passes" {
  run "${SCRIPTS}/spdx-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"every source file carries a licence header"* ]]
}

@test "a tracked file without a header fails and is named" {
  printf 'no header\n' >"${TREE}/bare.txt"
  git -C "${TREE}" add bare.txt
  run "${SCRIPTS}/spdx-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no licence header: bare.txt"* ]]
}

@test "a header below line five does not count" {
  printf '1\n2\n3\n4\n5\n# %s: Apache-2.0\n' "${tag}" >"${TREE}/late.sh"
  git -C "${TREE}" add late.sh
  run "${SCRIPTS}/spdx-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"late.sh"* ]]
}
