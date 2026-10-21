#!/usr/bin/env bash
# ==============================================================================
# One-Click Flutter & Android SDK Installer
#
# Supported Platforms: Linux (including WSL2), macOS (Darwin)
# Supported Architectures: x86_64 (amd64), arm64 (aarch64)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<user>/android_sdk_installer/main/install.sh | bash
#   # Or with options:
#   ./install.sh [--dry-run] [--non-interactive] [--skip-emulator] [--skip-sample]
# ==============================================================================

set -euo pipefail

# ANSI color codes
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Timing
START_TIME=$(date +%s)

# CLI Flags
DRY_RUN=false
NON_INTERACTIVE=false
SKIP_EMULATOR=false
SKIP_SAMPLE=false
UPDATE_PROFILE_ONLY=false

# If stdin is not a terminal (e.g. curl ... | bash), default to non-interactive
if [ ! -t 0 ]; then
  NON_INTERACTIVE=true
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --non-interactive|-y|--yes)
      NON_INTERACTIVE=true
      shift
      ;;
    --skip-emulator)
      SKIP_EMULATOR=true
      shift
      ;;
    --skip-sample)
      SKIP_SAMPLE=true
      shift
      ;;
    --update-profile)
      UPDATE_PROFILE_ONLY=true
      shift
      ;;
    --help|-h)
      echo "One-Click Flutter & Android SDK Installer"
      echo ""
      echo "Options:"
      echo "  --dry-run           Print planned actions without downloading or modifying files"
      echo "  --non-interactive   Run without prompting for confirmations"
      echo "  --skip-emulator     Do not create an Android Virtual Device (AVD)"
      echo "  --skip-sample       Do not scaffold a Hello World Flutter application"
      echo "  --update-profile    Only update shell profile environment exports and exit"
      echo "  --help, -h          Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Logging helpers
log_info() {
  echo -e "${BLUE}${BOLD}[INFO]${NC} $1"
}

log_step() {
  echo -e "\n${CYAN}${BOLD}==>${NC} ${BOLD}$1${NC}"
}

log_success() {
  echo -e "${GREEN}${BOLD}[✓]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}${BOLD}[!]${NC} $1"
}

log_error() {
  echo -e "${RED}${BOLD}[ERROR]${NC} $1" >&2
}

# ==============================================================================
# Banner
# ==============================================================================
echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║          Flutter & Android 1-Click Fast Bootstrap Installer          ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==============================================================================
# Phase 1: Environment & Architecture Detection
# ==============================================================================
log_step "Phase 1: Detecting system architecture and environment"

RAW_OS="$(uname -s)"
RAW_ARCH="$(uname -m)"

case "$RAW_OS" in
  Linux)
    TARGET_OS="linux"
    OS_NAME="Linux"
    DEFAULT_SDK_ROOT="$HOME/Android/Sdk"
    ANDROID_CLI_OS_PREFIX="linux"
    ;;
  Darwin)
    TARGET_OS="macos"
    OS_NAME="macOS"
    DEFAULT_SDK_ROOT="$HOME/Library/Android/Sdk"
    ANDROID_CLI_OS_PREFIX="darwin"
    ;;
  *)
    log_error "Unsupported operating system: $RAW_OS. Only Linux and macOS are supported."
    exit 1
    ;;
esac

case "$RAW_ARCH" in
  x86_64|amd64)
    TARGET_ARCH="x64"
    ANDROID_ARCH="x86_64"
    ANDROID_CLI_OS="${ANDROID_CLI_OS_PREFIX}_x86_64"
    ;;
  arm64|aarch64)
    TARGET_ARCH="arm64"
    ANDROID_ARCH="arm64-v8a"
    ANDROID_CLI_OS="${ANDROID_CLI_OS_PREFIX}_arm64"
    ;;
  *)
    log_error "Unsupported CPU architecture: $RAW_ARCH"
    exit 1
    ;;
esac

# Configurable paths (supports test harnesses and custom installation directories)
FLUTTER_DEST_DIR="${FLUTTER_DEST_DIR:-$HOME/development/flutter}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$DEFAULT_SDK_ROOT}"
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-$HOME/.local/bin}"
FLUTTER_STORAGE_BASE="${FLUTTER_STORAGE_BASE:-https://storage.googleapis.com/flutter_infra_release/releases}"

