# Flutter & Android 1-Click Fast Installer

A modern, zero-friction installer that takes you from a clean machine to a running Flutter "Hello World" app on an Android emulator in **under 5 minutes** with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/android_sdk_installer/main/install.sh | bash
```

---

## ⚡ The 5-Minute Setup

Instead of downloading 1.5 GB of Android Studio just to get an Android emulator, or manually hunting down Google's command-line tools zip and wrestling with directory hierarchies:

This installer leverages Google's official **Android CLI** and Google Cloud Storage to configure everything autonomously in one pass:

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

## 🚀 Usage

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

## 🛠️ Interactive Companion Manager

Once Flutter is installed, you can use the Dart companion CLI anytime to manage your Android development environment:

```bash
dart run lib/android_sdk_installer.dart
```

Features:
- **Interactive Component Management**: Choose and install specific Android API levels (34, 35, 36) and build-tools via Google's `android sdk install`.
- **AVD Profile Selector**: Browse hardware profiles (`medium_phone`, `small_phone`, `medium_desktop`, etc.) and spin up emulators on demand.
- **Environment Diagnostics**: Query active SDK configurations, connected devices, and verify `flutter doctor` health.

---

## 🧪 Testing & Clean-Room Verification

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

## 📋 Platform Support

| Operating System | Architectures | Status |
| :--- | :--- | :--- |
| **Linux** (Ubuntu, Debian, Fedora, Arch) | `x86_64`, `arm64` | ✅ Fully Supported |
| **macOS** (Apple Silicon M-Series, Intel) | `arm64`, `x86_64` | ✅ Fully Supported |
| **WSL2** (Windows Subsystem for Linux) | `x86_64` | ✅ Piggybacks on Linux targets |

---

## 📄 License

MIT License. See [LICENSE](file:///home/jwill/Documents/GitHub/android_sdk_installer/LICENSE) for details.
