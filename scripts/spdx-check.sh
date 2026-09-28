#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Every source file carries a machine-readable licence header, so REUSE
# compliance is a gate rather than a habit. REUSE.toml covers the files a
# header cannot go in.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
missing=0
# Assembled at run time so that this line is not itself read as a licence
# expression by the REUSE linter.
tag="SPDX-License-Identifier"
while IFS= read -r f; do
  case "$f" in
    LICENSE|LICENSES/*|.gitignore|.github/CODEOWNERS|docs/requirements.txt) continue ;;  # REUSE.toml covers these
  esac
  if ! head -5 "$f" | grep -q "${tag}:"; then
    echo "spdx-check: no licence header: $f" >&2
    missing=1
  fi
done < <(git ls-files 2>/dev/null || find . -type f -not -path './.git/*' | sed 's|^\./||')
[ "$missing" -eq 0 ] && echo "spdx-check: every source file carries a licence header"
exit "$missing"
