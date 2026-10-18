import 'package:flutter/material.dart';
import 'services/system_service.dart';
import 'state/app_signals.dart';
import 'ui/studio_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final systemService = SystemService();
  final appSignals = AppSignals(systemService: systemService);

  // Trigger initial environment discovery
  appSignals.refreshEnvironment();

  runApp(AndroidSdkStudioApp(appSignals: appSignals));
}

class AndroidSdkStudioApp extends StatefulWidget {
  final AppSignals appSignals;

  const AndroidSdkStudioApp({super.key, required this.appSignals});

  @override
  State<AndroidSdkStudioApp> createState() => _AndroidSdkStudioAppState();
}

class _AndroidSdkStudioAppState extends State<AndroidSdkStudioApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter & Android SDK Studio',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF13151B),
      ),
      home: StudioShell(
        appSignals: widget.appSignals,
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
