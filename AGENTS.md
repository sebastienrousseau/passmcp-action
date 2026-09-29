<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Working on passmcp-action as an AI agent

Invariants for AI-assisted contributions. Read
[DEVELOPMENT.md](DEVELOPMENT.md) for the local form of every CI gate.

## Hard gates

| Gate | Command |
|---|---|
| actionlint and shellcheck at zero findings | `make lint` |
| SPDX header on every file | `make spdx-check` |
| Every version-bearing place names one version | `make versions` |
| A test for every script behaviour, 85% line coverage | `make coverage` |
| The pinned digest is the image of this version | `make digest` |
| The version is passmcp's latest release | `make lockstep` |
| The family manifest's row is true | `make family` |
| The unit suite passes and the pinned image runs | `make test` |
| The retired name appears nowhere | `make name-guard` |

Tests never reach the network: extend `tests/bin/curl` with the answer a
new request needs. Keep heredoc bodies and multi-line `$(...)` out of the
scripts; bashcov counts those lines and cannot see them run
([ADR 0004](docs/adr/0004-coverage-traces-the-scripts-not-bats.md)).

## Commits

- **Every commit must be cryptographically signed and carry a DCO
  `Signed-off-by` trailer.** Hand commits over as a script rather than
  producing unsigned history.
- Conventional Commits for the subject line.
- Never rewrite published history.

## Versioning

- **The version is passmcp's.** Never choose one here. It lives in the
  newest `## [x.y.z]` heading in `CHANGELOG.md`.
- **The digest follows the version.** `action.yml` and the GitLab
  template pin the multi-arch image ghcr.io tags for that version. The
  sync workflow moves both; a hand edit is the bug.

## Things that look like bugs and are not

- **The token goes through the environment.** `-e MCP_TOKEN` and
  `--token-env MCP_TOKEN`, never `--token "$X"`. A value that is an
  argument is in `ps`, in a shell trace and in the step log.
- **Exit 2 is a result, not a failure of the action.** It means a check
  failed or the policy was not met; `fail-on` decides what the job does
  with it. Do not map it to exit 1.
- **The container runs as the runner's user, with `HOME=/tmp`.** The
  image's own user (uid 65532) cannot write into a workspace the runner
  owns, and that user has no home inside the image; both are why.
- **The smoke test runs `passmcp version`, not a check.** There is no
  consented server to run a check against in CI; proving the digest
  pulls and the binary answers is what can be proved.

## Things that are load-bearing

- **Pinned by digest, never by tag.** A tag can move under the action; a
  digest is what makes "this ran what the release signed" true.
- **Every input is a flag passmcp already has.** The action adds no
  behaviour of its own. A capability passmcp lacks is a change to passmcp.
- **Read-only unless the caller says otherwise, through `args`.**

## Scope

- Do not add a CI gate that does not currently pass.
- Do not add a second way to run passmcp (a binary download, a `go
  install`) beside the image. One artefact, one digest, one check.
