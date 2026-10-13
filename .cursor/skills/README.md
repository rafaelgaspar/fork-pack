# Agent skills

Task-specific runbooks for coding agents. Each skill is a directory with `SKILL.md`
(YAML frontmatter + instructions).

When vendored into a fork, `.claude/skills` is a symlink to `.cursor/skills`.
Edit and commit under `.cursor/skills/` only.

## Index

| Skill | When to use |
| --- | --- |
| [rafaelgaspar-fork](rafaelgaspar-fork/SKILL.md) | Fork workflow — feat branches, `rafaelgaspar` pointer, tag-bump |
| [fork-pack](fork-pack/SKILL.md) | Changing this pack (scripts, reusable tag-bump, members) |
