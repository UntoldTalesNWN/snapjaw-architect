# Snapjaw Architect

A Turtle WoW / Vanilla 1.12 client addon for searching and placing NPCs and
GameObjects on the Snapjaw server using existing VMaNGOS GM commands.

No C++ core changes or server module are required.

## Version 1.0.0

The first version provides:

- Searchable NPC and GameObject catalogues
- Local search by name, subtitle, or entry ID
- Spawn buttons
- NPC info, deletion, and model change controls
- GameObject nearest-selection, information, and deletion controls
- Capture of the selected GameObject GUID from server chat
- Database exporter for generating the bundled Lua catalogues
- Server-side ZIP packaging

## Server setup

Place this project at:

    ~/snapjaw-architect

Then run:

    cd ~/snapjaw-architect
    chmod +x build.sh tools/export-addon-data.sh
    ./build.sh

The finished client addon is created at:

    dist/SnapjawArchitect.zip

The exporter assumes:

- Docker Compose project directory: `~/snapjaw`
- Database service: `database`
- World database: `tw_world`
- MariaDB root password available inside the container as
  `MARIADB_ROOT_PASSWORD`

Override these when needed:

    SNAPJAW_DIR=~/snapjaw \
    DB_SERVICE=database \
    WORLD_DB=tw_world \
    ./build.sh

## Client installation

Extract `dist/SnapjawArchitect.zip` into:

    Turtle WoW\Interface\AddOns\

The resulting path must be:

    Turtle WoW\Interface\AddOns\SnapjawArchitect\SnapjawArchitect.toc

Open the addon in-game with:

    /sja

or:

    /architect

## Important

The addon sends existing GM chat commands. The logged-in account must have the
required GM security level.

The generated files in `addon/SnapjawArchitect/Data/` are bundled with the
client addon. End users do not need database access or the export tools.
