#!/usr/bin/env bash
# Runs the game from a terminal. Imports assets first: Godot's import cache
# (game/.godot) is not committed, and without it no sprites can load.
set -euo pipefail
cd "$(dirname "$0")/game"

GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
	for candidate in godot godot4 /Applications/Godot.app/Contents/MacOS/Godot; do
		if command -v "$candidate" >/dev/null 2>&1; then
			GODOT="$candidate"
			break
		fi
	done
fi
if [[ -z "$GODOT" ]]; then
	echo "Godot not found. Install Godot 4.7, or set GODOT=/path/to/godot." >&2
	exit 1
fi

"$GODOT" --headless --path . --import
exec "$GODOT" --path . "$@"
