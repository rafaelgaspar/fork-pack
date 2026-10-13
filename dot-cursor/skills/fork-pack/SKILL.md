---
name: fork-pack
description: >-
  Shared rebuild/tag-bump files for rafaelgaspar application forks (homepage,
  supergateway, xpra, xpra-html5). Use when changing stack rebuild, tag-bump,
  or fork-pack install.
disable-model-invocation: true
---

# fork-pack

Repo: [rafaelgaspar/fork-pack](https://github.com/rafaelgaspar/fork-pack).
Clones live in `~/Projects/ThirdParty/fork-pack`.

This pack stores GitHub files in `dot-github/` and skills in `dot-cursor/`
so Actions and Cursor project skills do not run against fork-pack itself.
`scripts/install.sh` vendors them onto forks as `.github/` and `.cursor/`.

Change `scripts/rebuild-rafaelgaspar.sh`,
`dot-github/workflows/rafaelgaspar-tag-bump.yaml`, and
`dot-cursor/skills/rafaelgaspar-fork/` **here**, not in the four forks.
GitHub will not `uses:` a reusable workflow from `dot-github`; forks call a
vendored `.github/workflows/rafaelgaspar-tag-bump-reusable.yaml`. Publish
workflows stay per-fork.

Members and tag filters: `members.yaml`. Fork workflow for agents:
[rafaelgaspar-fork](../rafaelgaspar-fork/SKILL.md).
