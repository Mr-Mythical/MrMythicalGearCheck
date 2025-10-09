#!/bin/bash

# Mr. Mythical Gear Optimizer Release Script
# This script packages the addon for distribution

ADDON_NAME="MrMythicalGear"
VERSION=${1:-"dev"}
EXCLUDE_FILES=".git* release.sh *.md CONTRIBUTING.md"

echo "Creating release package for Mr. Mythical Gear Optimizer v$VERSION"

# Create release directory
mkdir -p "releases"
RELEASE_DIR="releases/${ADDON_NAME}-${VERSION}"

# Clean any existing release directory
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy addon files
echo "Copying addon files..."
cp -r . "$RELEASE_DIR/" 2>/dev/null || true

# Remove excluded files
echo "Cleaning release directory..."
cd "$RELEASE_DIR"
for exclude in $EXCLUDE_FILES; do
    rm -rf $exclude 2>/dev/null || true
done

# Remove release directory from within itself
rm -rf releases 2>/dev/null || true

# Create zip package
cd ..
echo "Creating zip package..."
zip -r "${ADDON_NAME}-${VERSION}.zip" "${ADDON_NAME}-${VERSION}/" -x "*.DS_Store" "*/.*"

echo "Release package created: releases/${ADDON_NAME}-${VERSION}.zip"
echo "Release directory: releases/${ADDON_NAME}-${VERSION}/"

# Print package contents
echo ""
echo "Package contents:"
cd "${ADDON_NAME}-${VERSION}"
find . -type f | sort
