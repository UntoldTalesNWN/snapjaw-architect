#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import datetime as dt
from pathlib import Path
from typing import Iterable


def lua_string(value: str) -> str:
    value = value.replace("\\", "\\\\")
    value = value.replace('"', '\\"')
    value = value.replace("\r", "\\r")
    value = value.replace("\n", "\\n")
    value = value.replace("\t", "\\t")
    return f'"{value}"'


def read_tsv(path: Path, expected_columns: int) -> Iterable[list[str]]:
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line_number, raw_line in enumerate(handle, start=1):
            line = raw_line.rstrip("\r\n")
            if not line:
                continue

            columns = line.split("\t")
            if len(columns) != expected_columns:
                raise ValueError(
                    f"{path}:{line_number}: expected {expected_columns} columns, "
                    f"received {len(columns)}"
                )
            yield columns


def safe_int(value: str) -> int:
    try:
        return int(value)
    except ValueError:
        return 0


def decode_hex(value: str) -> str:
    try:
        return bytes.fromhex(value).decode("utf-8", errors="replace")
    except ValueError:
        return value



def build_search_index(*fields: object) -> str:
    """Create searchable words and useful joined variants.

    CamelCase is split before normalization:
        NightElf  -> night, elf, nightelf
        OrcTents  -> orc, tents, orctents

    This lets a query such as "night elf" match "NightElf" while preventing
    matches that cross unrelated word boundaries.
    """
    indexed_words: list[str] = []
    seen: set[str] = set()

    def add_word(word: str) -> None:
        if word and word not in seen:
            seen.add(word)
            indexed_words.append(word)

    for field in fields:
        original = str(field or "")

        # Split CamelCase and letter/number transitions before lowercasing.
        separated = re.sub(
            r"(?<=[a-z0-9])(?=[A-Z])",
            " ",
            original,
        )
        separated = re.sub(
            r"(?<=[A-Za-z])(?=[0-9])|(?<=[0-9])(?=[A-Za-z])",
            " ",
            separated,
        )

        words = re.findall(r"[0-9a-z]+", separated.lower())

        for word in words:
            add_word(word)

        # Joined adjacent words support searches such as "nightelf".
        for width in (2, 3):
            for start in range(0, len(words) - width + 1):
                add_word("".join(words[start:start + width]))

    return " ".join(indexed_words)

def write_npcs(source: Path, target: Path) -> int:
    rows = []

    for entry, name, subname, display_id, faction in read_tsv(source, 5):
        decoded_name = decode_hex(name)
        decoded_subname = decode_hex(subname)

        rows.append(
            (
                safe_int(entry),
                decoded_name,
                decoded_subname,
                safe_int(display_id),
                safe_int(faction),
            )
        )

    rows.sort(key=lambda row: (row[1].lower(), row[0]))

    with target.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write("-- AUTO-GENERATED FILE. DO NOT EDIT MANUALLY.\n")
        handle.write("-- Regenerate with tools/export-addon-data.sh.\n\n")
        handle.write("SnapjawArchitectNPCs = {\n")

        for entry, name, subname, display_id, faction in rows:
            search_index = build_search_index(
                entry,
                name,
                subname,
            )

            handle.write(
                "    { "
                f"entry = {entry}, "
                f"name = {lua_string(name)}, "
                f"subname = {lua_string(subname)}, "
                f"displayId = {display_id}, "
                f"faction = {faction}, "
                f"searchIndex = {lua_string(search_index)} "
                "},\n"
            )

        handle.write("}\n")

    return len(rows)


def write_gameobjects(source: Path, target: Path) -> int:
    rows = []

    for entry, name, object_type, display_id in read_tsv(source, 4):
        decoded_name = decode_hex(name)

        rows.append(
            (
                safe_int(entry),
                decoded_name,
                safe_int(object_type),
                safe_int(display_id),
            )
        )

    rows.sort(key=lambda row: (row[1].lower(), row[0]))

    with target.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write("-- AUTO-GENERATED FILE. DO NOT EDIT MANUALLY.\n")
        handle.write("-- Regenerate with tools/export-addon-data.sh.\n\n")
        handle.write("SnapjawArchitectGameObjects = {\n")

        for entry, name, object_type, display_id in rows:
            search_index = build_search_index(
                entry,
                name,
            )

            handle.write(
                "    { "
                f"entry = {entry}, "
                f"name = {lua_string(name)}, "
                f"type = {object_type}, "
                f"displayId = {display_id}, "
                f"searchIndex = {lua_string(search_index)} "
                "},\n"
            )

        handle.write("}\n")

    return len(rows)

def write_build_info(
    target: Path,
    database: str,
    npc_count: int,
    gameobject_count: int,
) -> None:
    generated_at = dt.datetime.now().astimezone().isoformat(timespec="seconds")

    with target.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write("-- AUTO-GENERATED FILE. DO NOT EDIT MANUALLY.\n\n")
        handle.write("SnapjawArchitectBuildInfo = {\n")
        handle.write(f"    generatedAt = {lua_string(generated_at)},\n")
        handle.write(f"    database = {lua_string(database)},\n")
        handle.write(f"    npcCount = {npc_count},\n")
        handle.write(f"    gameObjectCount = {gameobject_count},\n")
        handle.write('    version = "1.0.0",\n')
        handle.write("}\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--npcs", required=True, type=Path)
    parser.add_argument("--gameobjects", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--database", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    npc_count = write_npcs(args.npcs, args.output / "NPCs.lua")
    gameobject_count = write_gameobjects(
        args.gameobjects,
        args.output / "GameObjects.lua",
    )
    write_build_info(
        args.output / "BuildInfo.lua",
        args.database,
        npc_count,
        gameobject_count,
    )

    print(f"NPC templates: {npc_count}")
    print(f"GameObject templates: {gameobject_count}")


if __name__ == "__main__":
    main()
