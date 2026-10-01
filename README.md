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
  <a href="https://github.com/sebastienrousseau/passmcp-action/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/sebastienrousseau/passmcp-action/ci.yml?branch=main&style=for-the-badge&logo=github&label=Build" alt="Build" /></a>
  <a href="https://github.com/sebastienrousseau/passmcp-action/blob/main/DEVELOPMENT.md#coverage"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fsebastienrousseau.com%2Fpassmcp-action%2Fcoverage.json&style=for-the-badge&logo=codecov&logoColor=white" alt="Coverage" /></a>
  <a href="https://github.com/sebastienrousseau/passmcp-action/releases"><img src="https://img.shields.io/github/v/release/sebastienrousseau/passmcp-action?style=for-the-badge&color=fc8d62&logo=github&label=Release" alt="Release" /></a>
  <a href="https://sebastienrousseau.com/passmcp-action/"><img src="https://img.shields.io/badge/docs-manual-007d9c?style=for-the-badge&labelColor=555555&logo=readthedocs&logoColor=white" alt="Docs" /></a>
  <a href="https://scorecard.dev/viewer/?uri=github.com/sebastienrousseau/passmcp-action"><img src="https://img.shields.io/ossf-scorecard/github.com/sebastienrousseau/passmcp-action?style=for-the-badge&label=OpenSSF%20Scorecard&logo=openssf" alt="OpenSSF Scorecard" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg?style=for-the-badge" alt="License: Apache-2.0" /></a>
  <a href="https://github.com/sebastienrousseau/passmcp-action/blob/main/DEVELOPMENT.md#requirements"><img src="https://img.shields.io/badge/runner-linux%20%2B%20docker-93450a.svg?style=for-the-badge&logo=docker" alt="Runner: Linux with Docker" /></a>
</p>

<p align="center">
  <img src=".github/demo.gif" alt="The action's Run passmcp step, taken from action.yml and run locally with the pinned image against passmcp's example server over plain http: the step exits 2, prints the error annotation, and sets exit-code, score and grade outputs beside the report files" width="100%" />
</p>

---

## Contents

**Getting started**

