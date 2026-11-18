#!/usr/bin/env bash
set -euo pipefail

# Install curl-impersonate as a BUNDLE (not one binary): its profile binaries
# are shell wrappers that exec the engine next to themselves, so the whole
# extracted tree must stay together. The main installer's one-binary-per-entry
# flow cannot express that; this script follows the standalone, digest-pinned
# installer pattern of install-ffuf-wordlist.sh.
#
# Asset + SHA-256 are pinned per (OS, arch). A host whose pair has no pinned
# digest fails loudly with the exact asset name to pin, never installs blind.

TOOLS_DIR="${PI_TOOLS_DIR:-$HOME/.pi/scanners}"
DEST_DIR="$TOOLS_DIR/curl-impersonate"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pi-cyber-curl-impersonate.XXXXXX")"

trap 'rm -rf "$TEMP_DIR"' EXIT

if command -v sha256sum >/dev/null 2>&1; then sha256_of() { sha256sum "$1" | cut -d ' ' -f 1; }
else sha256_of() { shasum -a 256 "$1" | cut -d ' ' -f 1; }; fi

VERSION="v2.3.0"
OS="$(uname -s)"
ARCH="$(uname -m)"

# Map (OS, arch) -> upstream asset name and its pinned SHA-256. Empty SHA means
# the asset exists upstream but is not pinned here yet: refuse until it is.
ASSET=""
EXPECTED_SHA256=""
case "$OS/$ARCH" in
  Darwin/arm64)
    ASSET="curl-impersonate-${VERSION}.arm64-macos.tar.gz"
    EXPECTED_SHA256="2dfb4b5733e01ec88f9cc7363696c848d0a2b810584d4c0fac7719f82b985f8f" ;;
  Darwin/x86_64)
    ASSET="curl-impersonate-${VERSION}.x86_64-macos.tar.gz"
    EXPECTED_SHA256="" ;;
  Linux/x86_64)
    ASSET="curl-impersonate-${VERSION}.x86_64-linux-gnu.tar.gz"
    EXPECTED_SHA256="5e77cb12217158f118ead21ab550791788e553fb140d03a49d74d08308ebdb06" ;;
  Linux/aarch64 | Linux/arm64)
    ASSET="curl-impersonate-${VERSION}.aarch64-linux-gnu.tar.gz"
    EXPECTED_SHA256="" ;;
  *)
    echo "pi-cyber: unsupported OS/arch for curl-impersonate: $OS/$ARCH" >&2
    exit 1 ;;
esac

if [[ -z "$EXPECTED_SHA256" ]]; then
  echo "pi-cyber: pin the ${ASSET} SHA-256 before installing on $OS/$ARCH." >&2
  echo "pi-cyber: fetch it, run 'sha256sum ${ASSET}', and add the digest to this script." >&2
  exit 1
fi

SOURCE_URL="https://github.com/lexiforest/curl-impersonate/releases/download/${VERSION}/${ASSET}"
ARCHIVE="$TEMP_DIR/$ASSET"
curl --fail --location --proto '=https' --tlsv1.2 "$SOURCE_URL" --output "$ARCHIVE"
ACTUAL_SHA256="$(sha256_of "$ARCHIVE")"
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
  echo "pi-cyber: curl-impersonate SHA-256 mismatch; refusing installation" >&2
  echo "pi-cyber:   expected $EXPECTED_SHA256" >&2
  echo "pi-cyber:   got      $ACTUAL_SHA256" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
tar -xzf "$ARCHIVE" -C "$DEST_DIR"
chmod +x "$DEST_DIR"/* 2>/dev/null || true

BIN="$DEST_DIR/curl-impersonate"
if [[ ! -x "$BIN" ]]; then
  echo "pi-cyber: no curl-impersonate binary at $BIN after extraction; refusing" >&2
  exit 1
fi

# Prove the engine runs. The v2 binary links impersonation in; its banner wording
# differs across platforms, so accept any successful --version and only warn when
# the banner does not mention impersonation.
if VERSION_OUT="$("$BIN" --version 2>&1)"; then
  if ! grep -qi "impersonate" <<<"$VERSION_OUT"; then
    echo "pi-cyber: warning — $BIN ran but its --version banner did not mention impersonation" >&2
  fi
else
  echo "pi-cyber: curl-impersonate did not execute post-install; refusing" >&2
  exit 1
fi

echo "pi-cyber: curl-impersonate $VERSION installed at $DEST_DIR"
