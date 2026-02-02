#!/bin/bash
# package-appimage.sh - Build DDO Builder AppImage
# This script packages DDOBuilder.exe with Wine into a self-contained AppImage

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGING_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$PACKAGING_DIR")"
BUILD_DIR="${BUILD_DIR:-$PACKAGING_DIR/build}"
APPDIR="$BUILD_DIR/DDOBuilder.AppDir"
WINE_VERSION="${WINE_VERSION:-9.0}"

# Required inputs
DDOBUILDER_EXE="${DDOBUILDER_EXE:-}"
DATA_DIR="${DATA_DIR:-}"
DEFAULT_INI="${DEFAULT_INI:-}"
EXAMPLE_BUILDS_DIR="${EXAMPLE_BUILDS_DIR:-}"

# Validation
if [ -z "$DDOBUILDER_EXE" ] || [ ! -f "$DDOBUILDER_EXE" ]; then
    echo "Error: DDOBUILDER_EXE must point to a valid DDOBuilder.exe"
    echo "Usage: DDOBUILDER_EXE=/path/to/DDOBuilder.exe $0"
    exit 1
fi

# Auto-detect data directory if not specified
if [ -z "$DATA_DIR" ]; then
    DETECTED_DATA_DIR="$(dirname "$DDOBUILDER_EXE")/DataFiles"
    if [ -d "$DETECTED_DATA_DIR" ]; then
        DATA_DIR="$DETECTED_DATA_DIR"
        echo "Auto-detected DATA_DIR: $DATA_DIR"
    fi
fi

# Auto-detect Default.ini if not specified
if [ -z "$DEFAULT_INI" ]; then
    DETECTED_INI="$(dirname "$DDOBUILDER_EXE")/Default.ini"
    if [ -f "$DETECTED_INI" ]; then
        DEFAULT_INI="$DETECTED_INI"
        echo "Auto-detected DEFAULT_INI: $DEFAULT_INI"
    fi
fi

# Auto-detect Example Builds if not specified
if [ -z "$EXAMPLE_BUILDS_DIR" ]; then
    DETECTED_EXAMPLES="$(dirname "$DDOBUILDER_EXE")/Example Builds"
    if [ -d "$DETECTED_EXAMPLES" ]; then
        EXAMPLE_BUILDS_DIR="$DETECTED_EXAMPLES"
        echo "Auto-detected EXAMPLE_BUILDS_DIR: $EXAMPLE_BUILDS_DIR"
    fi
fi

echo "=========================================="
echo "DDO Builder AppImage Packager"
echo "=========================================="
echo "DDOBuilder.exe: $DDOBUILDER_EXE"
echo "DataFiles: ${DATA_DIR:-<not found>}"
echo "Default.ini: ${DEFAULT_INI:-<not found>}"
echo "Example Builds: ${EXAMPLE_BUILDS_DIR:-<not found>}"
echo "Build directory: $BUILD_DIR"
echo "Wine version: $WINE_VERSION"
echo "=========================================="

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$APPDIR"

# Download Wine Staging
echo ""
echo "Downloading Wine Staging $WINE_VERSION..."
# Kron4ek Wine-Builds uses format: wine-X.Y-staging-amd64.tar.xz
WINE_TARBALL="wine-$WINE_VERSION-staging-amd64.tar.xz"
WINE_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/$WINE_VERSION/$WINE_TARBALL"

if [ ! -f "$BUILD_DIR/$WINE_TARBALL" ]; then
    echo "Downloading from: $WINE_URL"
    wget -q --show-progress -O "$BUILD_DIR/$WINE_TARBALL" "$WINE_URL" || {
        echo "Failed to download Wine from Kron4ek. Trying alternative..."
        # Try wow64 variant (doesn't require 32-bit libs)
        WINE_TARBALL="wine-$WINE_VERSION-staging-amd64-wow64.tar.xz"
        WINE_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/$WINE_VERSION/$WINE_TARBALL"
        echo "Trying: $WINE_URL"
        wget -q --show-progress -O "$BUILD_DIR/$WINE_TARBALL" "$WINE_URL" || {
            echo "Error: Could not download Wine. Please check the version or URL."
            exit 1
        }
    }
