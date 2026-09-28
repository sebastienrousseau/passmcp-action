<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

<p align="center">
  <img src="https://raw.githubusercontent.com/sebastienrousseau/passmcp/main/.github/logo.svg" alt="passmcp-action logo" width="128" />
</p>

<h1 align="center">passmcp-action</h1>

<p align="center">
  Run passmcp, the Model Context Protocol server diagnostic, in GitHub Actions or GitLab CI — from the image the release signed, pinned by digest, with the token never on a command line.
</p>

<p align="center">
  <a href="https://github.com/sebastienrousseau/passmcp-action/actions"><img src="https://img.shields.io/github/actions/workflow/status/sebastienrousseau/passmcp-action/ci.yml?style=for-the-badge&logo=github" alt="Build Status" /></a>
  <a href="https://github.com/marketplace/actions/passmcp-server-server-diagnostic"><img src="https://img.shields.io/badge/marketplace-passmcp-fc8d62?style=for-the-badge&logo=github" alt="GitHub Marketplace" /></a>
  <a href="https://satellion.com/passmcp/docs/ci/"><img src="https://img.shields.io/badge/docs-CI%20guide-brightgreen?style=for-the-badge&logo=github" alt="Documentation" /></a>
  <a href="https://scorecard.dev/viewer/?uri=satellion.com/passmcp-action"><img src="https://img.shields.io/ossf-scorecard/satellion.com/passmcp-action?style=for-the-badge&label=OpenSSF%20Scorecard&logo=openssf" alt="OpenSSF Scorecard" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache--2.0-blue?style=for-the-badge" alt="License: Apache-2.0" /></a>
  <a href="#requirements"><img src="https://img.shields.io/badge/runner-ubuntu%20%2B%20docker-93450a.svg?style=for-the-badge&logo=docker&logoColor=white" alt="Runs on a Linux runner with Docker" /></a>
</p>

---

## Contents

**Getting started**