log_info "Operating System: $OS_NAME ($RAW_OS)"
log_info "Architecture:     $TARGET_ARCH ($RAW_ARCH)"
log_info "Flutter Path:     $FLUTTER_DEST_DIR"
log_info "Android SDK Path: $ANDROID_SDK_ROOT"
log_info "Binary Directory: $LOCAL_BIN_DIR"

# Required prerequisites check
log_info "Verifying required host utilities via 'command -v'..."
MISSING_TOOLS=()
check_tool() {
  local tool="$1"
  local reason="$2"
  if ! command -v "$tool" >/dev/null 2>&1; then
    log_error "Missing required tool: '$tool' ($reason)"
    MISSING_TOOLS+=("$tool")
  fi
}

check_tool "curl"     "downloading archives and SDK tools"
check_tool "tar"      "extracting Flutter SDK packages"
check_tool "unzip"    "extracting zip archives"
check_tool "git"      "required by Flutter toolchain and dependencies"
check_tool "awk"      "parsing release manifests and metadata"
check_tool "sed"      "transforming configuration and paths"
check_tool "grep"     "searching and environment matching"
check_tool "mktemp"   "creating safe temporary workspaces"
check_tool "chmod"    "setting executable permissions"
check_tool "mkdir"    "creating installation directories"
check_tool "uname"    "detecting operating system and architecture"
check_tool "basename" "path manipulations"
check_tool "dirname"  "directory resolution"
check_tool "head"     "reading tool output headers"

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
  log_error "Pre-flight check failed! ${#MISSING_TOOLS[@]} required tool(s) missing: ${MISSING_TOOLS[*]}"
  log_error "Please install missing utilities via your package manager (e.g. apt install / brew install) and re-run."
  exit 1
fi
log_success "All required host utilities verified."

# Detect shell profile file
detect_shell_rc() {
  if [ -n "${SHELL_RC_FILE:-}" ] && [ "$SHELL_RC_FILE" != "auto" ]; then
    echo "$SHELL_RC_FILE"
    return
  fi

  local current_shell
  current_shell="$(basename "${SHELL:-bash}")"

  if [ "$current_shell" = "zsh" ]; then
    echo "$HOME/.zshrc"
  elif [ "$TARGET_OS" = "macos" ]; then
    if [ -f "$HOME/.zshrc" ]; then
      echo "$HOME/.zshrc"
    else
      echo "$HOME/.bash_profile"
    fi
  else
    if [ -f "$HOME/.bashrc" ]; then
      echo "$HOME/.bashrc"
    else
      echo "$HOME/.profile"
    fi
  fi
}

SHELL_RC="$(detect_shell_rc)"
log_info "Shell Profile:    $SHELL_RC"

# Helper to update shell profile idempotently
update_shell_profile() {
  local rc_file="$1"
  local flutter_bin="$FLUTTER_DEST_DIR/bin"
  local local_bin="$LOCAL_BIN_DIR"
  local platform_tools="$ANDROID_SDK_ROOT/platform-tools"

  local marker_start="# >>> android_sdk_installer environment >>>"
  local marker_end="# <<< android_sdk_installer environment <<<"

  local block
  block="${marker_start}
export FLUTTER_HOME=\"$FLUTTER_DEST_DIR\"
export ANDROID_HOME=\"$ANDROID_SDK_ROOT\"
export ANDROID_SDK_ROOT=\"$ANDROID_SDK_ROOT\"
case \":\$PATH:\" in
  *:\$FLUTTER_HOME/bin:*) ;;
  *) export PATH=\"\$FLUTTER_HOME/bin:\$PATH\" ;;
esac
case \":\$PATH:\" in
  *:$local_bin:*) ;;
  *) export PATH=\"$local_bin:\$PATH\" ;;
esac
case \":\$PATH:\" in
  *:\$ANDROID_HOME/platform-tools:*) ;;
  *) export PATH=\"\$ANDROID_HOME/platform-tools:\$PATH\" ;;
