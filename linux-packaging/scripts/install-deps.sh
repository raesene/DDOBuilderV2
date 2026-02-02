#!/bin/bash
# Install build dependencies for DDO Builder AppImage packaging
# Supports Ubuntu/Debian-based distributions

set -e

echo "Installing dependencies for DDO Builder AppImage packaging..."

# Enable 32-bit architecture (required for Wine32)
sudo dpkg --add-architecture i386
sudo apt update

# Install required packages
sudo apt install -y \
    wine32 \
    wine64 \
    winetricks \
    wget \
    p7zip-full \
    icoutils \
    libfuse2 \
    binutils \
    file

echo "Dependencies installed successfully."
echo ""
echo "You can now run the build script:"
echo "  DDOBUILDER_EXE=/path/to/DDOBuilder.exe ./build-appimage.sh"
