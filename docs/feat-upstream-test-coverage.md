# feat-upstream test coverage

Tracks automated tests and remaining PR-body work for upstream PR branches (`feat-upstream/*` on xpra and xpra-html5). Not part of the shipped `rafaelgaspar` stack unless noted.

Run html5 tests: `node --test tests/` (CI: `.github/workflows/html5-unit-tests.yaml` on the H.264 branch).

## Overall

| Area | Status |
|------|--------|
| **CHANGELOG / docs in tree** | None on branches — normal; put repro and manual steps in the **PR body**. |
| **Co-authored-by / signing** | Aligned for upstream PRs. |
| **html5 `tests/`** | New on upstream base (`v21` had no `tests/`). **CI** runs `node --test tests/` on PRs touching `html5/` or `tests/`. |

## xpra (`v6.5.5` → branch)

| Branch | Tests | Gaps / notes |
|--------|--------|----------------|
| **x11-shadow-dynamic-window-model** | `test_shadow_dynamic_window_match_no_crash` (Xvfb + xterm + live shadow) | **`@unittest.skipUnless(xterm)`** — no silent skip. |
| **encode-queue-teardown** | **`client_connection_test.py`** (encode-at-end ordering on `stop_encode_thread`) | PR body: NVENC + disconnect / mmap client repro. |
| **video-idle-reuse-encoder** | **`video_idle_test.py`** (6 cases) | Solid. |
| **multi-screen-pointer** | **`xtest_pointer_test.py`** (mocked warp vs XTest fallback) | PR body: `DISPLAY=:N.M`, wrong-screen clicks; long-term fix is `screen_number` in `test.pyx`. |

## xpra-html5 (`v21` → branch)

| Branch | Tests | Gaps / notes |
|--------|--------|----------------|
| **html5-h264-safari** (5 commits) | **`VideoDecoder.test.mjs`**, **`OffscreenDecodeWorker.test.mjs`**, **`OffscreenDecodeWorkerHelper.test.mjs`**, **CI workflow** | Tie PR to **#227**. |
| **html5-hello-encoding** | **`ClientHello.test.mjs`** | Enough for change size. |
| **html5-speaker-click-start** | **`ClientAudio.test.mjs`** | Enough (user-gesture / `play()`). |
| **html5-menu-fixes** | **`Menu.test.mjs`** (vm harness for `rebindMenuHandlers`) | Short manual test plan in PR for toolbar/start menu still helps. |

**Removed (fork-only, not upstream):** ~~html5-audio-aac~~ — use `audio_codec=mediasource:aac+mpeg4` in deploy `default-settings.txt` (k3s-home) instead of reordering `PREFERRED_CODEC_ORDER`.

## Fork stack only (not `feat-upstream/`)

| Branch | Tests |
|--------|--------|
| **feat/html5-reconnect-patience** | **`ClientReconnect.test.mjs`** |
| Other fork feats | As on integration stack; no separate upstream PR. |