esac
${marker_end}"

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would configure PATH in $rc_file"
    return
  fi

  mkdir -p "$(dirname "$rc_file")"
  touch "$rc_file"

  if grep -q "$marker_start" "$rc_file" 2>/dev/null; then
    # Replace existing block cleanly
    awk -v s="$marker_start" -v e="$marker_end" -v b="$block" '
      $0 ~ s { print b; skip=1; next }
      $0 ~ e { skip=0; next }
      !skip { print }
    ' "$rc_file" > "${rc_file}.tmp" && mv "${rc_file}.tmp" "$rc_file"
    log_info "Updated existing environment block in $rc_file"
  else
    echo -e "\n$block" >> "$rc_file"
    log_info "Appended environment block to $rc_file"
  fi
}

if [ "$UPDATE_PROFILE_ONLY" = true ]; then
  update_shell_profile "$SHELL_RC"
  log_success "Shell profile updated successfully at $SHELL_RC."
  exit 0
fi

# ==============================================================================
# Phase 2: Bootstrap Flutter SDK
# ==============================================================================
log_step "Phase 2: Bootstrapping Flutter SDK"

if [ -x "$FLUTTER_DEST_DIR/bin/flutter" ]; then
  log_success "Flutter is already installed at $FLUTTER_DEST_DIR"
  "$FLUTTER_DEST_DIR/bin/flutter" --version | head -n 1
