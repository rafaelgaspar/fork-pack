#!/usr/bin/env bash
# Vendor pack scripts and the rafaelgaspar-fork skill into a fork checkout.
# Tag-bump reusable stays in fork-pack .github/workflows; forks uses: it from there.
# Debian apt helpers are copied only onto xpra / xpra-html5 (members.yaml).
set -euo pipefail

dest=${1:?usage: install.sh /path/to/fork}
pack=$(cd "$(dirname "$0")/.." && pwd)

[[ -d $dest/.git ]] || { echo "error: ${dest} is not a git checkout" >&2; exit 1; }

fork_key=""
origin_url=$(git -C "$dest" remote get-url origin 2>/dev/null || true)
if [[ -n $origin_url ]]; then
  origin_repo=${origin_url%.git}
  origin_repo=${origin_repo##*:}
  origin_repo=${origin_repo#https://github.com/}
  fork_key=${origin_repo##*/}
fi
[[ -n $fork_key ]] || fork_key=$(basename "$(cd "$dest" && pwd)")

copy_debian=false
if [[ -f $pack/members.yaml ]]; then
  publish=$(python3 - "$pack/members.yaml" "$fork_key" <<'PY'
import sys
from pathlib import Path
try:
    import yaml
except ImportError:
    sys.exit(0)
members = yaml.safe_load(Path(sys.argv[1]).read_text()).get("forks") or {}
m = members.get(sys.argv[2]) or {}
print(m.get("publish_workflow", ""))
PY
)
  [[ $publish == rafaelgaspar-release.yaml ]] && copy_debian=true
fi

mkdir -p \
  "${dest}/.github/scripts" \
  "${dest}/.github/workflows" \
  "${dest}/.cursor/skills"

cp -a "${pack}/scripts/rebuild-rafaelgaspar.sh" "${dest}/.github/scripts/"
cp -a "${pack}/scripts/resolve-integration-tag.sh" "${dest}/.github/scripts/"
if $copy_debian && [[ -d "${pack}/scripts/debian" ]]; then
  mkdir -p "${dest}/.github/scripts/debian"
  cp -a "${pack}/scripts/debian/"*.sh "${dest}/.github/scripts/debian/"
  chmod +x "${dest}/.github/scripts/debian/"*.sh
else
  rm -rf "${dest}/.github/scripts/debian"
fi
chmod +x "${dest}/.github/scripts/"*.sh

rm -f "${dest}/.github/workflows/rafaelgaspar-tag-bump-reusable.yaml"

rm -rf "${dest}/.cursor/skills/rafaelgaspar-fork"
cp -a "${pack}/dot-cursor/skills/rafaelgaspar-fork" "${dest}/.cursor/skills/"
if [[ ! -e ${dest}/.cursor/skills/README.md ]]; then
  cat >"${dest}/.cursor/skills/README.md" <<'EOF'
# Agent skills

If upstream has no `.claude/skills` directory, that path is a symlink to
`.cursor/skills`. If upstream already ships skills, leave that tree in place.
Edit the fork skill under `.cursor/skills/` only.

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
