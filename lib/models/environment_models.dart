enum ToolStatus {
  ok,
  warning,
  error,
  loading,
}

class FlutterInfo {
  final String version;
  final String channel;
  final String path;
  final ToolStatus status;
  final String? rawDoctor;

  const FlutterInfo({
    this.version = 'Checking...',
    this.channel = 'Unknown',
    this.path = '',
    this.status = ToolStatus.loading,
    this.rawDoctor,
  });

  FlutterInfo copyWith({
    String? version,
    String? channel,
    String? path,
    ToolStatus? status,
    String? rawDoctor,
  }) {
    return FlutterInfo(
      version: version ?? this.version,
      channel: channel ?? this.channel,
      path: path ?? this.path,
      status: status ?? this.status,
      rawDoctor: rawDoctor ?? this.rawDoctor,
    );
  }
}

class JavaInfo {
  final int majorVersion;
  final String rawVersion;
  final String javaHome;
  final ToolStatus status;

  const JavaInfo({
    this.majorVersion = 0,
    this.rawVersion = 'Checking...',
    this.javaHome = '',
    this.status = ToolStatus.loading,
  });

  bool get isCompatible => majorVersion >= 17;

  JavaInfo copyWith({
    int? majorVersion,
    String? rawVersion,
    String? javaHome,
    ToolStatus? status,
  }) {
    return JavaInfo(
      majorVersion: majorVersion ?? this.majorVersion,
      rawVersion: rawVersion ?? this.rawVersion,
      javaHome: javaHome ?? this.javaHome,
      status: status ?? this.status,
    );
  }
}

class AndroidCliInfo {
  final String version;
  final String sdkVersion;
  final String cliPath;
  final String sdkPath;
  final ToolStatus status;
  final bool licensesAccepted;

  const AndroidCliInfo({
    this.version = 'Checking...',
    this.sdkVersion = 'Checking...',
    this.cliPath = '',
    this.sdkPath = '',
    this.status = ToolStatus.loading,
    this.licensesAccepted = true,
  });

  AndroidCliInfo copyWith({
    String? version,
    String? sdkVersion,
    String? cliPath,
    String? sdkPath,
    ToolStatus? status,
    bool? licensesAccepted,
  }) {
    return AndroidCliInfo(
      version: version ?? this.version,
      sdkVersion: sdkVersion ?? this.sdkVersion,
      cliPath: cliPath ?? this.cliPath,
      sdkPath: sdkPath ?? this.sdkPath,
      status: status ?? this.status,
      licensesAccepted: licensesAccepted ?? this.licensesAccepted,
    );
  }
}

class AvdItem {
  final String name;
  final String profile;
  final String apiLevel;
  final bool isRunning;
  final int? pid;

  const AvdItem({
    required this.name,
    this.profile = 'medium_phone',
    this.apiLevel = '35',
    this.isRunning = false,
    this.pid,
  });

  AvdItem copyWith({
    String? name,
    String? profile,
    String? apiLevel,
    bool? isRunning,
    int? pid,
  }) {
    return AvdItem(
      name: name ?? this.name,
      profile: profile ?? this.profile,
      apiLevel: apiLevel ?? this.apiLevel,
      isRunning: isRunning ?? this.isRunning,
      pid: pid ?? this.pid,
    );
  }
}

class SdkPackageItem {
  final String packagePath;
  final String displayName;
  final String category;
  final bool isInstalled;

  const SdkPackageItem({
    required this.packagePath,
    required this.displayName,
    required this.category,
    this.isInstalled = false,
  });
}
