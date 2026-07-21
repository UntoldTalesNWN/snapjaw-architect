#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON_PARENT="$PROJECT_DIR/addon"
ADDON_DIR="$ADDON_PARENT/SnapjawArchitect"
DIST_DIR="$PROJECT_DIR/dist"
OUTPUT="$DIST_DIR/SnapjawArchitect.zip"

SKIP_EXPORT=0
if [[ "${1:-}" == "--skip-export" ]]; then
    SKIP_EXPORT=1
fi

if (( SKIP_EXPORT == 0 )); then
    "$PROJECT_DIR/tools/export-addon-data.sh"
fi

python3 "$PROJECT_DIR/tools/validate_addon.py" "$ADDON_DIR"

mkdir -p "$DIST_DIR"
rm -f "$OUTPUT"

python3 - "$ADDON_PARENT" "$OUTPUT" <<'PY'
from pathlib import Path
import sys
import zipfile

addon_parent = Path(sys.argv[1])
output = Path(sys.argv[2])
addon_dir = addon_parent / "SnapjawArchitect"

with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(addon_dir.rglob("*")):
        if path.is_file():
            archive.write(path, path.relative_to(addon_parent))

print(f"Created {output}")
PY

echo
echo "Snapjaw Architect build complete:"
echo "  $OUTPUT"
