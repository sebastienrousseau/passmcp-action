<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# 0001 — The action runs the published image by digest, and nothing else

**Status:** Accepted · **Date:** 2026-09-23

## Context

An action can run passmcp three ways: download the release binary, `go
install` it, or run the container image. Each is a supply-chain claim.
The binary and the image are both signed by passmcp's release workflow; `go
install …@latest` resolves to whatever the module proxy holds today and
is signed by nobody. Offering all three means three code paths to keep
correct and three answers to "what ran".

## Decision

**The action runs `ghcr.io/sebastienrousseau/passmcp` pinned by digest, and
that is the only way it runs passmcp.** The digest is the multi-arch
manifest of the passmcp release this action is in lockstep with, and
`scripts/verify-digest.sh` fails CI when it is not. The GitLab template
pins the same digest. The sync workflow moves both on passmcp's release
dispatch; nothing else does.

## Consequences

- One artefact, one digest, one check. What ran in a workflow is what the
  release signed, and a reader can prove it from `action.yml` alone.
- No `--stdio`: the image holds only passmcp, so a server that is a
  program cannot run inside it. That case is documented as out of scope
  and pointed at passmcp's CI guide, rather than half-supported here.
- No macOS or Windows runners. The same pointer.
- An `image` input exists for the operator who has mirrored the image
  into a private registry. Using it is stated to mean the release's
  signature no longer covers what runs.

## What would make this wrong

A hosted runner without Docker becoming the default, or passmcp shipping a
second signed artefact the Marketplace can run natively. Then the binary
path is worth adding — with its own digest check, not instead of this one.
