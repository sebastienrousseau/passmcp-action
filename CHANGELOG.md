<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Changelog

All notable changes to passmcp-action are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
versions are [Semantic Versioning](https://semver.org/) shaped.

**This repository carries passmcp's version.** It is in lockstep with
[passmcp](https://github.com/sebastienrousseau/passmcp): every passmcp release
is a release here, pinning that release's image by digest, and a release
here with nothing else in it is the version rule working. The sync
workflow opens the section on passmcp's release dispatch; passmcp's own
changelog says what changed in the diagnostic.

## [Unreleased]

## [0.0.4] — 2026-09-30

### Added

- **A README demo**, rendered from `.github/demo.tape` by `make demo`: the
  action's own run step checking a local example server in the pinned
  passmcp image, failing the step, and the outputs and report files it
  leaves.

### Changed

- **In lockstep with passmcp 0.0.4.** The action and the GitLab template pin `ghcr.io/sebastienrousseau/passmcp@sha256:a619e709cddc568394e7bf3b700f9ca44d925c658087c882d5a077ad65cdfdc7`, the multi-arch image passmcp's release published for 0.0.4. Written by the sync workflow for passmcp's release; passmcp's own changelog says what changed in the diagnostic.
- **Release pages are published in the family layout** by the release
  workflow itself (Highlights, What's Changed, Checksums, Full Changelog),
  so no page is rewritten by hand after a release.

## [0.0.3] — 2026-09-30

### Changed

- **In lockstep with passmcp 0.0.3.** The action and the GitLab template pin `ghcr.io/sebastienrousseau/passmcp@sha256:88668e403cb4fe2e63032e9d69550acb59a449701d1f2ab1b52d436e96806dad`, the multi-arch image passmcp's release published for 0.0.3. Written by the sync workflow for passmcp's release; passmcp's own changelog says what changed in the diagnostic.
- **Only the version moves.** Nothing in the action, the GitLab
  template or the scripts changed since 0.0.2. This section is opened on
  the release branch ahead of passmcp 0.0.3; the sync workflow dates it
  and adds the pinned image when that release dispatches.

### Fixed

- **The sync workflow keeps a release to one pull request.** On
  passmcp's release dispatch it opened its own pull request into `main`,
  beside the release branch's. When `feat/vX.Y.Z` exists it now commits
  the pins onto that branch instead, and opens a pull request only when
  there is no release branch.

## [0.0.2] — 2026-09-29

### Added

- **Unit tests for every script.** A bats suite runs each script in
  `scripts/` against a copy of the tree, with curl stubbed so no test
  touches the network; `make unit` runs it and `make coverage` runs it
  under bashcov, failing below 85% line coverage.
- **A coverage badge** from a shields.io endpoint file, `coverage.json`,
  published with the manual on GitHub Pages.
- **The OpenSSF Scorecard workflow**, publishing results weekly and on
  every push to `main`.

### Changed

- **In lockstep with passmcp 0.0.2.** The action and the GitLab template pin `ghcr.io/sebastienrousseau/passmcp@sha256:fb15e3a3ff2bc2270ce308778ead54da3f10bd0f8160aaab4a06a60a2da6bbdb`, the multi-arch image passmcp's release published for 0.0.2. Opened by the sync workflow on the release's dispatch; passmcp's own changelog says what changed in the diagnostic.
- **The README follows the family standard**: seven badges in one format,
  the family's ecosystem table with every component linked, and concrete
  release statuses in place of "Stable" and "planned".
- **`scripts/verify-release-versions.sh` checks every version-bearing
  place**: the snippets, the README's ecosystem sentence, `CITATION.cff`
  and the release highlights name the version, and every "Released in"
  status names a released one. CI runs it on every push, not only on a
  tag.
- **The sync workflow also moves the ecosystem sentence and
  `CITATION.cff`** to the new version, dates a `## [x.y.z]` section
  prepared on the release branch instead of skipping it, and opens its
  pull request against the branch it ran on.
- **`scripts/family.sh` accepts the family standard's `released` status**
  as well as the `shipping` that passmcp's manifest carried before its
  schema version 2.
- `ARCHITECTURE.md` moved to `docs/ARCHITECTURE.md`, into the manual.

### Fixed

- **The sync workflow's changelog step needs an `## [Unreleased]`
  heading** and this file had none, so the next passmcp release would
  have failed the sync. The heading is back, and the version check now
  fails when it is missing.
- **`make digest` names the version ghcr.io has no image for** when the
  registry answers the manifest request with an error, instead of ending
  on curl's exit code.

## [0.0.1] — 2026-09-29

The first release.

### Added

- **passmcp in GitHub Actions and GitLab CI**, run from the image the release
  signed, pinned by digest, with the token never on a command line.

[Unreleased]: https://github.com/sebastienrousseau/passmcp-action/compare/v0.0.4...HEAD
[0.0.4]: https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.4
[0.0.3]: https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.3
[0.0.2]: https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.2
[0.0.1]: https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1
