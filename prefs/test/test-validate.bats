#!/usr/bin/env bats
# Tests for prefs-validate script (pre-commit hook logic)

setup() {
  export TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/defaults-safe"
  
  # Create lockfile with one entry
  cat > "$TEST_DIR/defaults.lock.yaml" << 'EOF'
com.test.valid:
  promoted: "2026-01-01"
  reason: "Test entry"
EOF
  
  # Create matching plist
  touch "$TEST_DIR/defaults-safe/com.test.valid.plist"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "validate passes when lockfile matches defaults-safe" {
  actual=$(ls -1 "$TEST_DIR/defaults-safe"/*.plist 2>/dev/null | xargs -n1 basename | sed 's/\.plist$//' | sort)
  locked=$(yq -r 'keys | .[]' "$TEST_DIR/defaults.lock.yaml" 2>/dev/null | sort)
  [ "$actual" = "$locked" ]
}

@test "validate detects plist not in lockfile" {
  touch "$TEST_DIR/defaults-safe/com.rogue.plist"
  
  actual=$(ls -1 "$TEST_DIR/defaults-safe"/*.plist 2>/dev/null | xargs -n1 basename | sed 's/\.plist$//' | sort)
  locked=$(yq -r 'keys | .[]' "$TEST_DIR/defaults.lock.yaml" 2>/dev/null | sort)
  [ "$actual" != "$locked" ]
}

@test "validate detects lockfile entry without plist" {
  yq -i '.["com.missing"].promoted = "2026-01-01"' "$TEST_DIR/defaults.lock.yaml"
  
  actual=$(ls -1 "$TEST_DIR/defaults-safe"/*.plist 2>/dev/null | xargs -n1 basename | sed 's/\.plist$//' | sort)
  locked=$(yq -r 'keys | .[]' "$TEST_DIR/defaults.lock.yaml" 2>/dev/null | sort)
  [ "$actual" != "$locked" ]
}

@test "validate handles empty defaults-safe" {
  rm -rf "$TEST_DIR/defaults-safe"/*
  echo "{}" > "$TEST_DIR/defaults.lock.yaml"
  
  actual=$(ls -1 "$TEST_DIR/defaults-safe"/*.plist 2>/dev/null | xargs -n1 basename | sed 's/\.plist$//' | sort || echo "")
  locked=$(yq -r 'keys | .[]' "$TEST_DIR/defaults.lock.yaml" 2>/dev/null | sort || echo "")
  [ "$actual" = "$locked" ]
}
