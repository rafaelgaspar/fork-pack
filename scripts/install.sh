#!/usr/bin/env bash
# Vendor pack scripts and the rafaelgaspar-fork skill into a fork checkout.
# Tag-bump reusable stays in fork-pack .github/workflows; forks uses: it from there.
set -euo pipefail

dest=${1:?usage: install.sh /path/to/fork}
pack=$(cd "$(dirname "$0")/.." && pwd)

[[ -d $dest/.git ]] || { echo "error: ${dest} is not a git checkout" >&2; exit 1; }

mkdir -p \
  "${dest}/.github/scripts" \
  "${dest}/.github/workflows" \
  "${dest}/.cursor/skills"

cp -a "${pack}/scripts/rebuild-rafaelgaspar.sh" "${dest}/.github/scripts/"
cp -a "${pack}/scripts/resolve-integration-tag.sh" "${dest}/.github/scripts/"
chmod +x "${dest}/.github/scripts/"*.sh

rm -f "${dest}/.github/workflows/rafaelgaspar-tag-bump-reusable.yaml"

rm -rf "${dest}/.cursor/skills/rafaelgaspar-fork"
cp -a "${pack}/dot-cursor/skills/rafaelgaspar-fork" "${dest}/.cursor/skills/"
if [[ ! -e ${dest}/.cursor/skills/README.md ]]; then
  cat >"${dest}/.cursor/skills/README.md" <<'EOF'
# Agent skills

When vendored into a fork, `.claude/skills` is a symlink to `.cursor/skills`.
Edit and commit under `.cursor/skills/` only.

Shared skill source: `rafaelgaspar/fork-pack` `dot-cursor/skills/`.

| Skill | When to use |
| --- | --- |
| [rafaelgaspar-fork](rafaelgaspar-fork/SKILL.md) | Fork workflow — feat branches, `rafaelgaspar` pointer, tag-bump |
EOF
fi
if [[ ! -e ${dest}/.claude/skills ]]; then
  mkdir -p "${dest}/.claude"
  ln -s ../.cursor/skills "${dest}/.claude/skills"
fi
printf 'installed pack scripts and rafaelgaspar-fork skill into %s\n' "$dest"
