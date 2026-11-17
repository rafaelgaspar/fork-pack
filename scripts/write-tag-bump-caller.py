#!/usr/bin/env python3
"""Write a thin rafaelgaspar-tag-bump.yaml for a fork listed in members.yaml."""
from __future__ import annotations

import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML required")

pack = Path(__file__).resolve().parent.parent
name = sys.argv[1] if len(sys.argv) > 1 else ""
dest = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("-")
if not name:
    sys.exit("usage: write-tag-bump-caller.py <fork-name> <dest-yaml>")

members = yaml.safe_load((pack / "members.yaml").read_text())["forks"]
m = members[name]
tracks = m.get("tracks", "tag")
if tracks not in ("tag", "branch"):
    sys.exit(f"invalid tracks={tracks!r} for {name} (use tag or branch)")
branch = m.get("upstream_branch")
if tracks == "branch" and not branch:
    sys.exit(f"upstream_branch required when tracks=branch for {name}")
if tracks == "tag" and branch:
    sys.exit(f"upstream_branch is only valid with tracks=branch ({name})")

tpl = (pack / "examples" / "rafaelgaspar-tag-bump.yaml").read_text()
tracks_block = f"      tracks: {tracks}\n"
if branch:
    tracks_block += f"      upstream_branch: {branch}\n"
text = (
    tpl.replace("https://github.com/EXAMPLE/upstream.git", m["upstream"])
    .replace("tag_glob: 'v*.*.*'", f"tag_glob: '{m['tag_glob']}'")
    .replace(
        "tag_filter: '^v[0-9]+\\.[0-9]+\\.[0-9]+$'",
        f"tag_filter: '{m['tag_filter']}'",
    )
    .replace("      tracks: tag\n", tracks_block, 1)
    .replace("rafaelgaspar-ghcr-publish.yaml", m["publish_workflow"])
)
if m["publish_workflow"] == "rafaelgaspar-release.yaml":
    head, sep, tail = text.rpartition("  publish:\n")
    if not sep:
        sys.exit("publish job not found in template")
    tail = tail.replace(
        """    permissions:
      contents: write
      packages: write
""",
        """    permissions:
      contents: write
""",
        1,
    )
    text = head + sep + tail

dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text(text)
print(f"wrote {dest}")
