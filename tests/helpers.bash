# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Shared set-up for the script tests. Each test gets a copy of the files the
# scripts read, in its own temporary directory, and runs the real scripts
# against it through PASSMCP_ACTION_ROOT; curl is the stub in tests/bin.

REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
# Under tests/traced.sh the scripts are reached through tracing shims.
export SCRIPTS="${PASSMCP_TEST_SCRIPTS:-${REPO}/scripts}"

# The pinned digest in the real action.yml, for tests that need a match.
pinned_digest() {
  sed -n 's/^    default: "ghcr.io\/sebastienrousseau\/passmcp@\(sha256:[0-9a-f]\{64\}\)"$/\1/p' "${REPO}/action.yml"
}

setup_tree() {
  TREE="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${TREE}/scripts" "${TREE}/docs"
  cp -R "${REPO}/CHANGELOG.md" "${REPO}/README.md" "${REPO}/action.yml" \
    "${REPO}/CITATION.cff" "${REPO}/templates" "${REPO}/examples" \
    "${REPO}/LICENSES" "${TREE}/"
  cp -R "${REPO}/docs/releases" "${TREE}/docs/"
  cp "${REPO}/scripts/lockstep.sh" "${TREE}/scripts/"
  align_versions
  export PASSMCP_ACTION_ROOT="${TREE}"
  export PATH="${REPO}/tests/bin:${PATH}"
}

# Make the fixture name one version everywhere, the newest in its CHANGELOG,
# the way the sync workflow leaves a tree. The tests then hold across
# releases, and on a release branch whose section is open before its sync;
# whether the real tree agrees with itself is `make versions`' question.
align_versions() {
  VER=$(grep -Eo '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "${TREE}/CHANGELOG.md" | head -1 | tr -d '#[] ')
  export VER
  (
    cd "${TREE}" || return 1
    perl -pi -e 's{passmcp-action(\@v|/v)\d+\.\d+\.\d+}{passmcp-action$1$ENV{VER}}g;
      s{released at \*\*\d+\.\d+\.\d+\*\*}{released at **$ENV{VER}**}g;
      s{^version: .*}{version: $ENV{VER}}' README.md CITATION.cff examples/*.yml templates/*.yml
    touch "docs/releases/v${VER}.md"
  )
}

# Replace text in a file of the tree, portably (BSD and GNU sed differ on -i).
edit() {
  local file="${TREE}/$1" from="$2" to="$3"
  FROM="${from}" TO="${to}" perl -0pi -e 's/\Q$ENV{FROM}\E/$ENV{TO}/g' "${file}"
}