fi

echo "Extracting Wine..."
tar -xf "$BUILD_DIR/$WINE_TARBALL" -C "$BUILD_DIR"
# The extracted directory is named wine-X.Y-staging-amd64 or similar
WINE_EXTRACTED=$(find "$BUILD_DIR" -maxdepth 1 -type d -name "wine-*" | head -1)
if [ -z "$WINE_EXTRACTED" ]; then
    echo "Error: Could not find extracted Wine directory"
    exit 1
fi
mv "$WINE_EXTRACTED" "$APPDIR/wine"

# Create Wine prefix
echo ""
echo "Creating Wine prefix..."
export WINEPREFIX="$APPDIR/prefix"
export WINEARCH=win32
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree=disabled;mshtml=disabled"
export PATH="$APPDIR/wine/bin:$PATH"

# Initialize Wine prefix
"$APPDIR/wine/bin/wineboot" --init

# Wait for Wine to finish initialization
"$APPDIR/wine/bin/wineserver" --wait

# Update winetricks to get latest checksums (distro version is often outdated)
echo ""
echo "Updating winetricks..."
WINETRICKS_LATEST=$(mktemp)
wget -q -O "$WINETRICKS_LATEST" "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
chmod +x "$WINETRICKS_LATEST"

# Install dependencies with updated winetricks
echo ""
echo "Installing Wine dependencies (vcrun2019, msxml3)..."
"$WINETRICKS_LATEST" -q win10
"$WINETRICKS_LATEST" -q vcrun2019
"$WINETRICKS_LATEST" -q msxml3
rm -f "$WINETRICKS_LATEST"

# Wait for winetricks to finish
"$APPDIR/wine/bin/wineserver" --wait

# Create application directory in Wine prefix
APP_INSTALL_DIR="$WINEPREFIX/drive_c/DDOBuilder"
mkdir -p "$APP_INSTALL_DIR"

# Copy DDOBuilder.exe
echo ""
echo "Copying DDOBuilder.exe..."
cp "$DDOBUILDER_EXE" "$APP_INSTALL_DIR/"

# Copy DataFiles if available
if [ -n "$DATA_DIR" ] && [ -d "$DATA_DIR" ]; then
    echo "Copying DataFiles..."
    cp -r "$DATA_DIR" "$APP_INSTALL_DIR/"
fi

# Copy Default.ini if available
if [ -n "$DEFAULT_INI" ] && [ -f "$DEFAULT_INI" ]; then
    echo "Copying Default.ini..."
    cp "$DEFAULT_INI" "$APP_INSTALL_DIR/"
fi

# Copy Example Builds if available
if [ -n "$EXAMPLE_BUILDS_DIR" ] && [ -d "$EXAMPLE_BUILDS_DIR" ]; then
    echo "Copying Example Builds..."
    cp -r "$EXAMPLE_BUILDS_DIR" "$APP_INSTALL_DIR/"
fi

