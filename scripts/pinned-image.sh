#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Prints the image reference action.yml pins, which is the one source of
# truth for what the action runs.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
ref=$(sed -n 's/^    default: "\(ghcr.io\/sebastienrousseau\/passmcp@sha256:[0-9a-f]\{64\}\)"$/\1/p' action.yml)
[ -n "$ref" ] || { echo "pinned-image: action.yml pins no image by digest" >&2; exit 1; }
echo "$ref"
