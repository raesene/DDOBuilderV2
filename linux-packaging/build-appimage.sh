#!/bin/bash
# build-appimage.sh - Wrapper script for local AppImage builds
#
# Usage:
#   DDOBUILDER_EXE=/path/to/DDOBuilder.exe ./build-appimage.sh
#
# Or if DDOBuilder.exe is in the Output directory:
#   ./build-appimage.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Try to auto-detect DDOBuilder.exe if not specified
if [ -z "$DDOBUILDER_EXE" ]; then
    # Check common locations
    for path in \
        "$PROJECT_ROOT/Output/DDOBuilder.exe" \
        "$PROJECT_ROOT/Release/DDOBuilder.exe" \
        "$PROJECT_ROOT/DDOBuilder.exe"
    do
        if [ -f "$path" ]; then
            export DDOBUILDER_EXE="$path"
            echo "Auto-detected DDOBuilder.exe at: $path"
            break
        fi
    done
fi

if [ -z "$DDOBUILDER_EXE" ]; then
    echo "Error: Could not find DDOBuilder.exe"
    echo ""
    echo "Please specify the path to DDOBuilder.exe:"
    echo "  DDOBUILDER_EXE=/path/to/DDOBuilder.exe $0"
    echo ""
    echo "Or build the Windows application first and place it in Output/"
    exit 1
fi

# Run the packaging script
exec "$SCRIPT_DIR/scripts/package-appimage.sh"
