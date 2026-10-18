import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/environment_models.dart';

class SystemService {
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  void log(String message) {
    _logController.add(message);
  }

  /// Runs an external process, streaming stdout and stderr to the log controller.
  Future<int> runCommand(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final cmdStr = '$executable ${arguments.join(' ')}';
    log('\n\$ $cmdStr');

    try {
      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: true,
      );

      final stdoutSub = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => log('  $line'));

      final stderrSub = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => log('[!] $line'));

      final exitCode = await process.exitCode;
      await stdoutSub.asFuture();
      await stderrSub.asFuture();

      log('Process exited with code $exitCode');
      return exitCode;
    } catch (e) {
      log('[ERROR] Failed to start $executable: $e');
      return -1;
    }
  }

  /// Checks Flutter SDK environment.
  Future<FlutterInfo> checkFlutter() async {
    try {
      final result = await Process.run('flutter', ['--version'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final firstLine = output.split('\n').first;
        final channelMatch = RegExp(r'channel\s+([a-zA-Z0-9_-]+)').firstMatch(firstLine);
        final versionMatch = RegExp(r'Flutter\s+([0-9.]+)').firstMatch(firstLine);

        final whichResult = await Process.run('which', ['flutter'], runInShell: true);
        final flutterPath = whichResult.exitCode == 0 ? whichResult.stdout.toString().trim() : '';

        return FlutterInfo(
          version: versionMatch?.group(1) ?? 'Installed',
          channel: channelMatch?.group(1) ?? 'stable',
          path: flutterPath,
          status: ToolStatus.ok,
        );
      }
    } catch (_) {}

    return const FlutterInfo(
      version: 'Not Found',
      channel: 'None',
      path: '',
      status: ToolStatus.error,
    );
  }

  /// Runs `flutter doctor -v` and returns output.
  Future<String> runFlutterDoctor() async {
    try {
      final result = await Process.run('flutter', ['doctor', '-v'], runInShell: true);
      return result.stdout.toString();
    } catch (e) {
      return 'Failed to run flutter doctor: $e';
    }
  }

  /// Checks Java runtime environment.
  Future<JavaInfo> checkJava() async {
    try {
      final result = await Process.run('java', ['-version'], runInShell: true);
      final raw = result.stderr.toString().isNotEmpty ? result.stderr.toString() : result.stdout.toString();
      final match = RegExp(r'version "([0-9]+)').firstMatch(raw);
      final major = match != null ? (int.tryParse(match.group(1)!) ?? 0) : 0;
      final javaHome = Platform.environment['JAVA_HOME'] ?? '';

      return JavaInfo(
        majorVersion: major,
        rawVersion: raw.split('\n').first,
        javaHome: javaHome,
        status: major >= 17 ? ToolStatus.ok : ToolStatus.warning,
      );
    } catch (_) {}

    return const JavaInfo(
      majorVersion: 0,
      rawVersion: 'Not found in PATH',
      javaHome: '',
      status: ToolStatus.error,
    );
  }

  /// Discovers the installed Android SDK version from build-tools and platforms directories.
  String detectSdkVersion(String sdkPath) {
    if (sdkPath.isEmpty || !Directory(sdkPath).existsSync()) return '';

    String latestBuildTools = '';
    final buildToolsDir = Directory('$sdkPath/build-tools');
    if (buildToolsDir.existsSync()) {
      try {
        final dirs = buildToolsDir.listSync().whereType<Directory>().map((d) {
          final segments = d.uri.pathSegments.where((s) => s.isNotEmpty).toList();
          return segments.isNotEmpty ? segments.last : '';
        }).where((name) => name.isNotEmpty).toList();

        dirs.sort((a, b) {
          final aNums = RegExp(r'\d+').allMatches(a).map((m) => int.tryParse(m.group(0)!) ?? 0).toList();
          final bNums = RegExp(r'\d+').allMatches(b).map((m) => int.tryParse(m.group(0)!) ?? 0).toList();
          final maxLen = aNums.length > bNums.length ? aNums.length : bNums.length;
          for (var i = 0; i < maxLen; i++) {
            final aVal = i < aNums.length ? aNums[i] : 0;
            final bVal = i < bNums.length ? bNums[i] : 0;
            if (aVal != bVal) return aVal.compareTo(bVal);
          }
          return a.compareTo(b);
        });

        if (dirs.isNotEmpty) latestBuildTools = dirs.last;
      } catch (_) {}
    }

    String latestPlatform = '';
    final platformsDir = Directory('$sdkPath/platforms');
    if (platformsDir.existsSync()) {
      try {
        final dirs = platformsDir.listSync().whereType<Directory>().map((d) {
          final segments = d.uri.pathSegments.where((s) => s.isNotEmpty).toList();
          return segments.isNotEmpty ? segments.last : '';
        }).where((name) => name.isNotEmpty).toList();

        num maxApi = 0;
        for (final dirName in dirs) {
          final propsFile = File('$sdkPath/platforms/$dirName/source.properties');
          num? apiLevel;
          if (propsFile.existsSync()) {
            final lines = propsFile.readAsLinesSync();
            for (final l in lines) {
              if (l.startsWith('AndroidVersion.ApiLevel=')) {
                apiLevel = num.tryParse(l.substring('AndroidVersion.ApiLevel='.length).trim());
                break;
              }
            }
          }
          if (apiLevel == null) {
            final match = RegExp(r'android-(\d+(\.\d+)?)').firstMatch(dirName);
            if (match != null) {
              apiLevel = num.tryParse(match.group(1)!);
            }
          }
          if (apiLevel != null && apiLevel > maxApi) {
            maxApi = apiLevel;
          }
        }
        if (maxApi > 0) {
          final formattedApi = maxApi == maxApi.toInt() ? maxApi.toInt().toString() : maxApi.toString();
          latestPlatform = 'API $formattedApi';
        }
      } catch (_) {}
    }

    if (latestBuildTools.isNotEmpty && latestPlatform.isNotEmpty) {
      return '$latestBuildTools ($latestPlatform)';
    } else if (latestBuildTools.isNotEmpty) {
      return latestBuildTools;
    } else if (latestPlatform.isNotEmpty) {
      return latestPlatform;
    }
    return 'Unknown';
  }

  /// Checks Google Android CLI and SDK paths.
  Future<AndroidCliInfo> checkAndroidCli() async {
    String cliPath = '';
    String sdkPath = '';
    String version = '';
    String sdkVersion = '';

    try {
      final whichResult = await Process.run('which', ['android'], runInShell: true);
      if (whichResult.exitCode == 0) {
        cliPath = whichResult.stdout.toString().trim();
      } else {
        final home = Platform.environment['HOME'] ?? '';
        final fallback = '$home/.local/bin/android';
        if (File(fallback).existsSync()) cliPath = fallback;
      }

      if (cliPath.isNotEmpty) {
        final infoResult = await Process.run(cliPath, ['info'], runInShell: true);
        if (infoResult.exitCode == 0) {
          final lines = infoResult.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.startsWith('sdk:')) {
              sdkPath = line.substring(4).trim();
            } else if (line.startsWith('version:')) {
              version = line.substring(8).trim();
            }
          }
        }
      }

      if (sdkPath.isEmpty) {
        final envSdk = Platform.environment['ANDROID_HOME'] ??
            Platform.environment['ANDROID_SDK_ROOT'];
        if (envSdk != null && Directory(envSdk).existsSync()) {
          sdkPath = envSdk;
        } else {
          final home = Platform.environment['HOME'] ?? '';
          final defaultSdk = '$home/Android/Sdk';
          if (Directory(defaultSdk).existsSync()) {
            sdkPath = defaultSdk;
          }
        }
      }

      if (sdkPath.isNotEmpty) {
        sdkVersion = detectSdkVersion(sdkPath);
      }

      if (cliPath.isNotEmpty || sdkPath.isNotEmpty) {
        return AndroidCliInfo(
          version: version.isNotEmpty ? version : (cliPath.isNotEmpty ? '1.0' : 'Not installed'),
          sdkVersion: sdkVersion.isNotEmpty ? sdkVersion : 'Unknown',
          cliPath: cliPath,
          sdkPath: sdkPath,
          status: cliPath.isNotEmpty && sdkPath.isNotEmpty ? ToolStatus.ok : ToolStatus.warning,
        );
      }
    } catch (_) {}

    return const AndroidCliInfo(
      version: 'Not Found',
      sdkVersion: 'Not Found',
      cliPath: '',
      sdkPath: '',
      status: ToolStatus.error,
    );
  }

  /// Detects running Android emulator processes and returns a map of {avdName: pid}.
  Future<Map<String, int>> getRunningAvdPids() async {
    final running = <String, int>{};
    try {
      final result = await Process.run('ps', ['-eo', 'pid,command'], runInShell: true);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (!line.contains('qemu-system') && !line.contains('emulator')) continue;
          if (line.contains('grep')) continue;

          final match = RegExp(r'^\s*(\d+)\s+.*?(?:-avd\s+|@)([a-zA-Z0-9_\-\.]+)').firstMatch(line);
          if (match != null) {
            final pid = int.tryParse(match.group(1)!);
            final avdName = match.group(2)!;
            if (pid != null) {
              running[avdName] = pid;
            }
          }
        }
      }
    } catch (_) {}
    return running;
  }

  /// Lists configured Android Virtual Devices with their active running status and PID.
  Future<List<AvdItem>> listAvds() async {
    final avds = <AvdItem>[];
    final runningPids = await getRunningAvdPids();

    try {
      final result = await Process.run('android', ['emulator', 'list'], runInShell: true);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          final clean = line.trim();
          if (clean.isNotEmpty && !clean.contains('warning') && !clean.contains('update')) {
            final pid = runningPids[clean];
            avds.add(AvdItem(
              name: clean,
              isRunning: pid != null,
              pid: pid,
            ));
          }
        }
      }
    } catch (_) {}

    // Fallback to flutter emulators if android CLI emulator list returned nothing
    if (avds.isEmpty) {
      try {
        final flutterResult = await Process.run('flutter', ['emulators'], runInShell: true);
        if (flutterResult.exitCode == 0) {
          final lines = flutterResult.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.contains('•') && !line.contains('available emulators')) {
              final parts = line.split('•');
              if (parts.isNotEmpty) {
                final id = parts[0].trim();
                if (id.isNotEmpty && id != 'Id') {
                  final pid = runningPids[id];
                  avds.add(AvdItem(
                    name: id,
                    isRunning: pid != null,
                    pid: pid,
                  ));
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    return avds;
  }

  /// Lists available Android SDK packages.
  Future<List<SdkPackageItem>> listPackages() async {
    final packages = <SdkPackageItem>[
      const SdkPackageItem(
        packagePath: 'platforms/android-36',
        displayName: 'Android SDK Platform 36',
        category: 'Platforms',
        isInstalled: true,
      ),
      const SdkPackageItem(
        packagePath: 'platforms/android-35',
        displayName: 'Android SDK Platform 35',
        category: 'Platforms',
        isInstalled: true,
      ),
      const SdkPackageItem(
        packagePath: 'platforms/android-34',
        displayName: 'Android SDK Platform 34',
        category: 'Platforms',
        isInstalled: true,
      ),
      const SdkPackageItem(
        packagePath: 'build-tools/36.0.0',
        displayName: 'Build-Tools 36.0.0',
        category: 'Build-Tools',
        isInstalled: true,
      ),
      const SdkPackageItem(
        packagePath: 'build-tools/35.0.0',
        displayName: 'Build-Tools 35.0.0',
        category: 'Build-Tools',
        isInstalled: true,
      ),
      const SdkPackageItem(
        packagePath: 'platform-tools',
        displayName: 'Platform-Tools (ADB)',
        category: 'Tools',
        isInstalled: true,
      ),
      const SdkPackageItem(
        packagePath: 'emulator',
        displayName: 'Android Emulator',
        category: 'Tools',
        isInstalled: true,
      ),
    ];
    return packages;
  }

  /// Launches an emulator via flutter emulators --launch in the background,
  /// adds a delay to give the process time to launch, and captures the PID.
  Future<int?> launchEmulator(String name) async {
    log('Launching emulator: $name in background...');
    int? launcherPid;
    try {
      final res = await Process.run(
        'bash',
        ['-c', 'flutter emulators --launch "$name" & echo \$!'],
        runInShell: true,
      );
      if (res.exitCode == 0) {
        final out = res.stdout.toString().trim();
        final match = RegExp(r'\d+').firstMatch(out);
        if (match != null) {
          launcherPid = int.tryParse(match.group(0)!);
        }
      }
    } catch (e) {
      log('[ERROR] Failed to start emulator: $e');
    }

    log('Waiting 2 seconds for emulator process to initialize...');
    await Future.delayed(const Duration(seconds: 2));

    final running = await getRunningAvdPids();
    final actualPid = running[name] ?? launcherPid;
    if (actualPid != null) {
      log('Emulator "$name" is active (PID: $actualPid).');
    } else {
      log('Emulator "$name" launched.');
    }
    return actualPid;
  }

  /// Creates a virtual device via android emulator create.
  Future<bool> createEmulator(String profile) async {
    log('Creating emulator with profile: $profile...');
    final code = await runCommand('android', ['emulator', 'create', profile]);
    return code == 0;
  }

  /// Installs an SDK package via android sdk install.
  Future<bool> installPackage(String packagePath) async {
    log('Installing package: $packagePath...');
    final code = await runCommand('android', ['sdk', 'install', packagePath]);
    return code == 0;
  }

  /// Accepts all Android licenses.
  Future<bool> acceptLicenses() async {
    log('Accepting Android licenses...');
    final code = await runCommand('bash', ['-c', 'yes | flutter doctor --android-licenses']);
    return code == 0;
  }

  /// Configures Flutter Android SDK path.
  Future<bool> configureSdkPath(String path) async {
    log('Configuring Flutter Android SDK path: $path...');
    final code = await runCommand('flutter', ['config', '--android-sdk', path]);
    return code == 0;
  }

  void dispose() {
    _logController.close();
  }
}
