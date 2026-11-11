# Agent skills

Task-specific runbooks for coding agents. Each skill is a directory with `SKILL.md`
(YAML frontmatter + instructions).

This pack keeps skills in `dot-cursor/skills` so Cursor does not load them as
project skills for fork-pack itself. `scripts/install.sh` copies
`rafaelgaspar-fork` onto forks as `.cursor/skills/rafaelgaspar-fork`.
If upstream has no `.claude/skills` directory, install creates a symlink to
`.cursor/skills`. If upstream already ships skills (xpra), those stay.

## Index

| Skill | When to use |
| --- | --- |
| [rafaelgaspar-fork](rafaelgaspar-fork/SKILL.md) | Fork workflow — feat branches, `rafaelgaspar` pointer, tag-bump |
| [fork-pack](fork-pack/SKILL.md) | Changing this pack (scripts, reusable tag-bump, members) |
