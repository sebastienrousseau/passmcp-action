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

## [0.0.1] — Unreleased

The first release.

### Added

- **passmcp in GitHub Actions and GitLab CI**, run from the image the release
  signed, pinned by digest, with the token never on a command line.
