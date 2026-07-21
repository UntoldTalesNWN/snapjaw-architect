#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPJAW_DIR="${SNAPJAW_DIR:-$HOME/snapjaw}"
DB_SERVICE="${DB_SERVICE:-database}"
WORLD_DB="${WORLD_DB:-tw_world}"
DATA_DIR="$PROJECT_DIR/addon/SnapjawArchitect/Data"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ ! -d "$SNAPJAW_DIR" ]]; then
    echo "Snapjaw directory not found: $SNAPJAW_DIR" >&2
    exit 1
fi

mkdir -p "$DATA_DIR"

run_world_query() {
    local sql="$1"

    (
        cd "$SNAPJAW_DIR"
        docker compose exec -T "$DB_SERVICE" sh -lc \
            'mariadb \
                --batch \
                --raw \
                --skip-column-names \
                --user=root \
                --password="$MARIADB_ROOT_PASSWORD" \
                "$1" \
                --execute="$2"' \
            sh "$WORLD_DB" "$sql"
    )
}

echo "Exporting NPC templates..."
run_world_query "
SELECT
    entry,
    HEX(COALESCE(name, '')),
    HEX(COALESCE(subname, '')),
    COALESCE(display_id1, 0),
    COALESCE(faction, 0)
FROM creature_template
ORDER BY entry;
" > "$TMP_DIR/npcs.tsv"

echo "Exporting GameObject templates..."
run_world_query "
SELECT
    entry,
    HEX(COALESCE(name, '')),
    COALESCE(type, 0),
    COALESCE(displayId, 0)
FROM gameobject_template
ORDER BY entry;
" > "$TMP_DIR/gameobjects.tsv"

python3 "$PROJECT_DIR/tools/generate_lua_catalogs.py" \
    --npcs "$TMP_DIR/npcs.tsv" \
    --gameobjects "$TMP_DIR/gameobjects.tsv" \
    --output "$DATA_DIR" \
    --database "$WORLD_DB"

echo "Generated addon catalogues in:"
echo "  $DATA_DIR"
