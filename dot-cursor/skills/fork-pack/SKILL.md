---
name: fork-pack
description: >-
  Shared rebuild/tag-bump files for rafaelgaspar application forks (homepage,
  supergateway, xpra, xpra-html5, otbr-insight). Use when changing stack rebuild,
  tag-bump, mergiraf, Discord notify, or fork-pack install.
disable-model-invocation: true
---

# fork-pack

Repo: [rafaelgaspar/fork-pack](https://github.com/rafaelgaspar/fork-pack).
Clones live in `~/Projects/ThirdParty/fork-pack`.

Reusable tag-bump lives in `.github/workflows` (`workflow_call` only, so it
does not run on fork-pack). Skills stay in `dot-cursor/`; `scripts/install.sh`
vendors scripts and `rafaelgaspar-fork` onto forks as `.github/scripts` and
`.cursor/skills`.

Change `scripts/rebuild-rafaelgaspar.sh`,
`.github/workflows/rafaelgaspar-tag-bump.yaml`, and
`dot-cursor/skills/rafaelgaspar-fork/` **here**, not in the five forks.
Forks call `rafaelgaspar/fork-pack/.github/workflows/rafaelgaspar-tag-bump.yaml@main`.
Publish workflows stay per-fork.

Tag-bump installs **mergiraf**, pushes only after the full local stack, and
skips the daily cron when `origin/rafaelgaspar` already contains the upstream
commit. Publish must checkout the restacked `rafaelgaspar` ref (not the
caller's `github.sha`) and tag from the upstream tag that was rebuilt.
Rebuild success/failure posts to Discord `#forks-tag-bump` via secret
`DISCORD_WEBHOOK_FORKS_TAG_BUMP` on each fork (incoming webhook). Daily skips stay
quiet. Fixer can summarize a failed Actions run; it cannot restack yet.

Members and tag filters: `members.yaml`. Fork workflow for agents:
[rafaelgaspar-fork](../rafaelgaspar-fork/SKILL.md).
