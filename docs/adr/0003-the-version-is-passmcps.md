<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# 0003 — The version is passmcp's, and moves only with a passmcp release

**Status:** Accepted · **Recorded:** 2026-09-29 · in force since 0.0.1

## Context

The action is a wrapper over one artefact: passmcp's release image. A
version of its own would need a mapping table from action versions to
passmcp versions, and every reader would have to consult it to know what
ran.

## Decision

**This repository carries passmcp's version, in lockstep with the family.**
The newest `## [x.y.z]` heading in `CHANGELOG.md` is the version, and it
is always passmcp's latest release. passmcp's release workflow dispatches
to this repository; the sync workflow pins that release's image by digest,
opens the changelog section and raises the pull request that is the
release. `scripts/lockstep.sh` fails CI when the version is behind passmcp,
and `scripts/verify-release-versions.sh` fails it when any place in the
tree names another version.

## Consequences

- `passmcp-action@v0.0.1` runs passmcp 0.0.1, and nothing needs to say so
  twice.
- A release here can contain nothing but a new pin. That is the rule
  working, not an empty release.
- A fix to the wrapper alone waits for the next passmcp release, or goes
  out with it; there is no action-only version number to spend.
