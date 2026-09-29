<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Architecture

passmcp-action is a composite GitHub Action that runs
[passmcp](https://github.com/sebastienrousseau/passmcp) against an MCP server
and turns its exit status, report and attestation into a job outcome,
outputs and artifacts. It contains no diagnostic logic: every check is
passmcp's, run from passmcp's published container image.

## The one decision

**The action runs passmcp's release image, pinned by digest.** Not a
binary download, not `go install`, not `latest`. The digest is the
default of the `image` input in `action.yml`, and it is the only place
the version lives. A user pinning `passmcp-action@v0.0.1` gets exactly the
bytes passmcp's release published and signed for that version, and nothing a
registry could later change under the same tag.

## Flow of one run

```text
workflow step ──► action.yml (composite)
                   │
                   ├─ 1. docker pull <image@digest>
                   ├─ 2. docker run passmcp check <endpoint>
                   │        token from MCP_TOKEN via --token-env, never argv
                   │        --report-dir writes txt, md, json, html,
                   │        junit.xml, sarif, telemetry.ndjson, telemetry.har
                   ├─ 3. read report.json → outputs: exit-code, score, grade,
                   │        report, sarif, attestation
                   ├─ 4. append the Markdown report to the job summary
                   ├─ 5. upload the report directory as an artifact
                   └─ 6. decide the job outcome from fail-on:
                            failure (exit 1 or 2) · error (exit 1) · never
```

The token reaches the container through the environment, so it never
appears in a process list or a log line. passmcp's recorder redacts it from
every report and telemetry file.

## Files

| Path | Role |
| :--- | :--- |
| `action.yml` | The action: inputs, outputs and the composite steps |
| `templates/passmcp.gitlab-ci.yml` | The same run for GitLab CI, pinned to the same digest |
| `examples/` | Complete workflows: a policy gate, code scanning, a schedule, attest and sign |
| `scripts/pinned-image.sh` | Prints the pinned reference; the one reader of the digest |
| `scripts/lockstep.sh` | Checks this repository's version against passmcp's latest release |
| `scripts/family.sh` | Checks this repository's row in passmcp's family manifest |

## How it stays in step with passmcp

1. passmcp's release workflow sends a `repository_dispatch`
   (`passmcp-release`) carrying the version and the image digest.
2. `sync.yml` rewrites the digest in `action.yml` and the GitLab
   template, bumps the version references and opens a pull request.
3. CI proves the new pin: `make digest` checks the digest exists on
   ghcr.io, a smoke job runs the action against it, and `make lockstep`
   checks the version.
4. After the merge, a signed tag `vX.Y.Z` makes `release.yml` publish the
   changelog section as the release notes and move the `v0` tag.

## What it does not do

- Evaluate anything itself. A bug in a check is a passmcp issue.
- Sign the attestation. It writes `attestation.json`; signing is a later
  step with cosign or `actions/attest`, run by a job that holds the
  identity.
- Run on macOS or Windows runners. Its steps call Docker, which
  GitHub-hosted runners provide on Linux only.
