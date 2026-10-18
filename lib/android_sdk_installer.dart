// ignore_for_file: avoid_print
import 'dart:io';
import 'package:interact/interact.dart';
import 'package:path/path.dart' as p;

/// Preferred Java major version.
const int javaVersionMinimum = 17;

/// Recommended Android SDK component versions
const String defaultAndroidApiLevel = '35';
const String defaultAndroidBuildToolsVersion = '35.0.0';

/// Detects the current CPU architecture and returns the corresponding Android architecture string.
String getArchitecture() {
  final version = Platform.version.toLowerCase();

  if (version.contains('arm64') || version.contains('aarch64')) {
    return 'arm64-v8a';
  } else if (version.contains('x86_64') || version.contains('amd64')) {
    return 'x86_64';
  }

  if (Platform.isMacOS) {
    final result = Process.runSync('uname', ['-m']);
    if (result.stdout.toString().trim() == 'arm64') {
      return 'arm64-v8a';
    }
  }

  return 'x86_64';
}

/// Returns the system image package string for the current architecture.
String getAndroidSystemImage(String apiLevel) {
  final arch = getArchitecture();
  return 'system-images/android-$apiLevel/google_apis/$arch';
}

/// Resolves the Google Android CLI platform string.
String getAndroidCliPlatformKey() {
  final arch = getArchitecture() == 'arm64-v8a' ? 'arm64' : 'x86_64';
  if (Platform.isMacOS) {
    return 'darwin_$arch';
  } else if (Platform.isLinux) {
    return 'linux_$arch';
  }
  return 'linux_x86_64';
}

/// Locates the `android` CLI executable in PATH or standard directories.
String? findAndroidCliBinary() {
  final home = Platform.environment['HOME'] ?? '';
  final localBinAndroid = p.join(home, '.local', 'bin', 'android');

  if (File(localBinAndroid).existsSync()) {
    return localBinAndroid;
  }

  try {
    final whichResult = Process.runSync('which', ['android']);
    if (whichResult.exitCode == 0) {
      final path = whichResult.stdout.toString().trim();
      if (path.isNotEmpty && File(path).existsSync()) {
        return path;
      }
    }
  } catch (_) {}

  return null;
}

void main() async {
  print('\n${"=" * 60}');
  print('Flutter & Android SDK Companion Manager');
  print('=' * 60);

  final os = Platform.operatingSystem;
  final home = Platform.environment['HOME'] ?? '';
  String defaultSdkRoot;

  if (Platform.isMacOS) {
    defaultSdkRoot = p.join(home, 'Library', 'Android', 'Sdk');
  } else {
    defaultSdkRoot = p.join(home, 'Android', 'Sdk');
  }

  print('Host OS: $os | Target Architecture: ${getArchitecture()}');
  print('Default Android SDK Root: $defaultSdkRoot\n');

  try {
    final androidBin = await ensureAndroidCli();
    if (androidBin == null) {
      print('Android CLI setup was aborted.');
      return;
    }

    final sdkRoot = await resolveSdkRoot(androidBin, defaultSdkRoot);
    await checkOrInstallJava();
    await installAndroidComponents(androidBin, sdkRoot);
    await createOrManageAvd(androidBin);
    await configureFlutter(sdkRoot);
    await printSummary(androidBin, sdkRoot);
  } catch (e, stack) {
    print('\nAn error occurred: $e');
    print(stack);
  }
}

/// Ensures the Google Android CLI is installed and returns its path.
Future<String?> ensureAndroidCli() async {
  String? androidBin = findAndroidCliBinary();

  if (androidBin != null) {
    print('Found Google Android CLI: $androidBin');
    return androidBin;
  }

  final installCli = Confirm(
    prompt: 'Google Android CLI is not installed. Do you want to install it now?',
    defaultValue: true,
  ).interact();

  if (!installCli) return null;

  final home = Platform.environment['HOME']!;
  final localBinDir = p.join(home, '.local', 'bin');
  final targetBin = p.join(localBinDir, 'android');
  final platformKey = getAndroidCliPlatformKey();
  final cliUrl = 'https://dl.google.com/android/cli/latest/$platformKey/android';

  print('Downloading Android CLI from $cliUrl...');
  Directory(localBinDir).createSync(recursive: true);

  final result = await Process.run('curl', ['-fsSL', cliUrl, '-o', targetBin]);
  if (result.exitCode != 0) {
    print('Failed to download Android CLI: ${result.stderr}');
    return null;
  }

  await Process.run('chmod', ['+x', targetBin]);
  print('Initializing Android CLI...');
  await Process.run(targetBin, ['init']);

  print('Android CLI successfully installed at $targetBin\n');
  return targetBin;
}

