#!/usr/bin/env bash
# Environment setup for CitySlop — run once per session before bazel or playtest.sh.
# Safe to re-run; all steps are idempotent.
set -euo pipefail

echo "[setup] Starting CitySlop environment setup..."

# ---------- apt packages ----------

PKGS=()
for pkg in xvfb scrot imagemagick xdotool python3 curl unzip; do
    dpkg -s "$pkg" &>/dev/null || PKGS+=("$pkg")
done
if [[ ${#PKGS[@]} -gt 0 ]]; then
    echo "[setup] Installing: ${PKGS[*]}"
    apt-get install -y "${PKGS[@]}" 2>&1 | tail -3
fi

# ---------- Bazelisk ----------

if [[ ! -x /usr/local/bin/bazelisk ]]; then
    echo "[setup] Downloading Bazelisk..."
    curl -fsSL -o /usr/local/bin/bazelisk \
        "https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-amd64"
    chmod +x /usr/local/bin/bazelisk
fi
ln -sf /usr/local/bin/bazelisk /usr/local/bin/bazel
echo "[setup] bazel -> bazelisk $(bazelisk --version 2>/dev/null | head -1)"

# ---------- Bazel binary mirror (releases.bazel.build is blocked) ----------

BAZEL_VERSION=$(cat "$(dirname "$0")/../.bazelversion" 2>/dev/null || echo "9.1.0")
MIRROR_DIR="/tmp/bazel-mirror"
MIRROR_BIN="$MIRROR_DIR/$BAZEL_VERSION/bazel-$BAZEL_VERSION-linux-x86_64"

if [[ ! -x "$MIRROR_BIN" ]]; then
    echo "[setup] Downloading Bazel $BAZEL_VERSION from GitHub..."
    mkdir -p "$MIRROR_DIR/$BAZEL_VERSION"
    curl -fsSL -o "$MIRROR_BIN" \
        "https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-linux-x86_64"
    chmod +x "$MIRROR_BIN"
fi

# Start mirror HTTP server if not running
if ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:19999/$BAZEL_VERSION/bazel-$BAZEL_VERSION-linux-x86_64" 2>/dev/null | grep -q "200"; then
    echo "[setup] Starting Bazel mirror on :19999..."
    python3 -m http.server 19999 --directory "$MIRROR_DIR" > /tmp/bazel-mirror.log 2>&1 &
    sleep 1
fi

export BAZELISK_BASE_URL="http://localhost:19999"
echo "[setup] BAZELISK_BASE_URL=$BAZELISK_BASE_URL"

# ---------- Anthropic TLS proxy cert -> Java truststore ----------
# bcr.bazel.build is served through an Anthropic TLS-inspection proxy.
# Bazel's embedded JVM needs the proxy CA cert to validate the connection.

CERT_FILE="/tmp/anthropic-proxy-ca.pem"
if [[ ! -f "$CERT_FILE" ]]; then
    echo "[setup] Fetching Anthropic proxy CA cert..."
    # Extract the root CA (cert #2) from the chain
    echo | openssl s_client -connect bcr.bazel.build:443 -showcerts 2>/dev/null \
        | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' \
        | awk 'BEGIN{n=0;f=""} /-----BEGIN/{n++;f="/tmp/chain_cert_"n".pem"} {print>f}'
    # Use the last cert in the chain (the CA)
    last=$(ls /tmp/chain_cert_*.pem 2>/dev/null | sort -V | tail -1)
    [[ -n "$last" ]] && cp "$last" "$CERT_FILE" && rm -f /tmp/chain_cert_*.pem
fi

if [[ -f "$CERT_FILE" ]]; then
    # Import into system Java truststore
    JAVA_CACERTS=$(find /usr/lib/jvm -name cacerts 2>/dev/null | head -1)
    if [[ -n "$JAVA_CACERTS" ]]; then
        keytool -list -alias anthropic-proxy-ca -keystore "$JAVA_CACERTS" \
            -storepass changeit -noprompt &>/dev/null \
            || keytool -importcert -alias anthropic-proxy-ca -file "$CERT_FILE" \
                -keystore "$JAVA_CACERTS" -storepass changeit -noprompt 2>/dev/null \
            && echo "[setup] Anthropic CA cert imported into system JVM"
    fi
    # Add to ~/.bazelrc so Bazel's embedded JVM also trusts it
    CUSTOM_CACERTS="/tmp/custom_cacerts"
    if [[ ! -f "$CUSTOM_CACERTS" ]] || ! keytool -list -alias anthropic-proxy-ca \
            -keystore "$CUSTOM_CACERTS" -storepass changeit -noprompt &>/dev/null; then
        cp "$JAVA_CACERTS" "$CUSTOM_CACERTS" 2>/dev/null \
            || cp /etc/ssl/certs/java/cacerts "$CUSTOM_CACERTS"
        keytool -delete -alias anthropic-proxy-ca -keystore "$CUSTOM_CACERTS" \
            -storepass changeit -noprompt 2>/dev/null || true
        keytool -importcert -alias anthropic-proxy-ca -file "$CERT_FILE" \
            -keystore "$CUSTOM_CACERTS" -storepass changeit -noprompt 2>/dev/null \
            && echo "[setup] Anthropic CA cert imported into custom Bazel truststore"
    fi
    # Persist JVM flags into user-level bazelrc (idempotent)
    if ! grep -q "anthropic-proxy-ca\|custom_cacerts" ~/.bazelrc 2>/dev/null; then
        cat >> ~/.bazelrc << EOF
startup --host_jvm_args=-Djavax.net.ssl.trustStore=/tmp/custom_cacerts
startup --host_jvm_args=-Djavax.net.ssl.trustStorePassword=changeit
EOF
        echo "[setup] Added JVM truststore flags to ~/.bazelrc"
    fi
fi

# ---------- Xvfb virtual display ----------

if ! DISPLAY=:99 xdpyinfo &>/dev/null; then
    echo "[setup] Starting Xvfb on :99..."
    pkill -9 Xvfb 2>/dev/null || true
    sleep 1
    rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
    Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset \
        > /tmp/xvfb.log 2>&1 &
    sleep 2
fi
echo "[setup] Xvfb :99 ready"

# ---------- done ----------

echo "[setup] Done. Run the game with:"
echo "  BAZELISK_BASE_URL=http://localhost:19999 bazel run :cityslop"
echo "  or: tools/playtest.sh --interact"
