<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# 0004 — Coverage traces the scripts, not the test runner

**Status:** Accepted · **Date:** 2026-09-29

## Context

The family publishes a coverage badge for every repository. The code in
this one is the shell in `scripts/`; `action.yml`'s steps run only on a
runner and are covered by CI's smoke job, not by a line count. bashcov
measures shell coverage by turning on `xtrace` through an exported
`SHELLOPTS`, which every bash process inherits. Run over bats, that traces
bats too, and bats's own background processes write into the same trace:
the trace garbles and bashcov aborts with a partial report.

## Decision

**`make coverage` runs bats with `SHELLOPTS` removed, and the tests reach
each script through a shim that restores it for that one process**
(`tests/traced.sh`). Only the scripts are traced. SimpleCov counts every
file in `scripts/`, run or not (`.simplecov`), and
`scripts/coverage-badge.sh` fails below 85%, the family's floor.

## Consequences

- The number is line coverage of `scripts/*.sh` as bashcov infers it from
  the trace. It is not branch coverage, and it says nothing about the shell
  inside `action.yml`.
- Heredoc bodies and line continuations inside `$(...)` read to bashcov
  as lines that never ran. The scripts avoid those shapes rather than
  exclude lines from the count.
- The tools are pinned in `tests/Gemfile.lock` with checksums; CI installs
  them with Bundler, frozen.
