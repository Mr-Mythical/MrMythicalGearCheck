#!/bin/bash

# Semantic versioning release script
# Usage: ./release.sh [major|minor|patch] "commit message"

set -e

# Function to get the latest tag
get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"
}

# Function to increment version
increment_version() {
    local version=$1
    local type=$2
    
    # Remove 'v' prefix if present
    version=${version#v}
    
    # Split version into parts
    IFS='.' read -ra PARTS <<< "$version"
    major=${PARTS[0]:-0}
    minor=${PARTS[1]:-0}
    patch=${PARTS[2]:-0}
    
    case $type in
        major)
            ((major++))
            minor=0
            patch=0
            ;;
        minor)
            ((minor++))
            patch=0
            ;;
        patch)
            ((patch++))
            ;;
        *)
            echo "Invalid version type. Use: major, minor, or patch"
            exit 1
            ;;
    esac
    
    echo "v$major.$minor.$patch"
}

# Get parameters
VERSION_TYPE=$1
COMMIT_MESSAGE=$2

if [ -z "$VERSION_TYPE" ] || [ -z "$COMMIT_MESSAGE" ]; then
    echo "Usage: $0 [major|minor|patch] \"commit message\""
    echo ""
    echo "Examples:"
    echo "  $0 patch \"Fix bug in tooltip display\""
    echo "  $0 minor \"Add new feature for dungeon tracking\""
    echo "  $0 major \"Breaking change: new API structure\""
    exit 1
fi

# Get current version and calculate new version
CURRENT_VERSION=$(get_latest_tag)
NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$VERSION_TYPE")

echo "Current version: $CURRENT_VERSION"
echo "New version: $NEW_VERSION"
echo "Commit message: $COMMIT_MESSAGE"
echo ""

# Confirm with user
read -p "Proceed with release? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release cancelled."
    exit 1
fi

# Stage all changes
git add .

# Create commit
git commit -m "$COMMIT_MESSAGE"

# Create annotated tag
git tag -a "$NEW_VERSION" -m "$NEW_VERSION: $COMMIT_MESSAGE"

# Push with tags
git push --follow-tags

echo ""
echo "✅ Release $NEW_VERSION completed successfully!"
echo "📝 Commit: $COMMIT_MESSAGE"
echo "🏷️  Tag: $NEW_VERSION"
echo "🚀 Pushed to remote with tags"
