<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Governance

passmcp-action is one repository in the passmcp family and is governed the
way passmcp is. This document says what is specific to this repository and
points at passmcp's for the rest.

## Roles

**Maintainer:** Sebastien Rousseau (<sebastian.rousseau@gmail.com>,
GitHub `@sebastienrousseau`), with commit access, responsible for the
action's inputs and outputs, its releases and its security response.

**Contributor:** anyone who opens an issue or a pull request. Mechanics
are in [CONTRIBUTING.md](CONTRIBUTING.md).

## What is decided here, and what is not

This repository decides **the wrapper**: inputs, outputs, what fails a
job, and how the report reaches the run page and the artifact store. It
does not decide what passmcp checks or how it scores; those are passmcp's,
and a change there arrives here as a new pinned image.

## Version and release

The version is passmcp's. This repository never chooses its own: the sync
workflow opens a release's pull request on passmcp's dispatch, and
`scripts/lockstep.sh` refuses anything else. Releases are signed tags,
cut by the Maintainer; the release workflow moves the `v0` major tag.

## Continuity

The single-Maintainer model is a real bus-factor risk, stated rather than
hidden. The succession procedure is passmcp's, in
[passmcp's GOVERNANCE.md](https://github.com/sebastienrousseau/passmcp/blob/main/GOVERNANCE.md),
and applies to this repository as one of the family.

## Changes to this document

Through the usual pull request process.
