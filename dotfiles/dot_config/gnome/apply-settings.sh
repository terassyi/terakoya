#!/bin/bash
# Apply GNOME settings via dconf
# This script loads the dconf settings

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$SCRIPT_DIR/dconf-settings.ini"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Error: Settings file not found: $SETTINGS_FILE"
    exit 1
fi

# Check if running on Linux with GNOME
if [ "$(uname -s)" != "Linux" ]; then
    echo "Skipping GNOME settings (not on Linux)"
    exit 0
fi

if ! command -v dconf &> /dev/null; then
    echo "Warning: dconf not found, skipping GNOME settings"
    exit 0
fi

echo "Applying GNOME dconf settings..."
dconf load / < "$SETTINGS_FILE"
echo "GNOME settings applied successfully"
