#!/bin/bash

# Lore Console Custom Device Script
# This script allows the console app to be treated as a Flutter device target

COMMAND="$1"
shift

case "$COMMAND" in
    "list")
        echo '[{"id": "lore-console", "name": "Lore Console", "platform": "custom", "emulator": false, "category": "desktop", "platformType": {"name": "custom"}}]'
        ;;
    "install")
        # Build the console app
        echo "Building Lore Console..."
        dart tool/build_console.dart
        if [ $? -eq 0 ]; then
            echo "Lore Console built successfully at bin/lore"
        else
            echo "Failed to build Lore Console"
            exit 1
        fi
        ;;
    "launch")
        # Launch the console app
        echo "Launching Lore Console..."
        ./bin/lore "$@"
        ;;
    "forward")
        # Not applicable for console apps
        echo "Port forwarding not supported for console apps"
        ;;
    "stop")
        # Kill any running console processes
        pkill -f "bin/lore" 2>/dev/null || true
        echo "Stopped Lore Console"
        ;;
    *)
        echo "Usage: $0 {list|install|launch|forward|stop}"
        exit 1
        ;;
esac
