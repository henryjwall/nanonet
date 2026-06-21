#!/usr/bin/env bash
# Build the nanonet Vivado 2020.1 build-host image.
#
#   x86-64 ONLY — this will NOT build at usable speed on Apple Silicon.
#   Run it on the x86 build VM or any amd64 Linux host. See docker/README.md.
#
# Usage:
#   ./docker/build.sh <path-to-Xilinx_Unified_2020.1_*.tar.gz> [image-tag]
set -euo pipefail

INSTALLER_PATH="${1:?usage: build.sh <path-to-Xilinx_Unified_2020.1_*.tar.gz> [image-tag]}"
TAG="${2:-nanonet/vivado:2020.1}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$INSTALLER_PATH" ]]; then
    echo "error: installer not found: $INSTALLER_PATH" >&2
    exit 1
fi

# The installer must live inside the build context (repo root) so COPY can see it.
INSTALLER_NAME="$(basename "$INSTALLER_PATH")"
if [[ ! -f "$REPO_ROOT/$INSTALLER_NAME" ]]; then
    echo "Copying installer into build context: $REPO_ROOT/$INSTALLER_NAME"
    cp "$INSTALLER_PATH" "$REPO_ROOT/$INSTALLER_NAME"
fi

docker build \
    --platform linux/amd64 \
    --build-arg INSTALLER="$INSTALLER_NAME" \
    -t "$TAG" \
    -f "$REPO_ROOT/docker/Dockerfile" \
    "$REPO_ROOT"

echo "Built $TAG"
echo "Smoke test:  docker run --rm --platform linux/amd64 $TAG vivado -version"
