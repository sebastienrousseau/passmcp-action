# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# The README demo: the action's own "Run passmcp" step, taken from
# action.yml with yq and run locally the way a runner would, against
# passmcp's example toxic-pair server. The step runs the pinned image, which
# reaches the server through host.docker.internal: plain http to a host
# that is not loopback, so passmcp fails the connectivity check and the
# step exits 2 with fail-on at its default. Rendered by `make demo`, which
# pulls the pinned image, installs the example server at the lockstep
# release and exports DEMO_WORK, the step's workspace.
#
# The hidden set-up gives the step what a runner would: GITHUB_WORKSPACE,
# GITHUB_OUTPUT, GITHUB_STEP_SUMMARY, and every other variable its env:
# block maps from an input, set to that input's default in action.yml.
Output .github/demo.gif
Require docker
Require yq
Require servers
Set Shell "bash"
Set FontSize 14
Set Width 1200
Set Height 300
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms

Hide
Type `PS1='$ '; cd "$DEMO_WORK"; d() { yq -r ".inputs.\"$1\".default" action.yml; }` Enter
Type `export GITHUB_WORKSPACE="$PWD" GITHUB_OUTPUT="$PWD/github-output" GITHUB_STEP_SUMMARY="$PWD/step-summary.md"` Enter
Type `export IMAGE="$(d image)" COMMAND="$(d command)" MCP_TOKEN="$(d token)" POLICY="$(d policy)" EXTRA_ARGS="$(d args)"` Enter
Type `export REPORT_DIR="$(d report-dir)" FAIL_ON="$(d fail-on)" WITH_SUMMARY="$(d summary)" WITH_ATTEST="$(d attest)"` Enter
# The server stops itself after 90s: a hidden kill would still print a line.
Type "timeout 90 servers -flaw toxic-pair -addr 127.0.0.1:17831 >/dev/null 2>&1 &" Enter
# Let the set-up finish and clear it before recording starts.
Sleep 2s
Type "clear" Enter
Sleep 500ms
Show

Type `yq '.runs.steps[] | select(.id == "run") | .run' action.yml > run-step.sh` Sleep 400ms Enter
Sleep 1s
Type `ENDPOINT=http://host.docker.internal:17831/mcp bash run-step.sh > step.log 2>&1; echo "step exited $?"` Sleep 400ms Enter
# A full check takes about 20s, most of it the performance phase.
Sleep 26s
Type "tail -n 1 step.log" Sleep 400ms Enter
Sleep 1500ms
Type `cat "$GITHUB_OUTPUT"` Sleep 400ms Enter
Sleep 1500ms
Type "ls passmcp-report" Sleep 400ms Enter
Sleep 4s
