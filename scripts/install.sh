#!/usr/bin/env bash
# Copy pack scripts into a fork checkout's .github/scripts/.
set -euo pipefail

dest=${1:?usage: install.sh /path/to/fork}
pack=$(cd "$(dirname "$0")/.." && pwd)

[[ -d $dest/.git ]] || { echo "error: ${dest} is not a git checkout" >&2; exit 1; }

mkdir -p "${dest}/.github/scripts" "${dest}/.cursor/skills"
cp -a "${pack}/scripts/rebuild-rafaelgaspar.sh" "${dest}/.github/scripts/"
cp -a "${pack}/scripts/resolve-integration-tag.sh" "${dest}/.github/scripts/"
chmod +x "${dest}/.github/scripts/"*.sh
cp -a "${pack}/.cursor/skills/rafaelgaspar-fork" "${dest}/.cursor/skills/"
if [[ ! -e ${dest}/.cursor/skills/README.md ]]; then
  cp -a "${pack}/.cursor/skills/README.md" "${dest}/.cursor/skills/"
fi
if [[ ! -e ${dest}/.claude/skills ]]; then
  mkdir -p "${dest}/.claude"
  ln -s ../.cursor/skills "${dest}/.claude/skills"
fi
printf 'installed pack scripts and rafaelgaspar-fork skill into %s\n' "$dest"
