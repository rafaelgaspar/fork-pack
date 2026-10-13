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
tpl = (pack / "examples" / "rafaelgaspar-tag-bump.yaml").read_text()
text = (
    tpl.replace("https://github.com/EXAMPLE/upstream.git", m["upstream"])
    .replace("tag_glob: 'v*.*.*'", f"tag_glob: '{m['tag_glob']}'")
    .replace(
        "tag_filter: '^v[0-9]+\\.[0-9]+\\.[0-9]+$'",
        f"tag_filter: '{m['tag_filter']}'",
    )
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
