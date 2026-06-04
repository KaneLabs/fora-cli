#!/usr/bin/env bash
# =============================================================================
# fora-cli installer (anonymous-curl flavor)
#
# Downloads the latest fora-cli binary for the current platform from
# https://github.com/KaneLabs/fora-cli/releases and installs it to a
# location on PATH.
#
# Usage:
#   curl -fsSL https://install.fora.co/install.sh | sh
#
# Or for a specific tag:
#   curl -fsSL https://install.fora.co/install.sh | sh -s -- fora-cli-v0.1.0
#
# This script is the *public* installer. It does NOT require gh CLI or
# GitHub auth — KaneLabs/fora-cli is a public mirror repo whose Releases
# are anonymously downloadable. The source repo (KaneLabs/fora-markets)
# stays private; this mirror only holds compiled binaries.
#
# Requirements:
#   - curl
#   - tar
#   - shasum or sha256sum (for checksum verification)
# =============================================================================
set -eu

REPO="KaneLabs/fora-cli"
TAG="${1:-fora-cli-latest}"

# --- Locate install dir ---
# /usr/local/bin is the canonical Unix tooling location and is on PATH by
# default everywhere. Pick that if writable, else ~/.local/bin (user is
# responsible for having it on PATH), else error.
if [ -w /usr/local/bin ] || [ "$(id -u)" -eq 0 ]; then
  INSTALL_DIR="/usr/local/bin"
  NEED_SUDO=""
elif [ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
  INSTALL_DIR="$HOME/.local/bin"
  NEED_SUDO=""
  case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
      echo "warning: $INSTALL_DIR is not on \$PATH" >&2
      echo "  add this to your shell rc: export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2
      ;;
  esac
elif command -v sudo >/dev/null 2>&1; then
  INSTALL_DIR="/usr/local/bin"
  NEED_SUDO="sudo"
else
  echo "error: cannot find a writable install dir (/usr/local/bin or ~/.local/bin) and sudo is unavailable" >&2
  exit 1
fi

# --- Check dependencies ---
for cmd in curl tar; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: '$cmd' is required but not installed" >&2
    exit 1
  fi
done

# --- Detect platform ---
# Normalize uname -m: macOS reports "arm64" on Apple Silicon, but our build
# matrix uses "aarch64" everywhere. Linux already reports aarch64.
ARCH="$(uname -m)"
case "$ARCH" in
  arm64|aarch64) ARCH="aarch64" ;;
  x86_64|amd64)  ARCH="x86_64" ;;
  *)
    echo "error: unsupported architecture '$ARCH'" >&2
    exit 1
    ;;
esac

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$OS" in
  linux)
    TARGET="${ARCH}-unknown-linux-musl"
    ;;
  darwin)
    # No prebuilt macOS binary — we build on ubicloud which has no macOS
    # pool, and we don't pay for GitHub-hosted macos runners. macOS users
    # currently must build from source with cargo. If macOS support gets
    # prioritized this script will gain a darwin target.
    cat >&2 <<'DARWIN_EOF'
No prebuilt fora-cli binary for macOS (yet).

macOS install path (requires Rust toolchain + SSH access to the source repo):

    cargo install --git git@github.com:KaneLabs/fora-markets.git fora-cli

Alternatives if you can't install Rust on this machine:
  - run fora-cli inside a Linux container or VM
  - SSH into a Linux box and use it there
DARWIN_EOF
    exit 1
    ;;
  *)
    echo "error: unsupported OS '$OS'" >&2
    exit 1
    ;;
esac

ARCHIVE="fora-cli-${TARGET}.tar.gz"
SHA_FILE="${ARCHIVE}.sha256"
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"

echo "Platform: $TARGET"
echo "Release:  $TAG"
echo "Install:  $INSTALL_DIR/fora-cli"
echo ""

# --- Download tarball + sha256 to a temp dir ---
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading $ARCHIVE..."
curl -fsSL -o "$TMP/$ARCHIVE" "$BASE_URL/$ARCHIVE"
curl -fsSL -o "$TMP/$SHA_FILE" "$BASE_URL/$SHA_FILE"

# --- Verify sha256 ---
echo "Verifying sha256..."
cd "$TMP"
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 -c "$SHA_FILE"
elif command -v sha256sum >/dev/null 2>&1; then
  sha256sum -c "$SHA_FILE"
else
  echo "warning: no shasum/sha256sum found, skipping checksum verification" >&2
fi

# --- Extract + install ---
echo "Installing to $INSTALL_DIR/fora-cli..."
tar -xzf "$ARCHIVE"

# Use install(1) to atomically replace (won't clobber if a running fora-cli
# process has the file open — it'll unlink-and-replace instead).
$NEED_SUDO install -m 755 fora-cli "$INSTALL_DIR/fora-cli"

# --- Done ---
echo ""
echo "✓ fora-cli installed: $INSTALL_DIR/fora-cli"
echo ""
"$INSTALL_DIR/fora-cli" --version 2>/dev/null || "$INSTALL_DIR/fora-cli" --help | head -5 || true
