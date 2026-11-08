#!/usr/bin/env bash
# Build git integration base for tracks:main — v{tree-version}-main-{shortsha}.
# Usage: main-integration-base.sh <git-ref>
set -euo pipefail

ref=${1:?git ref required}
script_dir=$(cd "$(dirname "$0")" && pwd)

ver=$("${script_dir}/upstream-tree-version.sh" "$ref")
short=$(git rev-parse --short=7 "${ref}^{commit}")
printf 'v%s-main-%s\n' "$ver" "$short"
