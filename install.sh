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
tar -xzf "$tmp/relay.tar.gz" -C "$tmp"

mkdir -p "$bin_dir"
find "$tmp" -type f -name relay -perm -111 -exec cp {} "$bin_dir/relay" \;
chmod +x "$bin_dir/relay"

echo "Installed relay to $bin_dir/relay"
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) echo "Add $bin_dir to PATH to run relay from any shell." ;;
esac
