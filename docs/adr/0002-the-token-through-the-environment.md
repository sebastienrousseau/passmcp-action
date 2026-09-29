<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# 0002 — The token reaches passmcp through the environment, never as an argument

**Status:** Accepted · **Recorded:** 2026-09-29 · in force since 0.0.1

## Context

The action has to hand the server's bearer token to passmcp inside a
container. passmcp accepts it two ways: `--token <value>` or
`--token-env <NAME>`. A value on a command line is visible in a process
listing, in a shell trace (`set -x`) and in the step log GitHub prints for
the `docker run` it executes; masking catches some of that and not all.

## Decision

**The token is passed to the container as the environment variable
`MCP_TOKEN` (`docker run -e MCP_TOKEN`), and passmcp reads it with
`--token-env MCP_TOKEN`.** `action.yml` never places the value in an
argument, and the GitLab template does the same with its masked variable.

## Consequences

- The token appears in no `ps` listing, no trace and no log line the action
  produces; passmcp's recorder then redacts it from every file it writes.
- A contributor who "simplifies" this to `--token "$TOKEN"` reintroduces the
  leak; AGENTS.md lists it under things that look like bugs and are not.
- The environment variable's name is part of the GitLab template's
  contract: `MCP_TOKEN` is what a project sets.