/// Resolves the SDK root via Android CLI or user input.
Future<String> resolveSdkRoot(String androidBin, String defaultSdkRoot) async {
  String sdkRoot = defaultSdkRoot;

  try {
    final infoResult = await Process.run(androidBin, ['info']);
    if (infoResult.exitCode == 0) {
      final lines = infoResult.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.startsWith('sdk:')) {
          final detected = line.substring(4).trim();
          if (detected.isNotEmpty) {
            sdkRoot = detected;
            break;
          }
        }
      }
    }
  } catch (_) {}

  return sdkRoot;
}

/// Verifies Java >= 17 is available or prompts to install via SDKMAN.
Future<void> checkOrInstallJava() async {
  bool javaValid = false;

  try {
    final javaResult = await Process.run('java', ['-version']);
    if (javaResult.exitCode == 0) {
      final raw = javaResult.stderr.toString();
      final match = RegExp(r'version "([0-9]+)').firstMatch(raw);
      if (match != null) {
        final major = int.tryParse(match.group(1)!) ?? 0;
        if (major >= javaVersionMinimum) {
          javaValid = true;
          print('Detected compatible Java version ($major) in PATH.');
        }
      }
    }
  } catch (_) {}

  if (javaValid) return;

  final wantJava = Confirm(
    prompt: 'Java >= 17 was not detected. Do you want to install Java 17 via SDKMAN?',
    defaultValue: true,
  ).interact();

  if (!wantJava) return;

  final home = Platform.environment['HOME']!;
  final sdkmanDir = p.join(home, '.sdkman');
  final sdkmanInit = p.join(sdkmanDir, 'bin', 'sdkman-init.sh');

  if (!File(sdkmanInit).existsSync()) {
    print('Installing SDKMAN...');
    final p1 = await Process.start('bash', ['-c', 'curl -s "https://get.sdkman.io?rcupdate=false" | bash']);
    await stdout.addStream(p1.stdout);
    await stderr.addStream(p1.stderr);
    await p1.exitCode;
  }

  print('Installing Amazon Corretto 17 via SDKMAN...');
  final p2 = await Process.start('bash', [
    '-c',
    'export sdkman_auto_answer=true && source $sdkmanInit && sdk install java 17.0.12-amzn || sdk install java 17-amzn',
  ]);
  await stdout.addStream(p2.stdout);
  await stderr.addStream(p2.stderr);
  await p2.exitCode;
}

/// Installs Android SDK packages using the official Android CLI.
Future<void> installAndroidComponents(String androidBin, String sdkRoot) async {
  final wantComponents = Confirm(
    prompt: 'Install/update Android SDK components (platforms, build-tools, emulator)?',
    defaultValue: true,
  ).interact();

  if (!wantComponents) return;

  final availableApis = ['35', '36', '34'];
  final selectedIndex = Select(
    prompt: 'Select target Android API level:',
    options: availableApis.map((a) => 'Android API $a (recommended: $defaultAndroidApiLevel)').toList(),
    initialIndex: 0,
  ).interact();

  final chosenApi = availableApis[selectedIndex];
  final buildToolsVer = chosenApi == '36' ? '36.0.0' : '35.0.0';
  final systemImage = getAndroidSystemImage(chosenApi);

  print('\nInstalling components via Android CLI:');
  print(' - Platform:     platforms/android-$chosenApi');
  print(' - Build Tools:  build-tools/$buildToolsVer');
  print(' - System Image: $systemImage');
  print(' - Tools:        platform-tools, emulator\n');

  final process = await Process.start(androidBin, [
    'sdk',
    'install',
    'platforms/android-$chosenApi',
    'build-tools/$buildToolsVer',
    'platform-tools',
    'emulator',
    systemImage,
  ]);

  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
  final exitCode = await process.exitCode;

  if (exitCode == 0) {
    print('\nAndroid components installed successfully.');
  } else {
    print('\nInstallation exited with code: $exitCode');
  }
}

