<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Security Policy

passmcp-action runs passmcp inside a workflow with a token the workflow
supplies. Its security posture is about two things: running exactly the
binary passmcp's release signed, and keeping the token out of every place a
runner records.

## Reporting a Vulnerability

Report security issues through [GitHub's private vulnerability reporting](https://github.com/sebastienrousseau/passmcp-action/security/advisories/new). Do not open a public issue.

You will receive an acknowledgement within **72 hours**. A confirmed
vulnerability is fixed and released within **90 days** of the report, or
sooner when a fix is straightforward. A vulnerability in passmcp itself
belongs in [passmcp's policy](https://github.com/sebastienrousseau/passmcp/blob/main/SECURITY.md).

## Supported Versions

Only the latest release is supported. The version is passmcp's; see the
lockstep rule in [CHANGELOG.md](CHANGELOG.md).

## Security Measures

Each item names what enforces it.

- **The image is pinned by digest, and the digest is checked.** `action.yml`
  and the GitLab template name `ghcr.io/sebastienrousseau/passmcp@sha256:…`,
  never a tag. `scripts/verify-digest.sh`, run in CI, fails when that
  digest is not the one ghcr.io tags for the version in `CHANGELOG.md`.
  The image itself is signed with keyless cosign by passmcp's release
  workflow; `pkg/VERIFY.md` in passmcp has the verification command.
- **The token is never an argument.** It reaches the container as the
  environment variable `MCP_TOKEN` and passmcp reads it with `--token-env`,
  so it appears in no `ps` listing, no shell trace and no step log.
  passmcp redacts it from every report and telemetry file it writes.
- **The workspace is mounted, but passmcp writes only under `report-dir`.**
  The container runs as the runner's own user, not root, so what it
  writes is owned by the workflow that reads it; the action refuses a
  `report-dir` outside the workspace.
- **Nothing is fetched at run time except the pinned image.** The action
  has no dependency on a script from another repository; the only other
  action it uses, `actions/upload-artifact`, is pinned by commit SHA and
  updated by Dependabot.
- **Read-only by default.** The action passes nothing that would let passmcp
  invoke a mutating tool. `--allow-mutations` and `--allow-destructive` can
  be given through `args`, and doing so against a server you do not own is
  the caller's decision and the caller's problem.
