#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Run the bats suite under bashcov with only the scripts traced.
#
# bashcov turns on xtrace through an exported SHELLOPTS, which every bash
# process inherits, bats included; bats's own background processes then
# write into the same trace and garble it. So bats runs with SHELLOPTS
# removed, and the tests call each script through a shim that puts it back
# for that one process. The scripts are traced exactly as they run.
#
#   bashcov --root . -- tests/traced.sh [bats arguments]
traced="${SHELLOPTS:-}"
set -euo pipefail
[[ ":${traced}:" == *:xtrace:* ]] || { echo "traced: run me under bashcov" >&2; exit 2; }

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
shims=$(mktemp -d)
trap 'rm -rf "${shims}"' EXIT

for script in "${repo}"/scripts/*.sh; do
  printf '#!/usr/bin/env bash\nexec env SHELLOPTS=%q %q "$@"\n' "${traced}" "${script}" \
    >"${shims}/${script##*/}"
  chmod +x "${shims}/${script##*/}"
done

PASSMCP_TEST_SCRIPTS="${shims}" env -u SHELLOPTS bats "$@"
