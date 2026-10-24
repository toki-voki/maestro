#!/bin/sh
# Install maestro.
#
#   curl -fsSL https://raw.githubusercontent.com/toki-voki/maestro/main/distribution/install.sh | sh
#
# Resolution order:
#   1. MAESTRO_VERSION set        → that GitHub release tag, verified against its checksums.txt
#   2. otherwise                  → latest.json asset of the GitHub release flagged "Latest"
#                                   (stable channel), verified against the sha256 it records
#
# Env overrides:
#   MAESTRO_VERSION       tag to install, e.g. v0.1.0
#   MAESTRO_INSTALL_DIR   target dir                    (default: ~/.local/bin)
#   MAESTRO_MANIFEST_URL  manifest location             (default: latest release asset)
#   MAESTRO_MODIFY_PATH=1 append the install dir to your shell profile if it is not on PATH
#                         (default: only print the line to add)
set -eu

REPO="toki-voki/maestro"
BIN="maestro"
INSTALL_DIR="${MAESTRO_INSTALL_DIR:-$HOME/.local/bin}"
MANIFEST_URL="${MAESTRO_MANIFEST_URL:-https://github.com/${REPO}/releases/latest/download/latest.json}"

log()  { printf '[maestro] %s\n' "$*"; }
warn() { printf '[maestro] warning: %s\n' "$*" >&2; }
err()  { printf '[maestro] error: %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || err "curl is required"
command -v tar  >/dev/null 2>&1 || err "tar is required"

# --- platform -----------------------------------------------------------------
case "$(uname -s)" in
    Linux)  OS=linux ;;
    Darwin) OS=darwin ;;
    *)      err "unsupported OS: $(uname -s). On Windows download the zip from https://github.com/${REPO}/releases" ;;
esac

case "$(uname -m)" in
    x86_64|amd64)   ARCH=amd64 ;;
    aarch64|arm64)  ARCH=arm64 ;;
    *)              err "unsupported architecture: $(uname -m)" ;;
esac
TARGET="${OS}_${ARCH}"

# --- sha256 tool --------------------------------------------------------------
if command -v sha256sum >/dev/null 2>&1; then
    sha256() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
    sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
elif command -v openssl >/dev/null 2>&1; then
    sha256() { openssl dgst -sha256 "$1" | awk '{print $NF}'; }
else
    err "sha256sum, shasum or openssl is required to verify the download"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- resolve url + expected checksum -----------------------------------------
if [ -n "${MAESTRO_VERSION:-}" ]; then
    TAG="$MAESTRO_VERSION"
    VERSION="${TAG#v}"
    BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
    ARCHIVE="${BIN}_${VERSION}_${TARGET}.tar.gz"
    URL="${BASE_URL}/${ARCHIVE}"
    log "fetching checksums for ${TAG}"
    curl -fsSL -o "${TMP}/checksums.txt" "${BASE_URL}/checksums.txt" || err "download failed: ${BASE_URL}/checksums.txt"
    EXPECTED="$(awk -v f="$ARCHIVE" '$2 == f {print $1}' "${TMP}/checksums.txt")"
    [ -n "$EXPECTED" ] || err "no checksum for ${ARCHIVE} in checksums.txt"
else
    log "fetching release manifest"
    curl -fsSL -o "${TMP}/latest.json" "$MANIFEST_URL" || err "download failed: ${MANIFEST_URL}"
    TAG="$(sed -n 's/^[[:space:]]*"tag":[[:space:]]*"\([^"]*\)".*/\1/p' "${TMP}/latest.json")"
    # the manifest keeps one asset per line, so a single grep isolates ours
    LINE="$(grep "\"${TARGET}\"" "${TMP}/latest.json" || true)"
    [ -n "$LINE" ] || err "manifest has no asset for ${TARGET}"
    URL="$(printf '%s' "$LINE" | sed -n 's/.*"url":[[:space:]]*"\([^"]*\)".*/\1/p')"
    EXPECTED="$(printf '%s' "$LINE" | sed -n 's/.*"sha256":[[:space:]]*"\([0-9a-f]\{64\}\)".*/\1/p')"
    [ -n "$URL" ] && [ -n "$EXPECTED" ] || err "manifest entry for ${TARGET} is malformed"
    ARCHIVE="${URL##*/}"
fi

# --- download + verify --------------------------------------------------------
log "downloading ${BIN} ${TAG} (${TARGET})"
curl -fsSL -o "${TMP}/${ARCHIVE}" "$URL" || err "download failed: ${URL}"
ACTUAL="$(sha256 "${TMP}/${ARCHIVE}")"
[ "$EXPECTED" = "$ACTUAL" ] || err "checksum mismatch for ${ARCHIVE}: expected ${EXPECTED}, got ${ACTUAL}"
log "checksum verified"

# --- install ------------------------------------------------------------------
tar -xzf "${TMP}/${ARCHIVE}" -C "$TMP" "$BIN"
mkdir -p "$INSTALL_DIR"
install -m 0755 "${TMP}/${BIN}" "${INSTALL_DIR}/${BIN}"
log "installed ${INSTALL_DIR}/${BIN} ($("${INSTALL_DIR}/${BIN}" version))"

# --- PATH ---------------------------------------------------------------------
case ":${PATH}:" in
    *":${INSTALL_DIR}:"*) exit 0 ;;
esac

# the user's login shell decides which file and which syntax
case "$(basename "${SHELL:-sh}")" in
    fish) RC="$HOME/.config/fish/config.fish"; LINE="fish_add_path \"${INSTALL_DIR}\"" ;;
    zsh)  RC="${ZDOTDIR:-$HOME}/.zshrc";        LINE="export PATH=\"${INSTALL_DIR}:\$PATH\"" ;;
    bash) RC="$HOME/.bashrc"; [ "$OS" = darwin ] && RC="$HOME/.bash_profile"
          LINE="export PATH=\"${INSTALL_DIR}:\$PATH\"" ;;
    *)    RC="";                                LINE="export PATH=\"${INSTALL_DIR}:\$PATH\"" ;;
esac

# Never edit shell config unless asked: MAESTRO_MODIFY_PATH=1
if [ "${MAESTRO_MODIFY_PATH:-0}" = 1 ] && [ -n "$RC" ]; then
    if ! grep -qsF "$LINE" "$RC"; then
        mkdir -p "$(dirname "$RC")"
        printf '\n# maestro\n%s\n' "$LINE" >> "$RC"
    fi
    log "added ${INSTALL_DIR} to PATH in ${RC}; open a new terminal"
else
    warn "${INSTALL_DIR} is not in your PATH. Add this line to ${RC:-your shell profile}:"
    printf '    %s\n' "$LINE" >&2
    if [ -n "$RC" ]; then
        printf '  or re-run with MAESTRO_MODIFY_PATH=1 to let the installer append it\n' >&2
    fi
fi
