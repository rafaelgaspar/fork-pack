# fork-pack

Shared GitOps files for the public `rafaelgaspar/*` application forks
([homepage](https://github.com/rafaelgaspar/homepage),
[supergateway](https://github.com/rafaelgaspar/supergateway),
[xpra](https://github.com/rafaelgaspar/xpra),
[xpra-html5](https://github.com/rafaelgaspar/xpra-html5)).

This repo is the source of truth for stack rebuild and tag-bump. Per-fork
publish workflows (GHCR vs overlay `.deb` vs HTML5 tarball) stay in the forks.

This repo has no `.github/` or `.cursor/` so GitHub Actions and Cursor project
skills never activate here. Canonical copies live in `dot-github/` and
`dot-cursor/`; `scripts/install.sh` vendors them onto forks as the live names.

## Layout

| Path | Role |
|---|---|
| `scripts/rebuild-rafaelgaspar.sh` | Rebuild linear `feat/*` on an upstream tag; point `rafaelgaspar` at the tip |
| `scripts/resolve-integration-tag.sh` | Pick `v{base}-rafaelgaspar.{N}` for a release |
| `dot-github/workflows/rafaelgaspar-tag-bump.yaml` | Reusable tag-bump (vendored onto forks; GitHub will not `uses:` this path) |
| `dot-cursor/skills/rafaelgaspar-fork/` | Shared agent skill for fork workflow |
| `examples/rafaelgaspar-tag-bump.yaml` | Thin per-fork caller (cron + inputs) |
| `members.yaml` | Fork list, upstream remotes, tag filters |

## Consume from a fork

GitHub reusable workflows must live under `.github/workflows`, so each fork
gets a local copy of the pack reusable (`rafaelgaspar-tag-bump-reusable.yaml`)
and a thin caller that `uses:` that file. Tag-bump still checkouts this repo
for the rebuild scripts.

```yaml
# .github/workflows/rafaelgaspar-tag-bump.yaml
name: rafaelgaspar Tag Bump
on:
  schedule:
    - cron: '15 4 * * *'
  workflow_dispatch:
    inputs:
      upstream_tag:
        required: false
        type: string
      dry_run:
        type: boolean
        default: false
      squash:
        type: boolean
        default: true
jobs:
  bump:
    uses: ./.github/workflows/rafaelgaspar-tag-bump-reusable.yaml
    with:
      upstream_url: https://github.com/gethomepage/homepage.git
      tag_glob: 'v*.*.*'
      tag_filter: '^v[0-9]+\.[0-9]+\.[0-9]+$'
      # schedule has no workflow_dispatch inputs; passing inputs.* (null) into
      # boolean reusable inputs fails the called job before it starts.
      upstream_tag: ${{ github.event.inputs.upstream_tag || '' }}
      dry_run: ${{ github.event.inputs.dry_run == 'true' }}
      squash: ${{ github.event.inputs.squash != 'false' }}
      event_name: ${{ github.event_name }}
    secrets: inherit
    permissions:
      contents: write
      packages: write
  publish:
    needs: bump
    if: needs.bump.outputs.should_release == 'true'
    uses: ./.github/workflows/rafaelgaspar-ghcr-publish.yaml
    with:
      ref: rafaelgaspar
    secrets: inherit
    permissions:
      contents: write
      packages: write
```

Local rebuild (from a fork checkout):

```sh
git clone git@github.com:rafaelgaspar/fork-pack.git ~/Projects/ThirdParty/fork-pack
FORK_PACK_SCRIPTS=~/Projects/ThirdParty/fork-pack/scripts \
  ~/Projects/ThirdParty/fork-pack/scripts/rebuild-rafaelgaspar.sh --squash --push vX.Y.Z
```

Or vendor scripts, reusable tag-bump, and the skill into the fork:

```sh
~/Projects/ThirdParty/fork-pack/scripts/install.sh /path/to/fork
```

## Tag patterns

Default in `rebuild-rafaelgaspar.sh` is `v` + digits, optionally `X.Y.Z`
(`v2.5.0` and `v21`). Forks pass `tag_filter` from `members.yaml` so html5
stays on `^v[0-9]+$`.