- [Install](#install) — one `uses:` line, or one `include:` for GitLab
- [Requirements](#requirements) — a Linux runner with Docker, a reachable server
- [Quick Start](#quick-start) — diagnose a server on a schedule

**The passmcp-action ecosystem**

- [The passmcp-action ecosystem](#the-passmcp-action-ecosystem) — `passmcp`, `passmcp-reporting`, `passmcp-server`, `passmcp-action`, `passmcp-graph`, `passmcp-registry`, `passmcp-lsp`, `passmcp-census`, `satellion.com` at a glance

**Library reference**

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
- uses: sebastienrousseau/passmcp-action@v0.0.5
  with:
    endpoint: https://mcp.example.com/mcp
    token: ${{ secrets.MCP_TOKEN }}
```

Pin the exact version, as above, or follow the major tag `v0`, which the
release workflow moves to every release.

### In GitLab CI

```yaml
include:
  - remote: https://raw.githubusercontent.com/sebastienrousseau/passmcp-action/v0.0.5/templates/passmcp.gitlab-ci.yml

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
      - uses: sebastienrousseau/passmcp-action@v0.0.5
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

Every component is released at **0.0.5** and moves in lockstep: one version across the family, released together ([docs/ecosystem.md](https://github.com/sebastienrousseau/passmcp/blob/main/docs/ecosystem.md)).

| Component | Purpose | Use case |
| :--- | :--- | :--- |
| [passmcp](https://github.com/sebastienrousseau/passmcp) | The MCP server diagnostic: checks in nine phases, every finding tied to the request that showed it, signed attestations | Test a server before your agents trust it, and gate it in CI |
| [passmcp-reporting](https://github.com/sebastienrousseau/passmcp-reporting) | The attestation format, its JSON Schemas and offline verifier, the graph model, and the agentgateway processor | Verify an attestation in a gateway, registry or pipeline |
| [passmcp-server](https://github.com/sebastienrousseau/passmcp-server) | passmcp's diagnostics as read-only MCP tools | Evaluate a server, or check an attestation, from inside the agent |
| [passmcp-action](https://github.com/sebastienrousseau/passmcp-action) | passmcp in GitHub Actions and GitLab CI, the image pinned by digest | Fail a build on the findings you choose |
| [passmcp-graph](https://github.com/sebastienrousseau/passmcp-graph) | A local graph of agents, servers, tools and identities built from attestations | Find inherited risk and over-privilege, and gate on policy |
| [passmcp-registry](https://github.com/sebastienrousseau/passmcp-registry) | A signed public scorecard of the MCP Registry's remote servers | Check a public server's standing before connecting to it |
| [passmcp-lsp](https://github.com/sebastienrousseau/passmcp-lsp) | A language server for MCP artefacts, with check-id hover from the guidance catalogue | Catch mistakes in server.json, tool schemas and client configuration while editing |
| [passmcp-census](https://github.com/sebastienrousseau/passmcp-census) | The published reliability census: dataset, methodology, disclosure log and reproduction command | Cite ecosystem-wide reliability figures, and reproduce them |
| [satellion.com](https://github.com/sebastienrousseau/satellion.github.io) | The website, the Go module paths and the format URIs | Read the manual, and resolve `satellion.com/...` imports |

---

## Capabilities at a glance

| Area | Capability | Status |
| :--- | :--- | :--- |
| Target | `endpoint`: a Streamable HTTP URL | [Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1) |
| Credentials | `token`, forwarded through the environment as `MCP_TOKEN` | [Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1) |
| Gating | `policy`: an acceptance policy file; `fail-on`: `failure`, `error` or `never` | [Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1) |
| Pacing and everything else | `args`: any flag `passmcp check` takes | [Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1) |
| Evidence | `report-dir` with `report.{txt,md,json}`, `report.sarif`, `telemetry.{ndjson,har}`; `upload` as an artifact | [Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1) |
| Where people look | `summary` on the run page; `report.sarif` for code scanning | [Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1) |
| Attestation | `attest`: the in-toto statement beside the report, to sign in a later step | [Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1) |
| Outputs | `exit-code`, `score`, `grade`, `report`, `sarif`, `attestation` | [Released in 0.0.1](https://github.com/sebastienrousseau/passmcp-action/releases/tag/v0.0.1) |
| Servers that are programs (`--stdio`) | not through the image | Not supported by design: see [When not to use](#when-not-to-use-passmcp-action) |

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
itself is passmcp's, and passmcp's manual publishes its request budget.
There is no benchmark suite here because there is nothing here to measure
that is not passmcp. The one number the wrapper owns is the size of what it
pulls, read from the registry's manifest for the pinned 0.0.1 image:

| Scenario | Result | Environment |
| :--- | ---: | :--- |
| Image download, compressed layers | 6,912,228 bytes | `linux/amd64` manifest on ghcr.io |
| Image download, compressed layers | 6,361,425 bytes | `linux/arm64` manifest on ghcr.io |
| Pull and container start time | not measured | network- and runner-bound |
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
make lint        # actionlint (with shellcheck), shellcheck on the scripts and tests
make unit        # the bats suite for every script, with the network stubbed
make coverage    # the same suite under bashcov; fails below 85%, writes coverage/badge.json
make versions    # every version-bearing place names the CHANGELOG version
make digest      # the pinned digest is the image of this version, in both places
make lockstep    # the version is passmcp's latest release
make family      # this repository's row in passmcp's family manifest
make test        # the unit suite, then the pinned image: passmcp version
```

[DEVELOPMENT.md](DEVELOPMENT.md) maps every CI gate to its local form and
explains the sync and release workflows. The family manifest lives in
passmcp at
[`docs/ecosystem.md`](https://github.com/sebastienrousseau/passmcp/blob/main/docs/ecosystem.md);
`make family` checks this repository's row against it. A passmcp release
dispatches to this repository, the sync workflow pins the new image, and
the pull request it opens is the release.

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

- **[User Manual](https://sebastienrousseau.com/passmcp-action/)** — this repository's rendered manual; passmcp's own is at [satellion.com/passmcp/docs](https://satellion.com/passmcp/docs/)
- **[API reference](action.yml)** — every input and output of the action, with its description
- **[Developer docs](DEVELOPMENT.md)** — the gates, the sync workflow, the release model
- **[Ecosystem map](https://github.com/sebastienrousseau/passmcp/blob/main/docs/ecosystem.md)** — the family, the published artefacts, the lockstep version rule

| Document | Covers |
|---|---|
| [`action.yml`](action.yml) | Every input and output, with its description, as the Marketplace shows them |
| [`templates/passmcp.gitlab-ci.yml`](templates/passmcp.gitlab-ci.yml) | The GitLab job |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How one run flows, and how the action stays in step with passmcp |
| [`docs/adr/`](docs/adr/README.md) | Decision records for this repository |
| [`docs/releases/v0.0.1.md`](docs/releases/v0.0.1.md) | The 0.0.1 release highlights |
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
