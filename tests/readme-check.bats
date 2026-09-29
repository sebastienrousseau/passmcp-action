#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

load helpers

setup() { setup_tree; }

@test "the README follows the template" {
  run "${SCRIPTS}/readme-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"follows the template (passmcp-action)"* ]]
}

@test "a missing README fails" {
  run "${SCRIPTS}/readme-check.sh" nowhere.md
  [ "$status" -eq 1 ]
  [[ "$output" == *"nowhere.md not found"* ]]
}

@test "a README without the centred h1 fails" {
  edit README.md '<h1 align="center">passmcp-action</h1>' '# passmcp-action'
  run "${SCRIPTS}/readme-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no centred plain-text"* ]]
}

@test "headings out of the template's order fail" {
  edit README.md "## Benchmarks" "## Numbers"
  run "${SCRIPTS}/readme-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"second-level headings differ from the template"* ]]
}

@test "an unresolved template variable fails" {
  printf '\nSee {{API_DOCS_URL}}.\n' >>"${TREE}/README.md"
  run "${SCRIPTS}/readme-check.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unresolved template variables: {{API_DOCS_URL}}"* ]]
}

@test "a variable inside inline code is content, not a token" {
  printf '\nThe template writes \x60{{API_DOCS_URL}}\x60.\n' >>"${TREE}/README.md"
  run "${SCRIPTS}/readme-check.sh"
  [ "$status" -eq 0 ]
}