- [Install](#install) — one `uses:` line, or one `include:` for GitLab
- [Requirements](#requirements) — a Linux runner with Docker, a reachable server
- [Quick Start](#quick-start) — diagnose a server on a schedule

**The passmcp-action ecosystem**

- [The passmcp-action ecosystem](#the-passmcp-action-ecosystem) — `passmcp`, `passmcp-reporting`, `passmcp-action`, `passmcp-server`, `passmcp-lsp`, `passmcp-census` at a glance

**Reference**

- [Capabilities at a glance](#capabilities-at-a-glance) — every input and output
- [Ecosystem comparison](#ecosystem-comparison) — beside installing passmcp yourself
- [Benchmarks](#benchmarks) — what the wrapper adds to a run
- [Features](#features) — the token, the digest, the exit codes, the evidence
- [Configuration](#configuration) — inputs, in detail
- [Examples](#examples) — runnable workflow index

**Operational**

- [When not to use passmcp-action](#when-not-to-use-passmcp-action) — limitations
- [Development](#development) — make targets, CI
- [Security](#security) — what is pinned and what is never logged
- [Documentation](#documentation) — all reference docs
- [Stability guarantees](#stability-guarantees) — inputs, outputs and exit codes
- [License](#license)

---

## Install

### As a GitHub Action

```yaml
- uses: sebastienrousseau/passmcp-action@v0.0.1
  with:
    endpoint: https://mcp.example.com/mcp
    token: ${{ secrets.MCP_TOKEN }}
```

Pin the exact version, as above, or follow the major tag `v0`, which the
release workflow moves to every release.

### In GitLab CI

```yaml
include:
  - remote: https://raw.githubusercontent.com/sebastienrousseau/passmcp-action/v0.0.1/templates/passmcp.gitlab-ci.yml

variables:
  MCP_ENDPOINT: https://mcp.example.com/mcp
```

with `MCP_TOKEN` as a masked, protected CI/CD variable. The template's
[source](templates/passmcp.gitlab-ci.yml) pins the same image the action does.

---

## Requirements

| Requirement | Why |
|---|---|
| A Linux runner with Docker (`ubuntu-latest` has it) | the action runs the published image; there is no binary download and no `go install` |
| Network from the runner to the server | passmcp talks to the server; it uploads nothing anywhere else |
| `jq` on the runner (`ubuntu-latest` has it) | reads the score out of `report.json` for the outputs |

The image is `ghcr.io/sebastienrousseau/passmcp` pinned by digest, and the
digest is the one ghcr.io tags for the passmcp version this action is in
lockstep with; `make digest` in CI fails when it is not.

---

## Quick Start

```yaml
name: MCP server diagnostic

on:
  schedule:
    - cron: "17 6 * * *"
  workflow_dispatch:

permissions:
  contents: read

jobs:
  passmcp:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: sebastienrousseau/passmcp-action@v0.0.1
        with:
          endpoint: https://mcp.example.com/mcp
          token: ${{ secrets.MCP_TOKEN }}
```

That runs all nine phases at passmcp's default pacing, writes the Markdown
report to the run's summary page, keeps `report.{txt,md,json}`,
`report.sarif` and the redacted telemetry as an artifact named
`passmcp-report` whether the job passed or failed, and fails the job when a
check fails. The token goes to the container through the environment and
passmcp reads it with `--token-env`, so it is never an argument and never in
a log.

---

## The passmcp-action ecosystem

One engine, three surfaces, five satellites. This repository is the
cheapest verifiable traction signal in the family: GitHub publishes how
many workflows use an action.

| Component | Purpose | Use case |
| :--- | :--- | :--- |
| [`passmcp`](https://github.com/sebastienrousseau/passmcp) | The engine, every check, and the CLI, TUI and web surfaces (GPL-3.0-only) | Evaluate a server and write the statement |
| [`passmcp-reporting`](https://github.com/sebastienrousseau/passmcp-reporting) | The attestation format, its schema and the offline verifier (Apache-2.0) | Gate on a statement in a gateway, registry or pipeline |
| **`passmcp-action`** | The GitHub Action and GitLab template wrapping the published image by digest (Apache-2.0) | Run passmcp in CI without installing it |
| `passmcp-server` | passmcp's diagnostics as MCP tools (planned) | Evaluate a server from inside an editor |
| `passmcp-lsp` | A language server over MCP artefacts (planned) | Hover a check id for its remediation |
| `passmcp-census` | The published reliability census (planned) | Reproduce the numbers |

The family manifest lives in passmcp at
[`docs/ecosystem.md`](https://github.com/sebastienrousseau/passmcp/blob/main/docs/ecosystem.md);
`make family` checks this repository's row against it. Every lockstep
repository carries passmcp's version: a passmcp release dispatches to this one,
the sync workflow pins the new image, and the pull request it opens is the
release.

---

## Capabilities at a glance

| Area | Capability | Status |
| :--- | :--- | :--- |
| Target | `endpoint`: a Streamable HTTP URL | Stable |
| Credentials | `token`, forwarded through the environment as `MCP_TOKEN` | Stable |
| Gating | `policy`: an acceptance policy file; `fail-on`: `failure`, `error` or `never` | Stable |
| Pacing and everything else | `args`: any flag `passmcp check` takes | Stable |
| Evidence | `report-dir` with `report.{txt,md,json}`, `report.sarif`, `telemetry.{ndjson,har}`; `upload` as an artifact | Stable |
| Where people look | `summary` on the run page; `report.sarif` for code scanning | Stable |
| Attestation | `attest`: the in-toto statement beside the report, to sign in a later step | Stable |
| Outputs | `exit-code`, `score`, `grade`, `report`, `sarif`, `attestation` | Stable |
| Servers that are programs (`--stdio`) | not through the image; see [When not to use](#when-not-to-use-passmcp-action) | Out of scope |

---

## Ecosystem comparison

The alternative is installing passmcp on the runner yourself, which passmcp's
[CI guide](https://satellion.com/passmcp/docs/ci/) shows in full. The action is
that guide with the decisions made: the image instead of `go install`, the
digest instead of `@latest`, the token through the environment, the
evidence kept on failure.

| Approach | What runs | Token handling | Evidence on failure |
| :--- | :---: | :---: | :---: |
| **passmcp-action** | the release's image, by digest | environment, `--token-env` | kept as an artifact |
| `go install …@latest` | whatever `@latest` resolves to today | up to the workflow | up to the workflow |
| A hosted scanner | somebody else's binary, with an account | uploaded | theirs |

---

## Benchmarks

The wrapper adds one image pull and one container start to a run; the run
itself is passmcp's, and passmcp's manual publishes its request budget. On
`ubuntu-latest`, pulling the 15 MB multi-arch image takes a few seconds
the first time and is cached after; starting the container is under a
second. There is no benchmark suite here because there is nothing here to
measure that is not passmcp.

| Scenario | Result | Environment |
| :--- | ---: | :--- |
| Image pull, cold | seconds, network-bound | `ubuntu-latest` |
| Container start | under a second | `ubuntu-latest` |
| The diagnostic | passmcp's own timings, in `report.json` | the target server |

---

## Features

**The token is never an argument.** It reaches the container as
`MCP_TOKEN` and passmcp reads it with `--token-env MCP_TOKEN`, so it appears
in no `ps` listing, no shell trace and no step log, and passmcp redacts it
from every file it writes.

**The digest is checked, not trusted.** `action.yml` names the image by
`sha256`, and CI fails when that digest is not the one ghcr.io tags for
the passmcp version in `CHANGELOG.md`. What runs in your workflow is what
passmcp's release signed with keyless cosign.

**Exit codes mean what passmcp says they mean.** `0` every check passed;
`1` the run could not complete; `2` a check failed or the policy was not
met. `fail-on` decides which of those fails the job; the outputs carry all
of them either way.

**The evidence survives the failure.** The report directory is uploaded
with `if: always()`, because the run you most want the HAR from is the one
that just failed the job.

**Nothing of its own.** Every input is a flag `passmcp check` already has.
A capability the action lacks is a change to passmcp, not to the action.

---

## Configuration

| Input | Default | Meaning |
|---|---|---|
| `endpoint` | — | The server's Streamable HTTP URL. Required for `check` |
| `token` | — | Bearer token, forwarded as `MCP_TOKEN` (`--token-env`). Use a secret |
| `policy` | — | Path of an acceptance policy file, relative to the workspace (`--policy`). With it, exit `2` means the policy was not met |
| `args` | — | Extra flags for `passmcp check`, one string: `--rps 5 --skip-era-check --allow-mutations` |
| `report-dir` | `passmcp-report` | Where the report, the SARIF file and the telemetry go, relative to the workspace |
| `fail-on` | `failure` | `failure`: exit 1 and 2 fail the job. `error`: only exit 1. `never`: the job continues and the outputs say what happened |
| `summary` | `true` | Append `report.md` to the job summary |
| `attest` | `false` | Also write `attestation.json`, the in-toto statement, beside the report |
| `upload` | `true` | Upload `report-dir` as the `passmcp-report` artifact, always |
| `command` | `check` | The passmcp command. `version` is what this repository's CI runs to prove the image |
| `image` | the pinned digest | Override the image. Doing so means you are no longer running what the release signed |

| Output | Meaning |
|---|---|
| `exit-code` | passmcp's exit code |
| `score` | `.score.total` from `report.json`, empty without a report |
| `grade` | `.score.grade` from `report.json` |
| `report` | path of `report.json` |
| `sarif` | path of `report.sarif`, for `github/codeql-action/upload-sarif` |
| `attestation` | path of `attestation.json` when `attest` was `true` |

---

## Examples

| Example | Shows |
|---|---|
| [`examples/scheduled.yml`](examples/scheduled.yml) | The quick start: a nightly diagnostic with the evidence kept |
| [`examples/policy-gate.yml`](examples/policy-gate.yml) | Gating a deployment on an acceptance policy file, with exemptions that expire |
| [`examples/code-scanning.yml`](examples/code-scanning.yml) | Failing checks as code-scanning alerts, through the SARIF output |
| [`examples/attest-and-sign.yml`](examples/attest-and-sign.yml) | The attestation, signed with `actions/attest`, so a gateway can verify who ran the check |

---

## When not to use passmcp-action

- **A server that is a program.** `--stdio` runs the server as a child
  process, and the image holds nothing but passmcp, so a `node` or `python`
  server cannot run inside it. Install passmcp on the runner instead;
  passmcp's [CI guide](https://satellion.com/passmcp/docs/ci/) shows how.
- **A runner without Docker.** macOS and Windows hosted runners cannot run
  Linux containers; the same guide covers the binary.
- **Against a production server with `--allow-mutations` or
  `--allow-destructive`.** The action passes whatever `args` says; those
  two invoke tools that change things. Point them at a server you stood
  up for the run.
- **As a load test.** passmcp throttles at `--rps 2` by default and the
  action does not change that. Raising it is your call against your own
  server.

---

## Development

```bash
make lint        # actionlint (with shellcheck), shellcheck on the scripts
make digest      # the pinned digest is the image of this version, in both places
make lockstep    # the version is passmcp's latest release
make family      # this repository's row in passmcp's family manifest
make test        # run the pinned image: passmcp version
```

[DEVELOPMENT.md](DEVELOPMENT.md) maps every CI gate to its local form and
explains the sync and release workflows.

---

## Security

The image is pinned by digest and the digest is checked against ghcr.io in
CI; the token is forwarded through the environment and never as an
argument; the container runs as the runner's own unprivileged user and
writes only under the report directory; the one other action used is
pinned by commit SHA.
Nothing is downloaded at run time but the image.

Report vulnerabilities according to [`SECURITY.md`](SECURITY.md).

---

## Documentation

The four entry points, identical across every repo in the family:

- **[User Manual](https://satellion.com/passmcp/docs/)** — passmcp's rendered manual: the phases, the report, the CI guide
- **[API reference](https://pkg.go.dev/satellion.com/passmcp)** — the Go packages behind the binary the image runs
- **[Developer docs](DEVELOPMENT.md)** — the gates, the sync workflow, the release model
- **[Ecosystem map](https://github.com/sebastienrousseau/passmcp/blob/main/docs/ecosystem.md)** — the family, the published artefacts, the lockstep version rule

| Document | Covers |
|---|---|
| [`action.yml`](action.yml) | Every input and output, with its description, as the Marketplace shows them |
| [`templates/passmcp.gitlab-ci.yml`](templates/passmcp.gitlab-ci.yml) | The GitLab job |
| [`docs/adr/`](docs/adr/README.md) | Decision records for this repository |
| [`SECURITY.md`](SECURITY.md) | Disclosure policy, what is pinned, what is never logged |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Signed-commit and DCO policy, what a change needs |
| [`CHANGELOG.md`](CHANGELOG.md) | Per-release notes, and the lockstep version rule |
| [`SUPPORT.md`](SUPPORT.md) | Where to ask, and what to expect |

---

## Stability guarantees

passmcp-action is pre-1.0, carries passmcp's version, and follows SemVer with
the patch digit moving for everything until 1.0.

**The breaking axis is the contract a workflow relies on.** These are
breaking:

- Removing or renaming an input or an output
- Changing an input's default
- Changing which exit code fails the job under a given `fail-on`
- Changing where the report directory or its files land

Added inputs with inert defaults, added outputs, and a new pinned image
for a new passmcp release are **not** breaking. The pinned image follows
passmcp, whose own stability rule governs what a run reports.

**Deprecation window.** A deprecated input keeps working for at least one
release after the release that announces it, with a warning annotation.

---

## License

Licensed under the **[Apache License 2.0](LICENSE)**.

The image the action runs is [passmcp](https://github.com/sebastienrousseau/passmcp),
which is GPL-3.0-only. Running a GPL program from an Apache-2.0 wrapper
places no obligation on the workflow that uses it; the wrapper is
Apache-2.0 so the Marketplace listing and the GitLab template can be
copied and adapted freely.

<p align="right"><a href="#contents">Back to Top</a></p>
