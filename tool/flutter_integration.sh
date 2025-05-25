#!/bin/bash

# Flutter Console Runner
# This script integrates the console app with Flutter's device management

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

case "$1" in
    "list-devices")
        echo "2 connected devices:"
        echo ""
        echo "Lore Console (desktop) • lore-console • linux • Lore Console Application"
        echo "Lore Console Interactive • lore-console-interactive • linux • Lore Console (Interactive Mode)"
        ;;
    "run-console")
        echo "🚀 Running Lore Console..."
        dart tool/flutter_console.dart run "${@:2}"
        ;;
    "build-console")
        echo "🛠️  Building Lore Console..."
        dart tool/flutter_console.dart build
        ;;
    *)
        echo "Usage: $0 {list-devices|run-console|build-console}"
        echo ""
        echo "Integration commands:"
        echo "  list-devices     List console targets as Flutter devices"
        echo "  run-console      Build and run console with arguments"
        echo "  build-console    Build the console executable"
        ;;
esac
