#!/usr/bin/env sh
set -eu

repo="edheltzel/relay"
bin_dir="${BIN_DIR:-$HOME/.local/bin}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "relay install: missing required command: $1" >&2
    exit 1
  }
}

need curl
need tar

sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{ print $1 }'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{ print $1 }'
  else
    echo "relay install: missing required command: shasum or sha256sum" >&2
    exit 1
  fi
}

os="$(uname -s)"
arch="$(uname -m)"

case "$os:$arch" in
  Darwin:arm64) target="aarch64-apple-darwin" ;;
  Darwin:x86_64) target="x86_64-apple-darwin" ;;
  Linux:x86_64) target="x86_64-unknown-linux-gnu" ;;
  Linux:aarch64|Linux:arm64) target="aarch64-unknown-linux-gnu" ;;
  *)
    echo "relay install: unsupported platform $os/$arch" >&2
    exit 1
    ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

api="https://api.github.com/repos/$repo/releases/latest"
asset_url="$(
  curl -fsSL "$api" \
    | sed -n 's/.*"browser_download_url": "\(.*relay-v[^"]*-'"$target"'\.tar\.gz\)".*/\1/p' \
    | head -n 1
)"

if [ -z "$asset_url" ]; then
  echo "relay install: no release asset found for $target" >&2
  exit 1
fi

echo "Downloading $asset_url"
curl -fsSL "$asset_url" -o "$tmp/relay.tar.gz"
curl -fsSL "${asset_url}.sha256" -o "$tmp/relay.tar.gz.sha256"

expected="$(awk 'NR == 1 { print $1 }' "$tmp/relay.tar.gz.sha256" | tr '[:upper:]' '[:lower:]')"
case "$expected" in
  *[!0-9a-f]*|'')
    echo "relay install: release checksum is malformed" >&2
    exit 1
    ;;
esac
if [ "${#expected}" -ne 64 ]; then
  echo "relay install: release checksum is malformed" >&2
  exit 1
fi

actual="$(sha256 "$tmp/relay.tar.gz")"
if [ "$actual" != "$expected" ]; then
  echo "relay install: release checksum verification failed" >&2
  exit 1
fi

echo "Verified SHA-256 checksum"
tar -xzf "$tmp/relay.tar.gz" -C "$tmp"

mkdir -p "$bin_dir"
find "$tmp" -type f -name relay -perm -111 -exec cp {} "$bin_dir/relay" \;
chmod +x "$bin_dir/relay"

if [ "$os" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
  if xattr -p com.apple.provenance "$bin_dir/relay" >/dev/null 2>&1; then
    xattr -d com.apple.provenance "$bin_dir/relay"
  fi
fi

echo "Installed relay to $bin_dir/relay"
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) echo "Add $bin_dir to PATH to run relay from any shell." ;;
esac
