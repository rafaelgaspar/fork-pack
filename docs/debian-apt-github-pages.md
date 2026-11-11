# Debian apt on GitHub Pages (fork-pack)

Shared scripts for **reprepro** apt trees hosted on **gh-pages** (`https://<owner>.github.io/<repo>/apt`).

## Scripts (canonical in fork-pack)

| Script | Role |
|--------|------|
| `scripts/debian/publish-apt-repo.sh` | `includedeb` all `*.deb` under a suite (`forky` by default) |
| `scripts/debian/publish-apt-to-github-pages.sh` | Clone/push `gh-pages`, docker forky + reprepro |

Commit deb build scripts and release/apt workflow changes on **`feat/rafaelgaspar`**
only, not on child `feat/*` feature branches.

**Deb builds stay in each fork** (project-specific):

| Repo | Build script |
|------|----------------|
| `rafaelgaspar/xpra` | `packaging/debian/build-rafaelgaspar-xpra-for-forky.sh` (debuild integration set) |
| `rafaelgaspar/xpra-html5` | `packaging/debian/build-rafaelgaspar-xpra-html5-for-forky.sh` (`python3 setup.py deb`) |

Vendor **apt helpers only** into a fork: `scripts/install.sh /path/to/fork` copies `scripts/debian/publish-apt-*.sh` to `.github/scripts/debian/`.

## Prerequisite: Terraform GitHub Pages

Enable Pages on the fork **before** the first apt publish push:

1. In [k3s-home `terraform/github/repos.yaml`](https://github.com/rafaelgaspar/k3s-home/blob/main/terraform/github/repos.yaml), `xpra` and `xpra-html5` have a `pages:` block (`gh-pages`, path `/`).
2. Merge the Terraform PR and let **GitHub Terraform** apply on `main`.
3. Then run **rafaelgaspar Release** on the fork (it pushes the `gh-pages` branch).

Without Pages enabled, `git push … gh-pages` from CI may succeed but
`https://<owner>.github.io/<repo>/apt` will 404 until Terraform and the first
publish land.

## Release workflow pattern

1. **Checkout fork-pack** next to the fork (tag-bump already does this as `.fork-pack`).
2. **Build debs** with that repo’s packaging script (see table above) in `debian:forky`.
3. **Publish Pages apt** (from the fork repo checkout on the runner; vendored or `.fork-pack` checkout):

```bash
export APT_LABEL="rafaelgaspar xpra-html5"
export APT_DESCRIPTION="rafaelgaspar/xpra-html5 integration debs for Debian forky"
export APT_GPG_ASC_FILENAME="rafaelgaspar-xpra-html5.gpg.asc"
export APT_PAGES_COMMIT_LABEL="${TAG}"
export APT_PAGES_README=$'# rafaelgaspar/xpra-html5\n# Apt: https://rafaelgaspar.github.io/xpra-html5/apt'
# signing: APT_SIGN_KEY_ID, APT_REPO_GPG_* (same vars as xpra integration)

.github/scripts/debian/publish-apt-to-github-pages.sh dist/debian
```

## Apt lines (consumers)

| Repo | URL | Key (when signing) |
|------|-----|-------------------|
| [rafaelgaspar/xpra](https://github.com/rafaelgaspar/xpra) | `https://rafaelgaspar.github.io/xpra/apt` | `rafaelgaspar-xpra.gpg.asc` |
| [rafaelgaspar/xpra-html5](https://github.com/rafaelgaspar/xpra-html5) | `https://rafaelgaspar.github.io/xpra-html5/apt` | `rafaelgaspar-xpra-html5.gpg.asc` |

Example:

```text
deb [signed-by=/usr/share/keyrings/rafaelgaspar-xpra-html5.gpg] https://rafaelgaspar.github.io/xpra-html5/apt forky main
```

Leave `APT_ARCHITECTURES` as real arches (`amd64`). reprepro rejects `all` in `Architectures:`; `Architecture: all` debs (html5) still publish under those arches.

## xpra server integration

`rafaelgaspar/xpra` full deb releases should either ship an **`xpra-html5` `.deb`** on the same manifest/apt, or consumers install html5 from the **xpra-html5** apt (k3s-home `install-rafaelgaspar-xpra-debs.sh`: html5 deb first, or pinned tarball until apt exists).
