#!/usr/bin/env bash
# Launch CitySlop, optionally interact, and capture a screenshot.
#
# Usage:
#   ./tools/playtest.sh                        # launch + screenshot only
#   ./tools/playtest.sh --interact             # launch, click grid, start sim, screenshot
#   ./tools/playtest.sh --screenshot /tmp/x.png
#
# Outputs screenshot to /tmp/cityslop_screen.png (or --screenshot path).

set -euo pipefail

DISPLAY_NUM=":99"
BAZEL="/usr/local/bin/bazel7"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCREENSHOT="/tmp/cityslop_screen.png"
INTERACT=0
# Point Bazel's JVM at a truststore that includes the Anthropic TLS-inspection CA

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

# ---------- cleanup ----------

echo "[playtest] Cleaning up stale processes..."
pkill -9 -f "Godot_v4.3" 2>/dev/null || true
pkill -9 -f "bazel-real.*cityslop\|run_game.sh" 2>/dev/null || true
sleep 1

# ---------- virtual display ----------

echo "[playtest] Starting fresh Xvfb on $DISPLAY_NUM..."
pkill -9 Xvfb 2>/dev/null || true
sleep 1
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
Xvfb "$DISPLAY_NUM" -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
sleep 2

# ---------- launch ----------

echo "[playtest] Launching via bazel run :cityslop ..."
cd "$PROJECT_DIR"
DISPLAY="$DISPLAY_NUM" "$BAZEL" run :cityslop > /tmp/bazel_game.log 2>&1 &

# Wait for Godot process (up to 60s)
echo "[playtest] Waiting for Godot process..."
for i in $(seq 1 30); do
    pgrep -f "Godot_v4.3" > /dev/null && break
    sleep 2
done
pgrep -f "Godot_v4.3" > /dev/null || { echo "[playtest] ERROR: Godot never started"; cat /tmp/bazel_game.log; exit 1; }
echo "[playtest] Godot PID=$(pgrep -f Godot_v4.3)"

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
    # Grid is 64px cells; viewport is 1920x1080; camera starts at origin.
    # Center of screen ~ (960, 540); click a small cluster of cells.
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