# Extract icon from DDOBuilder.exe
echo ""
echo "Extracting application icon..."
if command -v wrestool &> /dev/null && command -v icotool &> /dev/null; then
    # Try to extract icon from the executable
    wrestool -x -t 14 "$DDOBUILDER_EXE" -o "$BUILD_DIR/icon.ico" 2>/dev/null || true
    if [ -f "$BUILD_DIR/icon.ico" ]; then
        icotool -x -o "$BUILD_DIR/" "$BUILD_DIR/icon.ico" 2>/dev/null || true
        # Find the largest PNG
        LARGEST_ICON=$(ls -S "$BUILD_DIR"/*.png 2>/dev/null | head -1)
        if [ -n "$LARGEST_ICON" ]; then
            cp "$LARGEST_ICON" "$APPDIR/ddo-builder.png"
        fi
    fi
fi

# If icon extraction failed, check for icon in project resources
if [ ! -f "$APPDIR/ddo-builder.png" ]; then
    # Look for existing icon in project
    for icon_path in "$PROJECT_ROOT/DDOBuilder/res/DDOBuilder.ico" "$PROJECT_ROOT/res/DDOBuilder.ico"; do
        if [ -f "$icon_path" ]; then
            if command -v icotool &> /dev/null; then
                icotool -x -o "$BUILD_DIR/" "$icon_path" 2>/dev/null || true
                LARGEST_ICON=$(ls -S "$BUILD_DIR"/*.png 2>/dev/null | head -1)
                if [ -n "$LARGEST_ICON" ]; then
                    cp "$LARGEST_ICON" "$APPDIR/ddo-builder.png"
                    break
                fi
            fi
        fi
    done
fi

# Fallback: create a simple placeholder icon
if [ ! -f "$APPDIR/ddo-builder.png" ]; then
    echo "Warning: Could not extract icon, using placeholder"
    # Create a simple 256x256 PNG (solid color) - requires ImageMagick
    if command -v convert &> /dev/null; then
        convert -size 256x256 xc:#4a90d9 "$APPDIR/ddo-builder.png" 2>/dev/null || true
    fi
fi

# Create AppRun launcher
echo ""
echo "Creating AppRun launcher..."
cp "$PACKAGING_DIR/resources/AppRun.template" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"

# Create desktop file
echo "Creating desktop entry..."
cp "$PACKAGING_DIR/resources/ddo-builder.desktop" "$APPDIR/ddo-builder.desktop"

# Clean up Wine prefix to reduce size
echo ""
echo "Cleaning Wine prefix..."
rm -rf "$WINEPREFIX/drive_c/windows/Installer"
rm -rf "$WINEPREFIX/drive_c/users"/*/.cache
rm -rf "$WINEPREFIX/drive_c/users"/*/.wine
rm -rf "$WINEPREFIX/drive_c/windows/temp"/*
find "$WINEPREFIX" -name "*.log" -delete 2>/dev/null || true

# Clean up Wine installation to reduce size
echo "Optimizing Wine installation..."
rm -rf "$APPDIR/wine/share/man"
rm -rf "$APPDIR/wine/share/doc"
rm -rf "$APPDIR/wine/share/applications"

# Download appimagetool
echo ""
echo "Downloading appimagetool..."
APPIMAGETOOL="$BUILD_DIR/appimagetool"
if [ ! -f "$APPIMAGETOOL" ]; then
    wget -q --show-progress -O "$APPIMAGETOOL" \
        "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGETOOL"
fi

# Build AppImage
echo ""
echo "Building AppImage..."
cd "$BUILD_DIR"

# Get version from tag or default
VERSION="${GITHUB_REF_NAME:-$(date +%Y%m%d)}"
VERSION="${VERSION#v}"  # Remove 'v' prefix if present

ARCH=x86_64 "$APPIMAGETOOL" --no-appstream "$APPDIR" "DDOBuilder-$VERSION-x86_64.AppImage"

# Move to project root
mv "DDOBuilder-$VERSION-x86_64.AppImage" "$PROJECT_ROOT/"

echo ""
echo "=========================================="
echo "AppImage built successfully!"
echo "Output: $PROJECT_ROOT/DDOBuilder-$VERSION-x86_64.AppImage"
echo "=========================================="

# Print size information
echo ""
echo "Size breakdown:"
du -sh "$APPDIR/wine" 2>/dev/null || echo "  Wine: <unknown>"
du -sh "$APPDIR/prefix" 2>/dev/null || echo "  Prefix: <unknown>"
du -sh "$PROJECT_ROOT/DDOBuilder-$VERSION-x86_64.AppImage" 2>/dev/null || echo "  AppImage: <unknown>"
