# fork-pack

Shared GitOps files for the public `rafaelgaspar/*` application forks
([homepage](https://github.com/rafaelgaspar/homepage),
[supergateway](https://github.com/rafaelgaspar/supergateway),
[xpra](https://github.com/rafaelgaspar/xpra),
[xpra-html5](https://github.com/rafaelgaspar/xpra-html5)).

This repo is the source of truth for stack rebuild and tag-bump. Per-fork
publish workflows (GHCR vs overlay `.deb` vs HTML5 tarball) stay in the forks.

## Layout

| Path | Role |
|---|---|
| `scripts/rebuild-rafaelgaspar.sh` | Rebuild linear `feat/*` on an upstream tag; point `rafaelgaspar` at the tip |
| `scripts/resolve-integration-tag.sh` | Pick `v{base}-rafaelgaspar.{N}` for a release |
| `.github/workflows/rafaelgaspar-tag-bump.yaml` | Reusable workflow the forks call |
| `.cursor/skills/rafaelgaspar-fork/` | Shared agent skill for fork workflow |
| `examples/rafaelgaspar-tag-bump.yaml` | Thin per-fork caller (cron + inputs) |
| `members.yaml` | Fork list, upstream remotes, tag filters |

## Consume from a fork

Tag-bump checks out this repo and runs its scripts (no vendored copy required
at runtime). After a successful rebuild, the ROOT layer is updated from pack
scripts so a local checkout still has them.

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
jobs:
  bump:
    uses: rafaelgaspar/fork-pack/.github/workflows/rafaelgaspar-tag-bump.yaml@main
    with:
      upstream_url: https://github.com/gethomepage/homepage.git
      tag_glob: 'v*.*.*'
      tag_filter: '^v[0-9]+\.[0-9]+\.[0-9]+$'
      upstream_tag: ${{ inputs.upstream_tag }}
      dry_run: ${{ inputs.dry_run }}
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

Or vendor the scripts into `.github/scripts/`:

```sh
~/Projects/ThirdParty/fork-pack/scripts/install.sh /path/to/fork
```

## Tag patterns

Default in `rebuild-rafaelgaspar.sh` is `v` + digits, optionally `X.Y.Z`
(`v2.5.0` and `v21`). Forks pass `tag_filter` from `members.yaml` so html5
stays on `^v[0-9]+$`.
