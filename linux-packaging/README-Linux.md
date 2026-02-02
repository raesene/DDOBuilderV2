# DDO Builder V2 - Linux AppImage

This directory contains the tooling to package DDO Builder V2 as a self-contained AppImage for Linux.

## What is an AppImage?

An AppImage is a portable Linux application format that bundles all dependencies into a single executable file. The DDO Builder AppImage includes:

- **Wine** - Windows compatibility layer
- **DDOBuilder.exe** - The Windows application
- **DataFiles** - All game data (classes, races, items, etc.)
- **Required DLLs** - Visual C++ runtime, MSXML3

The resulting AppImage is ~500-700 MB and runs on most Linux distributions without installing Wine system-wide.

## Quick Start

### Option 1: Download Pre-built AppImage (Recommended)

Download the latest AppImage from the [Releases](../../releases) page, then:

```bash
chmod +x DDOBuilder-*.AppImage
./DDOBuilder-*.AppImage
```

### Option 2: Build from GitHub Actions

1. Fork this repository
2. Push a version tag to trigger the build:
   ```bash
   git tag v2.0.0.71
   git push origin v2.0.0.71
   ```
3. The AppImage will be built and attached to the GitHub Release

### Option 3: Build Locally

If you have a Windows-built DDOBuilder.exe:

```bash
# Install dependencies (first time only)
cd linux-packaging
./scripts/install-deps.sh

# Build AppImage
DDOBUILDER_EXE=/path/to/DDOBuilder.exe ./build-appimage.sh
```

Or using make:
```bash
make deps
make appimage DDOBUILDER_EXE=/path/to/DDOBuilder.exe
```

## System Requirements

**To run the AppImage:**
- Linux kernel 4.15 or later
- glibc 2.27 or later (Ubuntu 18.04+, Fedora 28+, etc.)
- FUSE (for AppImage mounting)
- ~1 GB disk space

**To build the AppImage:**
- Ubuntu 22.04 or similar
- 32-bit Wine support
- winetricks
- wget, icoutils

## Tested Distributions

| Distribution | Status |
|-------------|--------|
| Ubuntu 22.04 LTS | ✅ Tested |
| Ubuntu 24.04 LTS | ✅ Tested |
| Fedora 39+ | ✅ Should work |
| Linux Mint 21+ | ✅ Should work |
| Arch Linux | ✅ Should work |
| Debian 12+ | ✅ Should work |

## Troubleshooting

### "FUSE not found" error

Install FUSE:
```bash
# Ubuntu/Debian
sudo apt install libfuse2

# Fedora
sudo dnf install fuse

# Arch
sudo pacman -S fuse2
```

### AppImage won't start

Try running from terminal to see error messages:
```bash
./DDOBuilder-*.AppImage
```

### Wine errors

The AppImage bundles its own Wine, but if you see graphics issues, try:
```bash
# Force software rendering
LIBGL_ALWAYS_SOFTWARE=1 ./DDOBuilder-*.AppImage
```

### Extracting the AppImage

If you need to extract the contents:
```bash
./DDOBuilder-*.AppImage --appimage-extract
```

This creates a `squashfs-root` directory with all files.

## File Locations

When running the AppImage:

| Data | Location |
|------|----------|
| User saves | `~/.local/share/ddo-builder/` |
| Wine prefix | Bundled inside AppImage |
| Application data | Bundled inside AppImage |

## Fork Maintenance

This packaging is designed to be maintained as a fork of the upstream DDO Builder repository. All files are in directories that don't exist upstream (`.github/workflows/` and `linux-packaging/`), ensuring clean merges.

### Syncing with Upstream

```bash
# Add upstream remote (first time only)
git remote add upstream https://github.com/Maetrim/DDOBuilderV2.git

# Fetch and merge upstream changes
git fetch upstream
git checkout main
git merge upstream/main
git push origin main

# Create new release
git tag v2.0.0.XX
git push origin v2.0.0.XX
```

## Technical Details

### Wine Configuration

The AppImage bundles Wine Staging 9.0 with a pre-configured 32-bit prefix containing:

- `vcrun2019` - Visual C++ 2019 runtime (required for MFC)
- `msxml3` - MSXML3 COM component (required for XML parsing)
- Windows 10 compatibility mode

### AppImage Structure

```
DDOBuilder.AppDir/
├── AppRun                    # Launcher script
├── ddo-builder.desktop       # Desktop integration
├── ddo-builder.png           # Application icon
├── wine/                     # Bundled Wine (~300 MB)
│   ├── bin/
│   └── lib/
└── prefix/                   # Wine prefix (~200 MB)
    └── drive_c/
        └── DDOBuilder/       # Application + data files
```

## License

The Linux packaging scripts are provided under the same license as DDO Builder V2. Wine is licensed under LGPL.
