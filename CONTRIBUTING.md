<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Contributing

passmcp-action is a composite GitHub Action and a GitLab template. There is
no code to build; there is YAML and shell to keep correct, and one image
digest to keep honest.

## Getting started

1. Fork and clone the repository.
2. Install `actionlint`, `shellcheck`, `docker`, `curl` and `python3`.
3. Create a branch from `main` and open the pull request against `main`.
4. Make the change.
5. Verify:

   ```bash
   make            # actionlint, shellcheck, headers, digest, lockstep, family, a run of the pinned image
   ```

## Commits

**Sign your commits cryptographically and add a DCO sign-off trailer.**
Both are required and both are enforced (`git commit -s -S`). Merge
commits are exempt from the DCO check.

Use [Conventional Commits](https://www.conventionalcommits.org/) with an
imperative subject.

## What a change needs

- **A changed input or output is documented in README.md** in the same
  pull request, with the example that shows it.
- **The digest is not touched by hand.** `action.yml` and the GitLab
  template pin the image of the version in `CHANGELOG.md`; the sync
  workflow moves both on a passmcp release. A pull request that moves the
  digest to any other image is declined.
- **An entry under `## [Unreleased]` in `CHANGELOG.md`.**
- **No `curl | sh`, no unpinned action.** Everything the action runs is
  the pinned image or an action pinned by commit SHA.

## Pull request checklist

- [ ] `make` passes
- [ ] README.md documents any changed input or output
- [ ] `CHANGELOG.md` has an entry under `## [Unreleased]`
- [ ] Commits are signed and carry a DCO sign-off
