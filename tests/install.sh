#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fixture_dir="$test_root/fixture"
fake_bin="$test_root/bin"
mkdir -p "$fixture_dir/package" "$fake_bin"

printf '#!/bin/sh\nexit 0\n' > "$fixture_dir/package/relay"
chmod +x "$fixture_dir/package/relay"
tar -C "$fixture_dir" -czf "$fixture_dir/relay.tar.gz" package

if command -v shasum >/dev/null 2>&1; then
  digest="$(shasum -a 256 "$fixture_dir/relay.tar.gz" | awk '{ print $1 }')"
else
  digest="$(sha256sum "$fixture_dir/relay.tar.gz" | awk '{ print $1 }')"
fi
printf '%s  dist/relay-v0.0.0-aarch64-apple-darwin.tar.gz\n' "$digest" \
  > "$fixture_dir/relay.tar.gz.sha256"
printf '%064d  dist/relay-v0.0.0-aarch64-apple-darwin.tar.gz\n' 0 \
  > "$fixture_dir/bad.sha256"

cat > "$fake_bin/uname" <<'EOF'
#!/bin/sh
case "$1" in
  -s) printf '%s\n' "$FAKE_OS" ;;
  -m) printf '%s\n' "$FAKE_ARCH" ;;
  *) exit 1 ;;
esac
EOF

cat > "$fake_bin/curl" <<'EOF'
#!/bin/sh
set -eu

output=""
url=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      output="$2"
      shift 2
      ;;
    -*) shift ;;
    *)
      url="$1"
      shift
      ;;
  esac
done

case "$url" in
  */releases/latest)
    printf '{"browser_download_url": "https://example.test/relay-v0.0.0-%s.tar.gz"}\n' \
      "$FAKE_TARGET"
    ;;
  *.tar.gz.sha256) cp "$FIXTURE_CHECKSUM" "$output" ;;
  *.tar.gz) cp "$FIXTURE_ARCHIVE" "$output" ;;
  *) exit 1 ;;
esac
EOF

cat > "$fake_bin/xattr" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$XATTR_LOG"
EOF

chmod +x "$fake_bin/uname" "$fake_bin/curl" "$fake_bin/xattr"

run_installer() {
  local os="$1"
  local arch="$2"
  local target="$3"
  local checksum="$4"
  local bin_dir="$5"
  local xattr_log="$6"

  FAKE_OS="$os" \
  FAKE_ARCH="$arch" \
  FAKE_TARGET="$target" \
  FIXTURE_ARCHIVE="$fixture_dir/relay.tar.gz" \
  FIXTURE_CHECKSUM="$checksum" \
  XATTR_LOG="$xattr_log" \
  BIN_DIR="$bin_dir" \
  PATH="$fake_bin:$PATH" \
    sh "$repo_root/install.sh"
}

macos_bin="$test_root/macos-bin"
macos_xattr="$test_root/macos-xattr.log"
run_installer \
  Darwin arm64 aarch64-apple-darwin \
  "$fixture_dir/relay.tar.gz.sha256" "$macos_bin" "$macos_xattr"
test -x "$macos_bin/relay"
grep -F -- "-d com.apple.provenance $macos_bin/relay" "$macos_xattr"

bad_bin="$test_root/bad-bin"
bad_xattr="$test_root/bad-xattr.log"
if run_installer \
  Darwin arm64 aarch64-apple-darwin \
  "$fixture_dir/bad.sha256" "$bad_bin" "$bad_xattr"; then
  echo "installer accepted a mismatched checksum" >&2
  exit 1
fi
test ! -e "$bad_bin/relay"
test ! -e "$bad_xattr"

linux_bin="$test_root/linux-bin"
linux_xattr="$test_root/linux-xattr.log"
run_installer \
  Linux x86_64 x86_64-unknown-linux-gnu \
  "$fixture_dir/relay.tar.gz.sha256" "$linux_bin" "$linux_xattr"
test -x "$linux_bin/relay"
test ! -e "$linux_xattr"
