#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

load helpers

setup() { setup_tree; }

@test "prints the image action.yml pins by digest" {
  run "${SCRIPTS}/pinned-image.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "ghcr.io/sebastienrousseau/passmcp@$(pinned_digest)" ]
}

@test "an image pinned by tag is refused" {
  edit action.yml "passmcp@$(pinned_digest)" "passmcp:latest"
  run "${SCRIPTS}/pinned-image.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"pins no image by digest"* ]]
}

@test "a digest that is not 64 hex characters is refused" {
  edit action.yml "passmcp@$(pinned_digest)" "passmcp@sha256:abc123"
  run "${SCRIPTS}/pinned-image.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"pins no image by digest"* ]]
}
