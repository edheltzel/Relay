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

cat > "$fake_bin/gh" <<'EOF'
#!/bin/sh
set -eu

if [ "${GH_FAIL_AUTH:-}" = "1" ]; then
  exit 1
fi

case "$1:$2" in
  release:view)
    printf 'v0.0.0\n'
    ;;
  release:download)
    tag="$3"
    shift 3
    destination=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --dir)
          destination="$2"
          shift 2
          ;;
        --pattern|--repo)
          shift 2
          ;;
        *)
          exit 1
          ;;
      esac
    done
    archive_name="relay-${tag}-${FAKE_TARGET}.tar.gz"
    cp "$FIXTURE_ARCHIVE" "$destination/$archive_name"
    if [ "${GH_SKIP_CHECKSUM:-}" != "1" ]; then
      cp "$FIXTURE_CHECKSUM" "$destination/$archive_name.sha256"
    fi
    ;;
  *)
    exit 1
    ;;
esac
EOF

cat > "$fake_bin/xattr" <<'EOF'
#!/bin/sh
if [ "${XATTR_SIGNAL_PARENT:-}" = "1" ] && [ "$1" = "-p" ]; then
  kill -TERM "$PPID"
  exit 0
fi
printf '%s\n' "$*" >> "$XATTR_LOG"
EOF

chmod +x "$fake_bin/uname" "$fake_bin/gh" "$fake_bin/xattr"

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
  XATTR_SIGNAL_PARENT="${XATTR_SIGNAL_PARENT:-}" \
  GH_FAIL_AUTH="${GH_FAIL_AUTH:-}" \
  GH_SKIP_CHECKSUM="${GH_SKIP_CHECKSUM:-}" \
  BIN_DIR="$bin_dir" \
  PATH="$fake_bin:$PATH" \
    sh "$repo_root/install.sh"
}

macos_bin="$test_root/macos-bin"
macos_xattr="$test_root/macos-xattr.log"
mkdir -p "$macos_bin"
printf 'blocked old binary\n' > "$macos_bin/relay"
chmod +x "$macos_bin/relay"
old_inode="$(ls -di "$macos_bin/relay" | awk '{ print $1 }')"
run_installer \
  Darwin arm64 aarch64-apple-darwin \
  "$fixture_dir/relay.tar.gz.sha256" "$macos_bin" "$macos_xattr"
test -x "$macos_bin/relay"
new_inode="$(ls -di "$macos_bin/relay" | awk '{ print $1 }')"
test "$new_inode" != "$old_inode"
grep -F -- "-d com.apple.provenance $macos_bin/.relay.install." "$macos_xattr"
test -z "$(find "$macos_bin" -name '.relay.install.*' -print -quit)"

bad_bin="$test_root/bad-bin"
bad_xattr="$test_root/bad-xattr.log"
mkdir -p "$bad_bin"
printf 'working old binary\n' > "$bad_bin/relay"
chmod +x "$bad_bin/relay"
if run_installer \
  Darwin arm64 aarch64-apple-darwin \
  "$fixture_dir/bad.sha256" "$bad_bin" "$bad_xattr"; then
  echo "installer accepted a mismatched checksum" >&2
  exit 1
fi
grep -F 'working old binary' "$bad_bin/relay"
test ! -e "$bad_xattr"

interrupt_bin="$test_root/interrupt-bin"
interrupt_xattr="$test_root/interrupt-xattr.log"
mkdir -p "$interrupt_bin"
printf 'working old binary\n' > "$interrupt_bin/relay"
chmod +x "$interrupt_bin/relay"
set +e
XATTR_SIGNAL_PARENT=1 run_installer \
  Darwin arm64 aarch64-apple-darwin \
  "$fixture_dir/relay.tar.gz.sha256" "$interrupt_bin" "$interrupt_xattr"
interrupt_status=$?
set -e
test "$interrupt_status" -eq 143
grep -F 'working old binary' "$interrupt_bin/relay"
test -z "$(find "$interrupt_bin" -name '.relay.install.*' -print -quit)"

linux_bin="$test_root/linux-bin"
linux_xattr="$test_root/linux-xattr.log"
run_installer \
  Linux x86_64 x86_64-unknown-linux-gnu \
  "$fixture_dir/relay.tar.gz.sha256" "$linux_bin" "$linux_xattr"
test -x "$linux_bin/relay"
test ! -e "$linux_xattr"

auth_bin="$test_root/auth-bin"
auth_xattr="$test_root/auth-xattr.log"
auth_stderr="$test_root/auth.stderr"
mkdir -p "$auth_bin"
set +e
GH_FAIL_AUTH=1 run_installer \
  Linux x86_64 x86_64-unknown-linux-gnu \
  "$fixture_dir/relay.tar.gz.sha256" "$auth_bin" "$auth_xattr" \
  >"$test_root/auth.stdout" 2>"$auth_stderr"
auth_status=$?
set -e
test "$auth_status" -eq 1
grep -F "relay install: cannot access private releases" "$auth_stderr"
test ! -e "$auth_bin/relay"

asset_bin="$test_root/asset-bin"
asset_xattr="$test_root/asset-xattr.log"
asset_stderr="$test_root/asset.stderr"
mkdir -p "$asset_bin"
set +e
GH_SKIP_CHECKSUM=1 run_installer \
  Linux x86_64 x86_64-unknown-linux-gnu \
  "$fixture_dir/relay.tar.gz.sha256" "$asset_bin" "$asset_xattr" \
  >"$test_root/asset.stdout" 2>"$asset_stderr"
asset_status=$?
set -e
test "$asset_status" -eq 1
grep -F "relay install: release v0.0.0 has no complete asset set" "$asset_stderr"
test ! -e "$asset_bin/relay"
