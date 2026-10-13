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

Change `scripts/rebuild-rafaelgaspar.sh`,
`.github/workflows/rafaelgaspar-tag-bump.yaml`, and
`.cursor/skills/rafaelgaspar-fork/` **here**, not in the four forks.
Forks call the reusable workflow; publish workflows stay per-fork.

Members and tag filters: `members.yaml`. Fork workflow for agents:
[rafaelgaspar-fork](../rafaelgaspar-fork/SKILL.md).
