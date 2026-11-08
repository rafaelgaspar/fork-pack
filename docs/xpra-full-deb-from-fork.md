# Xpra: full fork debs (tracks main / 7.x)

## Problem (legacy)

Older images used **xpra.org** `apt` (e.g. 6.5.6) plus **`xpra-rafaelgaspar-overlay_*`**
(divert ~20 Python modules + HTML5 www). That cannot track **`tracks: main`** /
**7.x** coherently.

## Target

| Layer | Source |
| --- | --- |
| Xpra server, codecs, x11, audio, html5 | **Binary debs built from `rafaelgaspar/xpra` @ integration tag** (upstream `packaging/debian`) |
| Fork HTML5 tree | **Staged into the source tree** before `debuild` (same commit as xpra-html5 integration tag) |
| Cluster image | **No xpra.org** `xpra-*` packages; **no overlay deb** |

Integration **git tags** stay `v7.0-main-<sha>-rafaelgaspar.N` (or tag-based when `tracks: tag`).

**Debian package versions** should use native ordering, e.g. `7.0~main+abc1234.rafaelgaspar.0` (tilde sorts before final releases).

## Release artifacts (per integration tag)

GitHub release ships:

- `deb-manifest.txt` — install order (one filename per line)
- `xpra-common_*.deb`, `xpra-server_*.deb`, `xpra-x11_*.deb`, codecs packages, `xpra-html5_*.deb`, …

Build entrypoint: `packaging/debian/build-rafaelgaspar-from-git.sh` (see xpra fork).

The overlay-only `.deb` remains in the release workflow for external apt users only;
**k3s-home does not use it.**

## k3s-home

`images/xpra-base/install-rafaelgaspar-xpra-debs.sh` pulls manifest + debs from the integration release.

Dockerfile: `ARG XPRA_FORK_VERSION=…` and `install-rafaelgaspar-xpra-debs.sh` (runtime deps such as pulse/cups stay on apt).

Renovate: widen the xpra pin regex to include `~main+` builds when on main-line releases.

## Rollout

1. Land build script + release workflow job; prove one green release with debs on `ubuntu-24.04` runner.
2. `xpra-base` installs only from the integration release (`deb-manifest.txt`); no xpra.org `xpra-*` in the image.
3. Validate NVENC, html5, and reconnect settings on cluster desktops.

## Check runtime

```bash
python3 -c 'import xpra; print(xpra.__version__)'
xpra --version
dpkg -l 'xpra-*' | grep ^ii
```

All `xpra-*` packages should share the same **fork deb version** (not `6.5.6-r*` from xpra.org).
