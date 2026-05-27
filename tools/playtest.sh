#!/usr/bin/env bash
# Launch CitySlop, optionally interact, and capture a screenshot.
#
# Usage:
#   ./tools/playtest.sh                        # launch + screenshot only
#   ./tools/playtest.sh --interact             # launch, click grid, start sim, screenshot
#   ./tools/playtest.sh --screenshot /tmp/x.png
#
# Outputs screenshot to /tmp/cityslop_screen.png (or --screenshot path).
#
# Requirements: bazelisk at /usr/local/bin/bazelisk, Xvfb, scrot, imagemagick, xdotool
# The Bazel binary mirror must be accessible (started by this script if needed).

set -euo pipefail

DISPLAY_NUM=":99"
BAZEL="/usr/local/bin/bazelisk"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCREENSHOT="/tmp/cityslop_screen.png"
INTERACT=0
MIRROR_PORT=19999
MIRROR_DIR="/tmp/bazel-mirror"

export BAZELISK_BASE_URL="http://localhost:${MIRROR_PORT}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --interact) INTERACT=1; shift ;;
        --screenshot) SCREENSHOT="$2"; shift 2 ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

# ---------- helpers ----------

screenshot() {
    DISPLAY="$DISPLAY_NUM" scrot "$1" 2>/dev/null
}

is_black() {
    local f="$1"
    local mean
    mean=$(convert "$f" -format "%[fx:mean]" info: 2>/dev/null || echo "0")
    awk "BEGIN{exit !($mean < 0.02)}"
}

click() {
    local x="$1" y="$2"
    DISPLAY="$DISPLAY_NUM" xdotool mousemove "$x" "$y" click 1
    sleep 0.15
}

keypress() {
    DISPLAY="$DISPLAY_NUM" xdotool key "$1"
    sleep 0.15
}

# ---------- bazel mirror ----------

ensure_mirror() {
    if ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:${MIRROR_PORT}" 2>/dev/null | grep -q "200\|404"; then
        echo "[playtest] Starting local Bazel mirror on port ${MIRROR_PORT}..."
        mkdir -p "${MIRROR_DIR}"
        # Populate mirror with any pre-downloaded Bazel binaries
        for bin in /usr/local/bin/bazel8 /usr/local/bin/bazel7; do
            [[ -x "$bin" ]] || continue
            ver=$("$bin" --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1) || continue
            mkdir -p "${MIRROR_DIR}/${ver}"
            cp "$bin" "${MIRROR_DIR}/${ver}/bazel-${ver}-linux-x86_64"
        done
        python3 -m http.server "${MIRROR_PORT}" --directory "${MIRROR_DIR}" \
            > /tmp/bazel-mirror.log 2>&1 &
        sleep 1
    fi
}

# ---------- cleanup ----------

echo "[playtest] Cleaning up stale processes..."
pkill -9 -f "Godot_v4" 2>/dev/null || true
pkill -9 -f "bazel-real.*cityslop\|run_game.sh" 2>/dev/null || true
sleep 1

# ---------- virtual display ----------

echo "[playtest] Starting fresh Xvfb on ${DISPLAY_NUM}..."
pkill -9 Xvfb 2>/dev/null || true
sleep 1
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
Xvfb "$DISPLAY_NUM" -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
sleep 2

# ---------- bazel mirror ----------

ensure_mirror

# ---------- launch ----------

echo "[playtest] Launching via bazel run :cityslop ..."
cd "$PROJECT_DIR"
DISPLAY="$DISPLAY_NUM" BAZELISK_BASE_URL="$BAZELISK_BASE_URL" \
    "$BAZEL" run :cityslop > /tmp/bazel_game.log 2>&1 &

# Wait for Godot process (up to 60s)
echo "[playtest] Waiting for Godot process..."
for i in $(seq 1 30); do
    pgrep -f "Godot_v4" > /dev/null && break
    sleep 2
done
pgrep -f "Godot_v4" > /dev/null || { echo "[playtest] ERROR: Godot never started"; cat /tmp/bazel_game.log; exit 1; }
echo "[playtest] Godot PID=$(pgrep -f 'Godot_v4' | head -1)"

# Wait for a rendered (non-black) frame (up to 40s)
echo "[playtest] Waiting for rendered frame..."
for i in $(seq 1 20); do
    screenshot "$SCREENSHOT"
    if ! is_black "$SCREENSHOT"; then
        echo "[playtest] Rendered frame on attempt $i"
        break
    fi
    echo "[playtest] Frame $i still dark, waiting 2s..."
    sleep 2
done

if is_black "$SCREENSHOT"; then
    echo "[playtest] WARNING: frame still dark after timeout — saving anyway"
fi

# ---------- interact ----------

if [[ "$INTERACT" -eq 1 ]]; then
    echo "[playtest] Interacting: clicking 5 grid squares near center..."
    # Grid is 64px cells; viewport is 1920x1080; camera starts at world origin.
    # Center of screen ~(960, 540); click a small cluster of adjacent cells.
    click 960 540
    click 1024 540
    click 1088 540
    click 960 604
    click 1024 604

    echo "[playtest] Pressing Space to start simulation..."
    keypress "space"

    echo "[playtest] Waiting 3 ticks (~1.5s) then screenshotting..."
    sleep 2

    screenshot "$SCREENSHOT"
    echo "[playtest] Post-interaction screenshot saved."
fi

echo "[playtest] Done. Screenshot: $SCREENSHOT"
