# Xpra: full fork debs (`tracks: branch` / `upstream/v7.x`)

## Problem (legacy)

Older images used **xpra.org** `apt` (e.g. 6.5.6) plus **`xpra-rafaelgaspar-overlay_*`**
(divert ~20 Python modules + HTML5 www). That cannot track **`upstream/v7.x`**
coherently (master is already 8.x).

**members.yaml** sets `tracks: branch` on **`xpra`** → `upstream_branch: v7.x` and
**`xpra-html5`** → `upstream_branch: master` (current html5 client; merged upstream features).

## Target

| Layer | Source |
| --- | --- |
| Xpra server, codecs, x11, audio, html5 | **Binary debs built from `rafaelgaspar/xpra` @ integration tag** (upstream `packaging/debian`) |
| Fork HTML5 tree | **Staged into the source tree** before `debuild` (same commit as xpra-html5 integration tag) |
| Cluster image | **No xpra.org** `xpra-*` packages; **no overlay deb** |

Integration **git tags** stay `v7.0-<sha>-rafaelgaspar.N` (or tag-based when `tracks: tag`).

**Debian package versions** should use native ordering, e.g. `7.0~abc1234.rafaelgaspar.0` (tilde sorts before final releases). **`deb-manifest.txt`** lists the **`.deb` filenames** on the release (archive form: `7.0.abc1234…`, not `7.0~…`); k3s-home maps manifest lines to assets via `tr '~' '.'` when needed.

## Release artifacts (per integration tag)

GitHub release ships:

- `deb-manifest.txt` — install order (one filename per line)
- `xpra-common_*.deb`, `xpra-server_*.deb`, `xpra-x11_*.deb`, codecs packages, `xpra-html5_*.deb`, …

Build entrypoint: `packaging/debian/build-rafaelgaspar-xpra-for-forky.sh` (see xpra fork).

Integration releases also update an **apt repository** on GitHub Pages (`gh-pages` → `apt/`):

`deb [signed-by=/usr/share/keyrings/rafaelgaspar-xpra.gpg] https://rafaelgaspar.github.io/xpra/apt forky main`

The overlay-only `.deb` remains in the release workflow for external apt users only;
**k3s-home does not use it.**

## k3s-home

`images/xpra-base/install-rafaelgaspar-xpra-debs.sh` pins the integration tag, installs from the **Pages apt repo**, and falls back to release `.deb` assets if the repo is not ready yet.

HTML5 **`/usr/share/xpra/www`** is the upstream **`xpra-html5`** Debian package (not bundled in server debs). Fork packaging: [debian-apt-github-pages.md](./debian-apt-github-pages.md) — build via `python3 setup.py deb`, apt at `https://rafaelgaspar.github.io/xpra-html5/apt`.

Dockerfile: `ARG XPRA_FORK_VERSION=…` and `install-rafaelgaspar-xpra-debs.sh` (runtime deps such as pulse/cups stay on apt).

Renovate: pin regex matches branch-line tags with an optional `-<sha>` segment before `-rafaelgaspar.N`.

## Rollout

1. Land build script + release workflow job; prove one green release with debs built **inside `debian:forky`** (same suite as k3s-home images — not `ubuntu-latest` / `lsb_release`).
2. `xpra-base` installs only from the integration release (`deb-manifest.txt`); no xpra.org `xpra-*` in the image.
3. Validate NVENC, html5, and reconnect settings on cluster desktops.

## Check runtime

```bash
python3 -c 'import xpra; print(xpra.__version__)'
xpra --version
dpkg -l 'xpra-*' | grep ^ii
```

All `xpra-*` packages should share the same **fork deb version** (not `6.5.6-r*` from xpra.org).