/// Manages or creates an Android Virtual Device using Android CLI.
Future<void> createOrManageAvd(String androidBin) async {
  final listResult = await Process.run(androidBin, ['emulator', 'list']);
  final existingList = listResult.stdout.toString().trim();

  if (existingList.isNotEmpty) {
    print('\nExisting Android Virtual Devices:');
    for (final line in existingList.split('\n')) {
      if (line.trim().isNotEmpty) print('  • $line');
    }

    final createAnother = Confirm(
      prompt: 'Do you want to create an additional Android Virtual Device?',
      defaultValue: false,
    ).interact();

    if (!createAnother) return;
  }

  // Fetch available profiles
  final profilesResult = await Process.run(androidBin, ['emulator', 'create', '--list-profiles']);
  List<String> profiles = ['medium_phone', 'small_phone', 'medium_desktop', 'medium_tablet'];
  if (profilesResult.exitCode == 0) {
    final parsed = profilesResult.stdout
        .toString()
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.contains('version') && !s.contains('update'))
        .toList();
    if (parsed.isNotEmpty) profiles = parsed;
  }

  final profileIndex = Select(
    prompt: 'Select device profile for the AVD:',
    options: profiles,
    initialIndex: profiles.contains('medium_phone') ? profiles.indexOf('medium_phone') : 0,
  ).interact();

  final selectedProfile = profiles[profileIndex];
  print('\nCreating virtual device with profile: $selectedProfile...');

  final createProcess = await Process.start(androidBin, ['emulator', 'create', selectedProfile]);
  await stdout.addStream(createProcess.stdout);
  await stderr.addStream(createProcess.stderr);
  await createProcess.exitCode;

  // Enable hardware keyboard
  final home = Platform.environment['HOME']!;
  final avdDir = p.join(home, '.android', 'avd');
  if (Directory(avdDir).existsSync()) {
    for (final entry in Directory(avdDir).listSync()) {
      if (entry is Directory && entry.path.endsWith('.avd')) {
        final configFile = File(p.join(entry.path, 'config.ini'));
        if (configFile.existsSync()) {
          final content = configFile.readAsStringSync();
          if (content.contains('hw.keyboard')) {
            configFile.writeAsStringSync(content.replaceAll(RegExp(r'hw\.keyboard\s*=\s*.*'), 'hw.keyboard=yes'));
          } else {
            configFile.writeAsStringSync('$content\nhw.keyboard=yes\n');
          }
        }
      }
    }
  }
}

/// Configures Flutter to use the Android SDK and accepts licenses.
Future<void> configureFlutter(String sdkRoot) async {
  final configure = Confirm(
    prompt: 'Configure Flutter Android SDK path and verify licenses?',
    defaultValue: true,
  ).interact();

  if (!configure) return;

  try {
    print('\nConfiguring Flutter Android SDK path: $sdkRoot');
    await Process.run('flutter', ['config', '--android-sdk', sdkRoot]);

    print('Verifying Android licenses...');
    final licenseProcess = await Process.start('bash', ['-c', 'yes | flutter doctor --android-licenses']);
    await stdout.addStream(licenseProcess.stdout);
    await stderr.addStream(licenseProcess.stderr);
    await licenseProcess.exitCode;

    print('\nRunning flutter doctor...');
    final doctor = await Process.start('flutter', ['doctor']);
    await stdout.addStream(doctor.stdout);
    await stderr.addStream(doctor.stderr);
    await doctor.exitCode;
  } catch (e) {
    print('Flutter configuration notice: $e');
  }
}

/// Prints summary of the installation.
Future<void> printSummary(String androidBin, String sdkRoot) async {
  print('\n${"=" * 60}');
  print('SETUP SUMMARY');
  print('=' * 60);
  print('Android SDK: $sdkRoot');
  print('Android CLI: $androidBin');

  try {
    final list = await Process.run(androidBin, ['emulator', 'list']);
    print('\nConfigured Emulators:');
    print(list.stdout.toString().trim());
  } catch (_) {}

  print('\nQuick Start:');
  print('1. Launch an emulator:  flutter emulators --launch <name>');
  print('2. Run Flutter app:     flutter run');
  print('=' * 60 + '\n');
}
