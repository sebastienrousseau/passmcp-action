<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Architecture Decision Records

Decisions about this repository that will be questioned later. Records
are immutable once merged; a decision that changes gets a new record.

| # | Decision | Status |
|---|---|---|
| [0001](0001-the-image-by-digest-and-nothing-else.md) | The action runs the published image by digest, and offers no other way to run passmcp | Accepted |
| [0002](0002-the-token-through-the-environment.md) | The token reaches passmcp through the environment, never as an argument | Accepted |
| [0003](0003-the-version-is-passmcps.md) | The version is passmcp's, and moves only with a passmcp release | Accepted |
| [0004](0004-coverage-traces-the-scripts-not-bats.md) | Coverage traces the scripts, not the test runner | Accepted |
