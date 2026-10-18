import 'package:signals_flutter/signals_flutter.dart';
import '../models/environment_models.dart';
import '../services/system_service.dart';

class AppSignals {
  final SystemService systemService;

  AppSignals({required this.systemService}) {
    systemService.logStream.listen((line) {
      consoleLogs.value = [...consoleLogs.value, line];
    });
  }

  // Active navigation tab (0: Dashboard, 1: Packages, 2: Emulators, 3: Doctor)
  final activeTab = signal<int>(0);

  // Environment signals
  final flutterInfo = signal<FlutterInfo>(const FlutterInfo());
  final javaInfo = signal<JavaInfo>(const JavaInfo());
  final androidCliInfo = signal<AndroidCliInfo>(const AndroidCliInfo());

  // Lists
  final avdsList = signal<List<AvdItem>>([]);
  final packagesList = signal<List<SdkPackageItem>>([]);

  // Process and UI state
  final isBusy = signal<bool>(false);
  final busyMessage = signal<String>('');
  final isConsoleExpanded = signal<bool>(false);
  final consoleLogs = signal<List<String>>([]);
  final doctorOutput = signal<String>('Click "Run Diagnostic" to inspect environment.');

  // Computed signals
  late final isAllHealthy = computed(() =>
      flutterInfo.value.status == ToolStatus.ok &&
      javaInfo.value.status == ToolStatus.ok &&
      androidCliInfo.value.status == ToolStatus.ok);

  Future<void> refreshEnvironment() async {
    isBusy.value = true;
    busyMessage.value = 'Inspecting environment...';

    flutterInfo.value = await systemService.checkFlutter();
    javaInfo.value = await systemService.checkJava();
    androidCliInfo.value = await systemService.checkAndroidCli();
    avdsList.value = await systemService.listAvds();
    packagesList.value = await systemService.listPackages();

    isBusy.value = false;
  }

  Future<void> runDoctor() async {
    isBusy.value = true;
    busyMessage.value = 'Running flutter doctor...';
    doctorOutput.value = 'Running flutter doctor -v...\n';

    final result = await systemService.runFlutterDoctor();
    doctorOutput.value = result;

    await refreshEnvironment();
    isBusy.value = false;
  }

  Future<void> launchAvd(String avdName) async {
    isBusy.value = true;
    busyMessage.value = 'Launching $avdName...';
    try {
      await systemService.launchEmulator(avdName);
      avdsList.value = await systemService.listAvds();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> createAvd(String profile) async {
    isBusy.value = true;
    busyMessage.value = 'Creating virtual device ($profile)...';
    await systemService.createEmulator(profile);
    avdsList.value = await systemService.listAvds();
    isBusy.value = false;
  }

  Future<void> installPackage(String packagePath) async {
    isBusy.value = true;
    busyMessage.value = 'Installing $packagePath...';
    await systemService.installPackage(packagePath);
    packagesList.value = await systemService.listPackages();
    isBusy.value = false;
  }

  Future<void> acceptLicenses() async {
    isBusy.value = true;
    busyMessage.value = 'Accepting Android licenses...';
    await systemService.acceptLicenses();
    await refreshEnvironment();
    isBusy.value = false;
  }

  Future<void> relinkSdk(String path) async {
    isBusy.value = true;
    busyMessage.value = 'Re-linking Android SDK path...';
    await systemService.configureSdkPath(path);
    await refreshEnvironment();
    isBusy.value = false;
  }

  void clearLogs() {
    consoleLogs.value = [];
  }
}
