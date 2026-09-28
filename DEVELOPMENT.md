<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Development

The single entry point for working on passmcp-action: toolchain, how to
reproduce every CI gate locally, and how a release is cut.

## Toolchain

| Tool | Why |
|---|---|
| `actionlint` (`go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7` works) | `make lint`: action.yml and every workflow, shellcheck included |
| `shellcheck` | `make lint`: the scripts |
| `docker` | `make test`: runs the pinned image |
| `curl`, `python3` | `make digest`, `make lockstep`, `make family` |
| `markdownlint-cli2`, `codespell`, `lychee` | the Docs Lint workflow and `pre-commit` |

## Reproducing every CI gate

| CI job | Local command |
|---|---|
| Lint | `make lint spdx-check` |
| The pinned image runs | `make test` |
| Repository Checks | `make digest family lockstep` |
| Markdown & Spelling | `markdownlint-cli2 '**/*.md'` and `codespell` |
| Link Check | `lychee --offline --include-fragments '**/*.md'` |
| DCO check | `git log --format=%B origin/main.. \| grep Signed-off-by` |

The smoke job in CI additionally runs the action against itself
(`uses: ./`) with `command: version`, and a `check` with no endpoint that
must be refused. Both need a runner; locally, `make test` is the first.

## How the pieces fit

| File | What it is |
|---|---|
| `action.yml` | The composite action: inputs, outputs, the `docker run` |
| `templates/passmcp.gitlab-ci.yml` | The GitLab job, pinning the same image |
| `scripts/pinned-image.sh` | Reads the one digest from `action.yml`; everything else asks it |
| `scripts/verify-digest.sh` | That digest is the image ghcr.io tags for `CHANGELOG.md`'s version, in both places |
| `scripts/lockstep.sh` | `CHANGELOG.md`'s version is passmcp's latest release |
| `scripts/family.sh` | This repository's row in passmcp's `ecosystem.json` is true |
| `.github/workflows/sync.yml` | On passmcp's release dispatch: pin the new digest, open the changelog section, raise the pull request |
| `.github/workflows/release.yml` | On a tag: publish the notes, move the `v0` tag |

## Release model

The version is passmcp's. A release here follows a passmcp release:

1. passmcp's release workflow fires `repository_dispatch` (`passmcp-release`)
   with the version and the image digest. The sync workflow opens a pull
   request pinning it. (Or run the sync workflow by hand with the
   version.) With a `SYNC_TOKEN` secret, a fine-grained token with
   `pull-requests: write` on this repository, the pull request's checks
   start on their own; without it, close and reopen the pull request to
   start them, because one opened with `GITHUB_TOKEN` triggers no
   workflows.
2. Review and merge the pull request. CI's `make digest` and
   `make lockstep` are the review.
3. Push a signed annotated tag `vX.Y.Z` with the message
   `passmcp-action vX.Y.Z`. The release workflow publishes the changelog
   section as the notes and moves `v0` to it.
4. Read the tag, the release page and the `v0` tag back before calling it
   done.

## Conventions

- Every input maps to a flag `passmcp check` already has.
- Shell in `action.yml` runs under `set -euo pipefail` and is linted by
  actionlint's shellcheck pass.
