# DDO Builder AppImage Makefile
# Alternative build automation for local AppImage builds

PACKAGING_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_ROOT := $(shell dirname $(PACKAGING_DIR))
BUILD_DIR := $(PACKAGING_DIR)/build

# Default DDOBuilder.exe location
DDOBUILDER_EXE ?= $(PROJECT_ROOT)/Output/DDOBuilder.exe

.PHONY: all clean deps appimage help

all: appimage

help:
	@echo "DDO Builder AppImage Build System"
	@echo ""
	@echo "Targets:"
	@echo "  deps      - Install build dependencies (requires sudo)"
	@echo "  appimage  - Build the AppImage (requires DDOBuilder.exe)"
	@echo "  clean     - Remove build artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  DDOBUILDER_EXE  - Path to DDOBuilder.exe (default: Output/DDOBuilder.exe)"
	@echo "  DATA_DIR        - Path to DataFiles directory (auto-detected)"
	@echo "  WINE_VERSION    - Wine version to bundle (default: 9.0)"
	@echo ""
	@echo "Examples:"
	@echo "  make deps"
	@echo "  make appimage"
	@echo "  make appimage DDOBUILDER_EXE=/path/to/DDOBuilder.exe"

deps:
	@echo "Installing build dependencies..."
	$(PACKAGING_DIR)/scripts/install-deps.sh

appimage:
	@if [ ! -f "$(DDOBUILDER_EXE)" ]; then \
		echo "Error: DDOBuilder.exe not found at $(DDOBUILDER_EXE)"; \
		echo "Set DDOBUILDER_EXE to the correct path"; \
		exit 1; \
	fi
	DDOBUILDER_EXE="$(DDOBUILDER_EXE)" $(PACKAGING_DIR)/scripts/package-appimage.sh

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(PROJECT_ROOT)/DDOBuilder-*.AppImage
