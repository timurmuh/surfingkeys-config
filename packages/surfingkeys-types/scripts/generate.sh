#!/usr/bin/env bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
OUTPUT_DIR="${OUTPUT_DIR:-$(cd "$(dirname "$0")/../output" && pwd)}"
SURFINGKEYS_VERSION="${SURFINGKEYS_VERSION:-}"  # Will be auto-detected if empty
SURFINGKEYS_REPO="${SURFINGKEYS_REPO:-https://github.com/brookhong/Surfingkeys.git}"
CLEAN=false
AUTO_VERSION=false

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/../docker" && pwd)"

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Generate TypeScript definitions for Surfingkeys from JSDoc comments.

OPTIONS:
    -o, --output DIR        Output directory (default: ../output)
    -v, --version VERSION   Surfingkeys version/branch (default: master)
    -r, --repo URL          Repository URL (for forks)
    -c, --clean             Clean output directory first
    -h, --help              Show this help message

EXAMPLES:
    # Generate types from latest master
    $(basename "$0")

    # Generate types for specific version
    $(basename "$0") --version v1.16.2

    # Clean output and regenerate
    $(basename "$0") --clean

    # Use custom output directory
    $(basename "$0") --output /tmp/surfingkeys-types

ENVIRONMENT VARIABLES:
    OUTPUT_DIR              Default output directory
    SURFINGKEYS_VERSION     Default Surfingkeys version
    SURFINGKEYS_REPO        Default repository URL

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -v|--version)
            SURFINGKEYS_VERSION="$2"
            shift 2
            ;;
        -r|--repo)
            SURFINGKEYS_REPO="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate Docker is available
if ! command -v docker &> /dev/null; then
    error "Docker is not installed or not in PATH"
    exit 1
fi

# Default to master if not specified (Surfingkeys doesn't use version tags)
if [ -z "${SURFINGKEYS_VERSION}" ]; then
    SURFINGKEYS_VERSION="master"
    info "Using default: master branch"
    info "Note: Specify --version to use a different branch/commit"
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"
OUTPUT_DIR="$(cd "${OUTPUT_DIR}" && pwd)" # Get absolute path

# Clean output directory if requested
if [ "${CLEAN}" = true ]; then
    info "Cleaning output directory: ${OUTPUT_DIR}"
    rm -rf "${OUTPUT_DIR:?}"/*
fi

info "Generating TypeScript definitions for Surfingkeys"
info "Version: ${SURFINGKEYS_VERSION}"
info "Repository: ${SURFINGKEYS_REPO}"
info "Output: ${OUTPUT_DIR}"

# Build Docker image
info "Building Docker image..."
docker build \
    --build-arg SURFINGKEYS_REPO="${SURFINGKEYS_REPO}" \
    --build-arg SURFINGKEYS_VERSION="${SURFINGKEYS_VERSION}" \
    -t surfingkeys-types:latest \
    -f "${DOCKER_DIR}/Dockerfile" \
    "${DOCKER_DIR}/.." || {
    error "Docker build failed"
    exit 1
}

# Run Docker container
info "Running type generation..."
docker run --rm \
    -v "${OUTPUT_DIR}:/output" \
    surfingkeys-types:latest || {
    error "Type generation failed"
    exit 1
}

# Post-process: create index.d.ts
info "Post-processing generated types..."

# Find all generated .d.ts files
GENERATED_FILES=$(find "${OUTPUT_DIR}" -name "*.d.ts" -type f)

if [ -z "${GENERATED_FILES}" ]; then
    error "No .d.ts files were generated"
    exit 1
fi

# Create index.d.ts that declares the global API
INDEX_FILE="${OUTPUT_DIR}/index.d.ts"

cat > "${INDEX_FILE}" << 'EOF'
/**
 * TypeScript definitions for Surfingkeys
 * Generated from JSDoc comments in the Surfingkeys source code
 * @see https://github.com/brookhong/Surfingkeys
 */

/// <reference path="./content_scripts/common/api.d.ts" />
/// <reference path="./content_scripts/common/runtime.d.ts" />
/// <reference path="./content_scripts/common/clipboard.d.ts" />
/// <reference path="./content_scripts/common/utils.d.ts" />

import type createAPI from './content_scripts/common/api';

/**
 * The global Surfingkeys API object available in .surfingkeysrc
 */
declare global {
    const api: ReturnType<typeof createAPI>;
}

// Also export the API type for use in modules
export type SurfingkeysAPI = ReturnType<typeof createAPI>;
EOF

# Extract version number from tag (strip 'v' prefix if present)
PKG_VERSION="${SURFINGKEYS_VERSION#v}"
if [ "${PKG_VERSION}" = "master" ] || [ "${PKG_VERSION}" = "main" ]; then
    PKG_VERSION="0.0.0-dev"
fi

# Create package.json metadata
cat > "${OUTPUT_DIR}/package.json" << EOF
{
  "name": "surfingkeys-types",
  "version": "${PKG_VERSION}",
  "description": "TypeScript definitions for Surfingkeys ${SURFINGKEYS_VERSION}",
  "types": "index.d.ts",
  "keywords": [
    "surfingkeys",
    "typescript",
    "definitions",
    "types"
  ],
  "repository": {
    "type": "git",
    "url": "${SURFINGKEYS_REPO}"
  },
  "license": "MIT",
  "metadata": {
    "surfingkeysVersion": "${SURFINGKEYS_VERSION}",
    "generatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
}
EOF

info "Type generation complete!"
info "Output directory: ${OUTPUT_DIR}"
info "Main index: ${INDEX_FILE}"
info "Total .d.ts files: $(find "${OUTPUT_DIR}" -name "*.d.ts" | wc -l | tr -d ' ')"
info ""
info "To use these types in your .surfingkeysrc:"
info "  /// <reference types=\"./surfingkeys-types/output\" />"
