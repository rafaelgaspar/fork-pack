#!/usr/bin/env bash
# Read upstream semver (or integer release) from a tree object at REF.
# Usage: upstream-tree-version.sh <git-ref>
set -euo pipefail

ref=${1:?git ref required}

read_py_init_version() {
  local path=$1
  local content
  content=$(git show "${ref}:${path}" 2>/dev/null) || return 1
  printf '%s\n' "$content" | sed -n 's/^__version__ = "\([^"]*\)".*/\1/p' | head -1
}

read_setup_version() {
  local path=$1
  local content line
  content=$(git show "${ref}:${path}" 2>/dev/null) || return 1
  while IFS= read -r line; do
    case $line in
      VERSION\ =\ \"*\" )
        line=${line#VERSION = \"}
        line=${line%\"}
        printf '%s\n' "$line"
        return 0
        ;;
      version\ =\ \"*\" )
        line=${line#version = \"}
        line=${line%\"}
        printf '%s\n' "$line"
        return 0
        ;;
    esac
  done <<<"$content"
  return 1
}

read_package_json_version() {
  local content
  content=$(git show "${ref}:package.json" 2>/dev/null) || return 1
  if command -v jq >/dev/null 2>&1; then
    jq -er .version <<<"$content"
    return
  fi
  printf '%s\n' "$content" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

ver=""
for candidate in \
  "$(read_py_init_version xpra/__init__.py 2>/dev/null || true)" \
  "$(read_setup_version setup.py 2>/dev/null || true)" \
  "$(read_package_json_version 2>/dev/null || true)"; do
  [[ -n "${candidate:-}" ]] || continue
  ver=$candidate
  break
done

[[ -n "${ver}" ]] || {
  echo "error: no VERSION/__version__ found at ${ref}" >&2
  exit 1
}
printf '%s\n' "$ver"
