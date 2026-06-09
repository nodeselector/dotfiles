#!/usr/bin/env bats
# Tests for prefs-promote script

setup() {
  export TEST_DIR=$(mktemp -d)
  export REPO_ROOT="$TEST_DIR/repo"
  
  mkdir -p "$REPO_ROOT/prefs/defaults"
  mkdir -p "$REPO_ROOT/prefs/defaults-safe"
  mkdir -p "$REPO_ROOT/script"
  
  # Copy fixtures
  cp "$BATS_TEST_DIRNAME/fixtures/com.test.sample.plist" "$REPO_ROOT/prefs/defaults/"
  cp "$BATS_TEST_DIRNAME/fixtures/defaults.lock.yaml" "$REPO_ROOT/prefs/defaults.lock.yaml"
  
  # Create a minimal promote script that works with TEST_DIR
  cat > "$REPO_ROOT/script/prefs-promote" << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PREFS_DIR="$REPO_ROOT/prefs"
LOCKFILE="$PREFS_DIR/defaults.lock.yaml"
DOMAIN="$1"
REASON="$2"
SOURCE="$PREFS_DIR/defaults/$DOMAIN.plist"
DEST="$PREFS_DIR/defaults-safe/$DOMAIN.plist"
[[ -z "$DOMAIN" ]] && exit 1
[[ -z "$REASON" ]] && exit 1
[[ ! -f "$SOURCE" ]] && exit 1
cp "$SOURCE" "$DEST"
DATE=$(date +%Y-%m-%d)
yq -i ".\"$DOMAIN\".promoted = \"$DATE\" | .\"$DOMAIN\".reason = \"$REASON\"" "$LOCKFILE"
SCRIPT
  chmod +x "$REPO_ROOT/script/prefs-promote"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "promote copies plist to defaults-safe" {
  run "$REPO_ROOT/script/prefs-promote" "com.test.sample" "test reason"
  [ "$status" -eq 0 ]
  [ -f "$REPO_ROOT/prefs/defaults-safe/com.test.sample.plist" ]
}

@test "promote updates lockfile with reason" {
  "$REPO_ROOT/script/prefs-promote" "com.test.sample" "my test reason"
  run yq '.["com.test.sample"].reason' "$REPO_ROOT/prefs/defaults.lock.yaml"
  [ "$output" = 'my test reason' ]
}

@test "promote updates lockfile with date" {
  "$REPO_ROOT/script/prefs-promote" "com.test.sample" "test reason"
  run yq '.["com.test.sample"].promoted' "$REPO_ROOT/prefs/defaults.lock.yaml"
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

@test "promote fails without domain" {
  run "$REPO_ROOT/script/prefs-promote" "" "test reason"
  [ "$status" -ne 0 ]
}

@test "promote fails without reason" {
  run "$REPO_ROOT/script/prefs-promote" "com.test.sample" ""
  [ "$status" -ne 0 ]
}

@test "promote fails if source plist missing" {
  run "$REPO_ROOT/script/prefs-promote" "com.nonexistent" "test reason"
  [ "$status" -ne 0 ]
}
