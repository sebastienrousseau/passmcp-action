<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Development

The single entry point for working on passmcp-action: toolchain, how to
reproduce every CI gate locally, and how a release is cut.

## Requirements

What the action needs where it runs, and what CI proves:

| Requirement | Enforced by |
|---|---|
| A Linux runner with Docker | CI's smoke job runs the action on `ubuntu-latest` |
| `jq` on the runner | the same smoke job; `ubuntu-latest` has it |
| Network from the runner to ghcr.io and the server | the smoke job pulls the pinned image |

There is no version floor to state: the action pins no Docker, bash or
`jq` version, and is not tested on anything but GitHub's `ubuntu-latest`
and the image's `linux/amd64` and `linux/arm64` builds. macOS and Windows
hosted runners cannot run Linux containers, so they are unsupported.

## Toolchain

| Tool | Why |
|---|---|
| `actionlint` (`go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7` works) | `make lint`: action.yml and every workflow, shellcheck included |
| `shellcheck` | `make lint`: the scripts and the test suite |
| `bats` | `make unit`: the test suite |
| Ruby 3.3 and Bundler, with `tests/Gemfile.lock` | `make coverage`: bashcov and SimpleCov |
| `jq`, `perl`, `git` | `make coverage` reads the total; the tests edit and index fixture trees |
| `docker` | `make smoke`: runs the pinned image |
| `curl`, `python3` | `make digest`, `make lockstep`, `make family` |
| `markdownlint-cli2`, `codespell`, `lychee` | the Docs Lint workflow and `pre-commit` |

## Reproducing every CI gate

| CI job | Local command |
|---|---|
| Lint | `make lint spdx-check name-guard versions` |
| Unit tests and coverage | `make coverage` (or `make unit` without bashcov) |
| The pinned image runs | `make smoke` |
| Repository Checks | `make digest family lockstep` |
| Markdown & Spelling | `make readme-check`, `markdownlint-cli2 '**/*.md'` and `codespell` |
| Link Check | `lychee --offline --include-fragments '**/*.md'` |
| Manual | `mkdocs build --strict` with `docs/requirements.txt` |
| OpenSSF Scorecard | none: it reads the repository's settings on GitHub |
| DCO check | `git log --format=%B origin/main.. \| grep Signed-off-by` |

`make all` runs every local gate in one go.

The smoke job in CI additionally runs the action against itself
(`uses: ./`) with `command: version`, and a `check` with no endpoint that
must be refused. Both need a runner; locally, `make smoke` is the first.

## Coverage

The code this repository owns is the shell in `scripts/`. `tests/` holds a
bats suite with a file per script: each test copies the files a script
reads into its own temporary directory, runs the real script against it
through `PASSMCP_ACTION_ROOT`, and puts `tests/bin/curl`, a stub, first on
`PATH`, so no test touches the network.

```bash
BUNDLE_GEMFILE=tests/Gemfile bundle install
BUNDLE_GEMFILE=tests/Gemfile make coverage BASHCOV="bundle exec bashcov"
```

`make coverage` runs the suite under bashcov (tracing only the scripts;
see [ADR 0004](docs/adr/0004-coverage-traces-the-scripts-not-bats.md)),
prints the line total, writes `coverage/badge.json` and fails below 85%,
the family's floor (`COVERAGE_MIN` overrides it). The number is line
coverage of `scripts/*.sh`; it is not branch coverage, and the shell
inside `action.yml` is covered by CI's smoke job instead.

The manual workflow runs the same target and publishes the file as
<https://sebastienrousseau.com/passmcp-action/coverage.json>, the
shields.io endpoint the README's coverage badge reads.

## How the pieces fit

| File | What it is |
|---|---|
| `action.yml` | The composite action: inputs, outputs, the `docker run` |
| `templates/passmcp.gitlab-ci.yml` | The GitLab job, pinning the same image |
| `scripts/pinned-image.sh` | Reads the one digest from `action.yml`; everything else asks it |
| `scripts/verify-digest.sh` | That digest is the image ghcr.io tags for `CHANGELOG.md`'s version, in both places |
| `scripts/lockstep.sh` | `CHANGELOG.md`'s version is passmcp's latest release |
| `scripts/family.sh` | This repository's row in passmcp's `ecosystem.json` is true |
| `scripts/verify-release-versions.sh` | Every version-bearing place names the CHANGELOG version |
| `scripts/coverage-badge.sh` | Writes the coverage endpoint file and enforces the floor |
| `tests/` | The bats suite, the curl stub, and `traced.sh` for coverage |
| `.github/workflows/manual.yml` | Builds the manual and `coverage.json`, deploys both to Pages |
| `.github/workflows/scorecard.yml` | OpenSSF Scorecard, weekly and on push to `main` |
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
   workflows. A dispatch runs on `main`. When a `feat/vX.Y.Z` branch has
   already opened the undated `## [X.Y.Z]` section, run the sync on that
   branch instead (`gh workflow run sync.yml --ref feat/vX.Y.Z -f
   version=vX.Y.Z`): it pins the digest, dates the section, and opens its
   pull request against that branch.
2. Add `docs/releases/vX.Y.Z.md`, the hand-written highlights, to that
   pull request; until it exists `make versions` keeps the pull request
   red. The sync workflow has already moved the snippets, the README's
   ecosystem sentence and `CITATION.cff`.
3. Review and merge the pull request. CI's `make digest`,
   `make lockstep` and `make versions` are the review.
4. Push a signed annotated tag `vX.Y.Z` with the message
   `passmcp-action vX.Y.Z`. The release workflow publishes the changelog
   section as the notes and moves `v0` to it.
5. Read the tag, the release page and the `v0` tag back before calling it
   done.

## Conventions

- Every input maps to a flag `passmcp check` already has.
- Shell in `action.yml` runs under `set -euo pipefail` and is linted by
  actionlint's shellcheck pass.
