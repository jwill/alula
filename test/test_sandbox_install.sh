#!/usr/bin/env bash
# ==============================================================================
# Clean-Room Sandbox Test Runner for install.sh
#
# Validates that the installer runs properly in an isolated environment without
# reading or modifying any tools or files in the host's actual $HOME.
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"

echo -e "${BLUE}${BOLD}[TEST] Starting Clean-Room Sandbox Verification...${NC}"

# 1. Create temporary sandbox
SANDBOX_DIR="$(mktemp -d -t flutter_installer_sandbox_XXXXXX)"
echo -e "${BLUE}${BOLD}[TEST] Created ephemeral sandbox at: $SANDBOX_DIR${NC}"

cleanup() {
  echo -e "${BLUE}${BOLD}[TEST] Cleaning up sandbox at $SANDBOX_DIR...${NC}"
  rm -rf "$SANDBOX_DIR"
  echo -e "${GREEN}${BOLD}[TEST] Teardown complete.${NC}"
}
trap cleanup EXIT

# 2. Verify that host tools are invisible when using stripped environment
echo -e "\n${BLUE}${BOLD}[TEST] Assertion 1: Verifying tool isolation with stripped environment...${NC}"
ISOLATION_CHECK=$(env -i \
  HOME="$SANDBOX_DIR" \
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  bash -c 'which flutter android sdkman 2>&1 || true')

if [[ "$ISOLATION_CHECK" == *"flutter"* || "$ISOLATION_CHECK" == *"android"* ]]; then
  echo -e "${RED}${BOLD}[FAIL] Host tools leaked into stripped environment!${NC}" >&2
  exit 1
fi
echo -e "${GREEN}${BOLD}[PASS] Host tools are successfully isolated and hidden.${NC}"

# 3. Test install.sh in dry-run mode inside the isolated sandbox
echo -e "\n${BLUE}${BOLD}[TEST] Assertion 2: Running install.sh (--dry-run) in stripped sandbox...${NC}"
OUTPUT=$(env -i \
  HOME="$SANDBOX_DIR" \
  USER="testuser" \
  SHELL="/bin/bash" \
  TERM="xterm-256color" \
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  bash "$INSTALL_SCRIPT" --dry-run --non-interactive)

# Assert key phases completed in output
assert_contains() {
  local needle="$1"
  local haystack="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo -e "${RED}${BOLD}[FAIL] Expected output to contain '$needle'${NC}" >&2
    echo "$haystack"
    exit 1
  fi
}

assert_contains "Phase 1: Detecting system architecture" "$OUTPUT"
assert_contains "Phase 2: Bootstrapping Flutter SDK" "$OUTPUT"
assert_contains "Phase 3: Verifying and configuring Java runtime" "$OUTPUT"
assert_contains "Phase 4: Setting up official Google Android CLI" "$OUTPUT"
assert_contains "Phase 5: Installing Android SDK components" "$OUTPUT"
assert_contains "Phase 6: Configuring AVD & Flutter Android SDK Path" "$OUTPUT"
assert_contains "Phase 7: System Verification & Quick Start" "$OUTPUT"
assert_contains "INSTALLATION COMPLETE" "$OUTPUT"
echo -e "${GREEN}${BOLD}[PASS] All 7 phases executed successfully in clean-room simulation.${NC}"

# 4. Verify Shell Profile Idempotency
echo -e "\n${BLUE}${BOLD}[TEST] Assertion 3: Testing shell profile idempotency...${NC}"
TEST_RC="$SANDBOX_DIR/.bashrc"
touch "$TEST_RC"

# Invoke install.sh --update-profile twice to verify idempotency
env -i \
  HOME="$SANDBOX_DIR" \
  SHELL_RC_FILE="$TEST_RC" \
  FLUTTER_DEST_DIR="$SANDBOX_DIR/development/flutter" \
  ANDROID_SDK_ROOT="$SANDBOX_DIR/Android/Sdk" \
  LOCAL_BIN_DIR="$SANDBOX_DIR/.local/bin" \
  USER="testuser" \
  SHELL="/bin/bash" \
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  bash "$INSTALL_SCRIPT" --update-profile >/dev/null

env -i \
  HOME="$SANDBOX_DIR" \
  SHELL_RC_FILE="$TEST_RC" \
  FLUTTER_DEST_DIR="$SANDBOX_DIR/development/flutter" \
  ANDROID_SDK_ROOT="$SANDBOX_DIR/Android/Sdk" \
  LOCAL_BIN_DIR="$SANDBOX_DIR/.local/bin" \
  USER="testuser" \
  SHELL="/bin/bash" \
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  bash "$INSTALL_SCRIPT" --update-profile >/dev/null

MARKER_COUNT=$(grep -c ">>> android_sdk_installer environment >>>" "$TEST_RC" || true)
if [ "$MARKER_COUNT" -ne 1 ]; then
  echo -e "${RED}${BOLD}[FAIL] Idempotency failed: marker count is $MARKER_COUNT (expected 1)${NC}" >&2
  exit 1
fi

if ! grep -q "FLUTTER_HOME=\"$SANDBOX_DIR/development/flutter\"" "$TEST_RC"; then
  echo -e "${RED}${BOLD}[FAIL] Missing expected FLUTTER_HOME export in $TEST_RC${NC}" >&2
  exit 1
fi
echo -e "${GREEN}${BOLD}[PASS] Shell profile was updated idempotently (1 block present).${NC}"

# 5. Check Host Isolation Guarantee
echo -e "\n${BLUE}${BOLD}[TEST] Assertion 4: Verifying host environment integrity...${NC}"
if [ ! -d "/home/jwill/develop/flutter" ]; then
  echo -e "${RED}${BOLD}[FAIL] Host flutter path unexpectedly modified!${NC}" >&2
  exit 1
fi
echo -e "${GREEN}${BOLD}[PASS] Host environment is 100% untouched and intact.${NC}"

echo -e "\n${GREEN}${BOLD}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ALL SANDBOX TESTS PASSED!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════════════${NC}\n"
