#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("Usage: validate_addon.py ADDON_DIRECTORY")

    addon_dir = Path(sys.argv[1])
    toc = addon_dir / "SnapjawArchitect.toc"

    required = [
        toc,
        addon_dir / "Core.lua",
        addon_dir / "UI.lua",
        addon_dir / "Data" / "BuildInfo.lua",
        addon_dir / "Data" / "NPCs.lua",
        addon_dir / "Data" / "GameObjects.lua",
    ]

    for path in required:
        if not path.is_file():
            fail(f"Required file missing: {path}")

    toc_text = toc.read_text(encoding="utf-8")
    if "## Interface: 11200" not in toc_text:
        fail("SnapjawArchitect.toc does not target Interface 11200.")

    for lua_file in addon_dir.rglob("*.lua"):
        text = lua_file.read_text(encoding="utf-8")
        if "\x00" in text:
            fail(f"NUL byte found in {lua_file}")

        if re.search(r"\bcontinue\b", text):
            fail(f"Unsupported Lua keyword 'continue' found in {lua_file}")

    print("Addon validation passed.")


if __name__ == "__main__":
    main()
