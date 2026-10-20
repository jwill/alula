# Flutter & Android 1-Click Fast Installer

A modern, zero-friction installer that takes you from a clean machine to a running Flutter "Hello World" app on an Android emulator in **under 5 minutes** with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/android_sdk_installer/main/install.sh | bash
```

---

## The 5-Minute Setup

Instead of downloading 1.5 GB of Android Studio just to get an Android emulator, or manually hunting down Google's command-line tools zip and wrestling with directory hierarchies:

This installer leverages Google's official **Android CLI** for Android setup to configure everything autonomously in one pass:

```
[1/7] Detect OS & CPU Architecture (Linux / macOS, x64 / arm64)
[2/7] Download & Bootstrap latest stable Flutter SDK
[3/7] Verify or install Java 17 LTS via SDKMAN
[4/7] Install Google Android CLI (~/.local/bin/android)
[5/7] Install Android SDK, Platform 35/36, Build-Tools, & System Image
[6/7] Create AVD ('medium_phone') & Enable Hardware Keyboard
[7/7] Scaffold Hello World app & run 'flutter doctor'
```

---

## Usage

### 1. The 1-Click Command (Zero Dependencies)
Run directly in your terminal (Linux, macOS, or WSL):
```bash
curl -fsSL https://raw.githubusercontent.com/<user>/android_sdk_installer/main/install.sh | bash
```

### 2. Running Locally with Options
You can clone the repository and run with customizable options:
```bash
./install.sh [options]

Options:
  --dry-run           Print planned actions without downloading or modifying files
  --non-interactive   Run without interactive confirmation prompts
  --skip-emulator     Do not create an Android Virtual Device (AVD)
  --skip-sample       Do not scaffold the Hello World Flutter application
  --update-profile    Only update shell profile environment exports and exit
  --help, -h          Show help message
```

#### Customizing Installation Directories
The script supports environment variable overrides:
```bash
FLUTTER_DEST_DIR="$HOME/tools/flutter" \
ANDROID_SDK_ROOT="$HOME/Android/Sdk" \
LOCAL_BIN_DIR="$HOME/.local/bin" \
./install.sh
```

---

## Flutter Desktop Studio GUI

Once Flutter is installed, launch the visual **Android SDK Studio** desktop app (built with Flutter Desktop and `signals.dart`):

```bash
flutter run
```

Features:
- **System Health Dashboard**: Real-time status cards for Flutter SDK, Java Runtime (JDK 17), and Google Android CLI / SDK Root.
- **Visual Package Manager**: Browse, install, and update Android API platforms (34, 35, 36), Build-Tools, and System Images with one click.
- **AVD Studio**: Manage emulators, create new virtual devices with custom hardware profiles, and launch emulators directly from the UI.
- **1-Click Diagnostics & Doctor**: Run `flutter doctor` diagnostics, accept licenses non-interactively, and re-link SDK paths.
- **Live Process Console**: Collapsible bottom console drawer with real-time streaming stdout/stderr execution logs.
- **Theme Toggle**: Built-in Material 3 Light and Dark mode switching.

---

## Testing & Clean-Room Verification

To test the installer safely on a machine that already has Flutter or Android installed without altering any host files or configuration, run the clean-room sandbox test suite:

```bash
./test/test_sandbox_install.sh
```

This test:
1. Provisions an ephemeral sandbox directory in `/tmp`.
2. Strips all host environment paths using `env -i`, hiding any existing host Flutter, Java, or Android installations.
3. Simulates a clean-slate system to verify all installer phases end-to-end.
4. Verifies idempotent `.bashrc` updates (ensuring only one configuration block is written).
5. Guarantees that the host development environment is 100% untouched.

---

## Platform Support

| Operating System | Architectures | Status |
| :--- | :--- | :--- |
| **Linux** (Ubuntu, Debian, Fedora, Arch) | `x86_64`, `arm64` | ✅ Fully Supported |
| **macOS** (Apple Silicon M-Series, Intel) | `arm64`, `x86_64` | ✅ Fully Supported |
| **WSL2** (Windows Subsystem for Linux) | `x86_64` | ✅ Piggybacks on Linux targets |