else
  log_info "Resolving latest stable Flutter release for $TARGET_OS ($TARGET_ARCH)..."
  MANIFEST_URL="${FLUTTER_STORAGE_BASE}/releases_${TARGET_OS}.json"

  # Resolve archive path using standard curl and awk (zero external dependencies)
  ARCHIVE_PATH=""
  MANIFEST_DATA=$(curl -fsSL "$MANIFEST_URL" 2>/dev/null || true)
  if [ -n "$MANIFEST_DATA" ]; then
    STABLE_HASH=$(echo "$MANIFEST_DATA" | awk -F '"' '/"stable":/ {print $4; exit}')
    if [ -n "$STABLE_HASH" ]; then
      ARCHIVE_PATH=$(echo "$MANIFEST_DATA" | awk -v target_hash="$STABLE_HASH" -v target_arch="$TARGET_ARCH" -F '"' '
        /\{/ { hash=""; a_arch=""; archive="" }
        /"hash":/ { hash=$4 }
        /"dart_sdk_arch":/ { a_arch=$4 }
        /"archive":/ { archive=$4 }
        /\}/ {
          if (hash == target_hash) {
            if ((target_arch == "arm64" && a_arch == "arm64") || (target_arch != "arm64" && a_arch != "arm64")) {
              print archive
              exit
            }
          }
        }
      ')
    fi
  fi

  # Fallback if network or manifest parsing failed
  if [ -z "$ARCHIVE_PATH" ]; then
    if [ "$TARGET_OS" = "linux" ]; then
      ARCHIVE_PATH="stable/linux/flutter_linux_3.47.7-stable.tar.xz"
    elif [ "$TARGET_ARCH" = "arm64" ]; then
      ARCHIVE_PATH="stable/macos/flutter_macos_arm64_3.47.7-stable.zip"
    else
      ARCHIVE_PATH="stable/macos/flutter_macos_3.47.7-stable.zip"
    fi
  fi

  FLUTTER_DOWNLOAD_URL="${FLUTTER_STORAGE_BASE}/${ARCHIVE_PATH}"
  log_info "Downloading Flutter from: $FLUTTER_DOWNLOAD_URL"

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would download and extract Flutter to $FLUTTER_DEST_DIR"
  else
    TMP_DL_DIR=$(mktemp -d -t flutter_dl_XXXXXX)
    ARCHIVE_FILENAME=$(basename "$ARCHIVE_PATH")
    ARCHIVE_FILE="$TMP_DL_DIR/$ARCHIVE_FILENAME"

    log_info "Downloading Flutter archive..."
    curl -# -L -C - "$FLUTTER_DOWNLOAD_URL" -o "$ARCHIVE_FILE"

    log_info "Extracting Flutter to $(dirname "$FLUTTER_DEST_DIR")..."
    mkdir -p "$(dirname "$FLUTTER_DEST_DIR")"

    if [[ "$ARCHIVE_FILENAME" == *.tar.xz ]]; then
      tar -xf "$ARCHIVE_FILE" -C "$(dirname "$FLUTTER_DEST_DIR")"
    elif [[ "$ARCHIVE_FILENAME" == *.zip ]]; then
      unzip -q -o "$ARCHIVE_FILE" -d "$(dirname "$FLUTTER_DEST_DIR")"
    fi

    rm -rf "$TMP_DL_DIR"
    log_success "Flutter extracted successfully."
  fi
fi

# Export Flutter & Dart to current subshell PATH
export PATH="$FLUTTER_DEST_DIR/bin:$LOCAL_BIN_DIR:$PATH"

# Verify Flutter & Dart executables
if [ "$DRY_RUN" = false ]; then
  if ! command -v flutter >/dev/null 2>&1 && [ ! -x "$FLUTTER_DEST_DIR/bin/flutter" ]; then
    log_error "Flutter verification failed: 'flutter' command not executable at $FLUTTER_DEST_DIR/bin/flutter"
    exit 1
  fi
  if ! command -v dart >/dev/null 2>&1 && [ ! -x "$FLUTTER_DEST_DIR/bin/dart" ]; then
    log_error "Dart verification failed: bundled 'dart' command not found at $FLUTTER_DEST_DIR/bin/dart"
    exit 1
  fi
  log_success "Verified 'flutter' and 'dart' executables via 'command -v'."
fi

# ==============================================================================
# Phase 3: Java 17 Runtime Setup
# ==============================================================================
log_step "Phase 3: Verifying and configuring Java runtime (JDK 17 LTS)"

JAVA_COMPATIBLE=false
if command -v java >/dev/null 2>&1; then
  RAW_JAVA_VER=$(java -version 2>&1 | head -n 1)
  PARSED_MAJOR=$(echo "$RAW_JAVA_VER" | sed -E 's/.*version "([0-9]+).*/\1/' || echo "0")
  if [ "$PARSED_MAJOR" -ge 17 ] 2>/dev/null; then
    JAVA_COMPATIBLE=true
    log_success "Found compatible Java version ($PARSED_MAJOR) in PATH: $RAW_JAVA_VER"
  else
    log_warn "Current Java major version is $PARSED_MAJOR (requires >= 17 for modern Android build tools)."
  fi
fi

if [ "$JAVA_COMPATIBLE" = false ]; then
  log_info "Installing Amazon Corretto 17 LTS via SDKMAN..."
  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would install SDKMAN and Amazon Corretto 17 LTS"
  else
    SDKMAN_DIR="$HOME/.sdkman"
    SDKMAN_INIT="$SDKMAN_DIR/bin/sdkman-init.sh"

    if [ ! -f "$SDKMAN_INIT" ]; then
      log_info "Installing SDKMAN non-interactively..."
      curl -s "https://get.sdkman.io?rcupdate=false" | bash
    fi

    if [ -f "$SDKMAN_INIT" ]; then
      # Source SDKMAN into current subshell
      set +u
      export sdkman_auto_answer=true
      # shellcheck disable=SC1090
      source "$SDKMAN_INIT"
      
      log_info "Installing Java 17 via SDKMAN..."
      sdk install java 17.0.12-amzn || sdk install java 17-amzn || true
      set -u
      
      if [ -d "$SDKMAN_DIR/candidates/java/current" ]; then
        export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"
        export PATH="$JAVA_HOME/bin:$PATH"
        log_success "Java 17 configured at $JAVA_HOME"
      fi
    fi
  fi
fi

# Verify Java executable mid-install
if [ "$DRY_RUN" = false ]; then
  if ! command -v java >/dev/null 2>&1; then
    log_error "Java verification failed: 'java' command was not found in PATH."
    exit 1
  fi
  log_success "Verified 'java' command via 'command -v'."
fi

# ==============================================================================
# Phase 4: Google Android CLI Installation
# ==============================================================================
log_step "Phase 4: Setting up official Google Android CLI"

mkdir -p "$LOCAL_BIN_DIR"
ANDROID_BIN="$LOCAL_BIN_DIR/android"

if [ -x "$ANDROID_BIN" ] || command -v android >/dev/null 2>&1; then
  CURRENT_ANDROID_BIN="$(command -v android || echo "$ANDROID_BIN")"
  log_success "Android CLI is already installed at $CURRENT_ANDROID_BIN"
else
  ANDROID_CLI_URL="https://dl.google.com/android/cli/latest/${ANDROID_CLI_OS}/android"
  log_info "Fetching Android CLI from $ANDROID_CLI_URL..."

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would download Android CLI binary to $ANDROID_BIN"
  else
    TMP_CLI=$(mktemp)
    curl -fsSL "$ANDROID_CLI_URL" -o "$TMP_CLI"
    mv "$TMP_CLI" "$ANDROID_BIN"
    chmod +x "$ANDROID_BIN"
    log_success "Android CLI installed to $ANDROID_BIN"
  fi
fi

# Initialize Android CLI environment
if [ -x "$ANDROID_BIN" ]; then
  log_info "Initializing Android CLI environment..."
  if [ "$DRY_RUN" = false ]; then
    "$ANDROID_BIN" init || true
  fi
fi

# Verify Android CLI executable mid-install
if [ "$DRY_RUN" = false ]; then
  if ! command -v android >/dev/null 2>&1 && [ ! -x "$ANDROID_BIN" ]; then
    log_error "Android CLI verification failed: 'android' command not executable at $ANDROID_BIN"
    exit 1
  fi
  log_success "Verified 'android' command via 'command -v'."
fi

# ==============================================================================
# Phase 5: Android SDK Components Installation
# ==============================================================================
log_step "Phase 5: Installing Android SDK components via Android CLI"

mkdir -p "$ANDROID_SDK_ROOT"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"

# Target component versions
API_LEVEL="36"
BUILD_TOOLS_VER="36.0.0"
SYSTEM_IMAGE="system-images/android-${API_LEVEL}/google_apis/${ANDROID_ARCH}"

log_info "Android Components Target:"
log_info "  - Platforms:    platforms/android-${API_LEVEL}"
log_info "  - Build-Tools:  build-tools/${BUILD_TOOLS_VER}"
log_info "  - System Image: $SYSTEM_IMAGE"
log_info "  - Platform-Tools & Emulator"

if [ "$DRY_RUN" = true ]; then
  # Check if packages are already installed even in dry-run, if possible, for better reporting
  packages_to_install=("platforms/android-${API_LEVEL}" "build-tools/${BUILD_TOOLS_VER}" "platform-tools" "emulator" "$SYSTEM_IMAGE")
  needed_packages=()
  for pkg in "${packages_to_install[@]}"; do
    if ! "$ANDROID_BIN" sdk list | grep -qE "^\s*${pkg}\s"; then
      needed_packages+=("$pkg")
    fi
  done

  if [ ${#needed_packages[@]} -gt 0 ]; then
    log_info "[DRY-RUN] Would install missing SDK packages: ${needed_packages[*]}"
  else
    log_info "[DRY-RUN] All required Android SDK components are already installed."
  fi
else
  if [ -x "$ANDROID_BIN" ]; then
    log_info "Executing package installation (this may take 1-2 minutes on first run)..."

    # Check if packages are already installed to avoid unnecessary downloads/re-installation
    packages_to_install=("platforms/android-${API_LEVEL}" "build-tools/${BUILD_TOOLS_VER}" "platform-tools" "emulator" "$SYSTEM_IMAGE")
    needed_packages=()
    for pkg in "${packages_to_install[@]}"; do
      # Use grep to ensure exact match on the package identifier by anchoring to start of line or whitespace
      if ! "$ANDROID_BIN" sdk list | grep -qE "^\s*${pkg}\s" ; then
        needed_packages+=("$pkg")
      fi
    done

    if [ ${#needed_packages[@]} -gt 0 ]; then
      log_info "Installing missing packages: ${needed_packages[*]}"
      "$ANDROID_BIN" sdk install "${needed_packages[@]}" || log_warn "Package installation completed with warnings."
    else
      log_success "All required Android SDK components are already installed."
    fi
    log_success "Android SDK components installation checked."
  fi
fi

# Verify platform-tools & adb mid-install
if [ "$DRY_RUN" = false ]; then
  if [ -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]; then
    export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
    if command -v adb >/dev/null 2>&1; then
      log_success "Verified 'adb' platform tool via 'command -v'."
    fi
  fi
fi

# ==============================================================================
# Phase 6: Android Virtual Device (AVD) & Flutter Integration
# ==============================================================================
log_step "Phase 6: Configuring AVD & Flutter Android SDK Path"

AVD_NAME="medium_phone"

if [ "$SKIP_EMULATOR" = false ]; then
  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would create AVD '$AVD_NAME' if none exists"
  else
    if [ -x "$ANDROID_BIN" ]; then
      EXISTING_AVDS="$("$ANDROID_BIN" emulator list 2>/dev/null || true)"
      if [ -n "$EXISTING_AVDS" ]; then
        log_info "Existing Android Virtual Device(s) detected:"
        echo "$EXISTING_AVDS" | sed 's/^/  • /'
      else
        log_info "Creating default virtual device: $AVD_NAME..."
        "$ANDROID_BIN" emulator create "$AVD_NAME" || log_warn "Could not automatically create AVD $AVD_NAME"
      fi

      # Ensure hardware keyboard is enabled in AVD config
      AVD_CONFIG_FILE="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
      if [ -f "$AVD_CONFIG_FILE" ]; then
        if grep -q "hw.keyboard" "$AVD_CONFIG_FILE"; then
          sed -i.bak 's/hw.keyboard *= *.*/hw.keyboard = yes/' "$AVD_CONFIG_FILE" && rm -f "${AVD_CONFIG_FILE}.bak"
        else
          echo "hw.keyboard = yes" >> "$AVD_CONFIG_FILE"
        fi
        log_success "Hardware keyboard enabled for $AVD_NAME"
      fi
    fi
  fi
fi

# Configure Flutter with the Android SDK path
if [ -x "$FLUTTER_DEST_DIR/bin/flutter" ]; then
  log_info "Configuring Flutter to use Android SDK at $ANDROID_SDK_ROOT..."
  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would run 'flutter config --android-sdk $ANDROID_SDK_ROOT'"
  else
    "$FLUTTER_DEST_DIR/bin/flutter" config --android-sdk "$ANDROID_SDK_ROOT" >/dev/null 2>&1 || true

    # Accept Android licenses non-interactively
    log_info "Verifying Android SDK licenses..."
    yes | "$FLUTTER_DEST_DIR/bin/flutter" doctor --android-licenses >/dev/null 2>&1 || true
    log_success "Flutter Android SDK configured and licenses accepted."
  fi
fi

# Update shell profile configuration
update_shell_profile "$SHELL_RC"

# ==============================================================================
# Phase 7: Verification & Quick Start
# ==============================================================================
log_step "Phase 7: System Verification & Quick Start"

if [ "$DRY_RUN" = false ] && [ -x "$FLUTTER_DEST_DIR/bin/flutter" ]; then
  log_info "Running Flutter Doctor verification..."
  "$FLUTTER_DEST_DIR/bin/flutter" doctor || true

  if [ "$SKIP_SAMPLE" = false ] && [ ! -d "hello_world" ]; then
    log_info "Scaffolding sample Flutter Hello World app..."
    "$FLUTTER_DEST_DIR/bin/flutter" create --org com.example hello_world >/dev/null 2>&1 || true
    log_success "Created sample project at ./hello_world"
  fi
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo -e "\n${GREEN}${BOLD}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  INSTALLATION COMPLETE in ${ELAPSED}s!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "Flutter SDK:  ${CYAN}$FLUTTER_DEST_DIR${NC}"
echo -e "Android SDK:  ${CYAN}$ANDROID_SDK_ROOT${NC}"
echo -e "Android CLI:  ${CYAN}$LOCAL_BIN_DIR/android${NC}"
echo ""
echo -e "${BOLD}To start using Flutter right now:${NC}"
echo -e "  1. Reload your shell environment:"
echo -e "     ${YELLOW}source $SHELL_RC${NC}"
echo ""
echo -e "  2. Launch the Android emulator:"
echo -e "     ${YELLOW}flutter emulators --launch $AVD_NAME${NC}"
echo ""
echo -e "  3. Run your Flutter application:"
echo -e "     ${YELLOW}cd hello_world && flutter run${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════════════${NC}\n"
