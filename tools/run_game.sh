#!/usr/bin/env bash
set -euo pipefail

# Resolve the project root (where project.godot lives).
PROJECT_DIR="${BUILD_WORKSPACE_DIRECTORY:-.}"

# Locate the hermetic Godot binary via Bazel runfiles.
RUNFILES="${BASH_SOURCE[0]}.runfiles"

# Read the relative binary path from the repository rule
BIN_PATH_FILE="${RUNFILES}/+godot+godot/godot_bin_path.txt"
if [[ ! -f "$BIN_PATH_FILE" ]]; then
    BIN_PATH_FILE="${RUNFILES}/_main/external/+godot+godot/godot_bin_path.txt"
fi
if [[ ! -f "$BIN_PATH_FILE" ]]; then
    # Try canonical repo name format
    BIN_PATH_FILE=$(find "$RUNFILES" -name "godot_bin_path.txt" 2>/dev/null | head -1)
fi

if [[ -z "${BIN_PATH_FILE:-}" || ! -f "${BIN_PATH_FILE:-}" ]]; then
    echo "ERROR: Could not find godot_bin_path.txt in runfiles" >&2
    echo "Runfiles contents:" >&2
    find "$RUNFILES" -maxdepth 3 2>/dev/null | head -20 >&2
    exit 1
fi

GODOT_REL_PATH=$(cat "$BIN_PATH_FILE")
GODOT_DIR=$(dirname "$BIN_PATH_FILE")
GODOT_BIN="${GODOT_DIR}/godot_extracted/${GODOT_REL_PATH}"

if [[ ! -f "$GODOT_BIN" ]]; then
    echo "ERROR: Godot binary not found at: $GODOT_BIN" >&2
    exit 1
fi

chmod +x "$GODOT_BIN" 2>/dev/null || true

echo "Launching CitySlop with hermetic Godot"
exec "$GODOT_BIN" --path "$PROJECT_DIR"
