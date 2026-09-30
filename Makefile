# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

.PHONY: all lint spdx-check versions lockstep digest family unit coverage smoke test help readme-check name-guard demo

# bashcov runs the suite for `make coverage`; CI sets it to
# `bundle exec bashcov` against tests/Gemfile.lock.
BASHCOV ?= bashcov
BASH_PATH ?= $(shell command -v bash)

# Every gate CI runs.
all: lint spdx-check readme-check name-guard versions digest lockstep family test coverage

# actionlint reads action.yml and every workflow, shellcheck included;
# shellcheck then reads the scripts and the test suite.
lint:
	actionlint
	shellcheck scripts/*.sh tests/traced.sh tests/bin/curl tests/bin/gh tests/helpers.bash tests/*.bats

# The README follows the portfolio template: headings in order, no
# unresolved {{VARIABLES}} (AGENTS.md §7.3).
readme-check:
	scripts/readme-check.sh

spdx-check:
	scripts/spdx-check.sh

# Every version-bearing place names the newest CHANGELOG version.
versions:
	scripts/verify-release-versions.sh

# The image pinned in action.yml is the image of the version in CHANGELOG.md.
digest:
	scripts/verify-digest.sh

# The version is passmcp's latest release, exactly.
lockstep:
	scripts/lockstep.sh

# This repository's row in passmcp's family manifest is true of this tree.
family:
	scripts/family.sh

# The bats suite: every script, against a copy of the tree, network stubbed.
unit:
	bats tests

# The same suite under bashcov, tracing only the scripts; writes
# coverage/badge.json and fails below COVERAGE_MIN (85) percent.
coverage:
	rm -rf coverage
	$(BASHCOV) --bash-path "$(BASH_PATH)" --root "$(CURDIR)" -- tests/traced.sh tests
	scripts/coverage-badge.sh "$$(jq -r .total.lines.percent coverage/coverage.json)" coverage/badge.json

# Run the pinned image the way the action does, without a server: proves
# the digest pulls and the binary answers.
smoke:
	docker run --rm "$$(scripts/pinned-image.sh)" version

test: unit smoke

# The README demo (.github/demo.gif), rendered by VHS from .github/demo.tape:
# the action's "Run passmcp" step, run locally against passmcp's example
# server with the pinned image. Needs vhs, ttyd, ffmpeg, yq, Go (for the
# example server, at the lockstep release) and a Docker that resolves
# host.docker.internal (Docker Desktop, colima). DEMO_WORK is the step's
# workspace and must be shared with Docker's VM: colima shares only your
# home directory by default, so point it there when the clone is not.
DEMO_WORK ?= $(CURDIR)/build/demo/work
demo:
	mkdir -p build/demo/bin "$(DEMO_WORK)"
	rm -rf "$(DEMO_WORK)/passmcp-report"
	rm -f "$(DEMO_WORK)/action.yml" "$(DEMO_WORK)/github-output" "$(DEMO_WORK)/step-summary.md" "$(DEMO_WORK)/run-step.sh" "$(DEMO_WORK)/step.log"
	ver="$$(grep -Eo '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | head -1 | tr -d '#[] ')"; \
	  GOBIN="$(CURDIR)/build/demo/bin" go install "satellion.com/passmcp/examples/servers@v$${ver}"
	docker pull --quiet "$$(scripts/pinned-image.sh)"
	cp action.yml "$(DEMO_WORK)/action.yml"
	DEMO_WORK="$(DEMO_WORK)" PATH="$(CURDIR)/build/demo/bin:$$PATH" vhs .github/demo.tape

help:
	@printf '%s\n' "targets: all lint spdx-check readme-check name-guard versions digest lockstep family unit coverage smoke test demo"

# The project was renamed to passmcp: the retired name may not appear in
# any tracked file (scripts/name-guard.sh).
name-guard:
	./scripts/name-guard.sh
