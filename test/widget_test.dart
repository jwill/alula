import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_sdk_installer/main.dart';
import 'package:android_sdk_installer/models/environment_models.dart';
import 'package:android_sdk_installer/services/system_service.dart';
import 'package:android_sdk_installer/state/app_signals.dart';

void main() {
  testWidgets('AndroidSdkStudioApp renders StudioShell with tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final systemService = SystemService();
    final appSignals = AppSignals(systemService: systemService);

    await tester.pumpWidget(AndroidSdkStudioApp(appSignals: appSignals));
    await tester.pump();

    expect(find.text('Flutter & Android SDK Studio'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Packages'), findsOneWidget);
    expect(find.text('Emulators'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
  });

  testWidgets('Dashboard renders Android SDK version and CLI version on health card', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final systemService = SystemService();
    final appSignals = AppSignals(systemService: systemService);

    appSignals.androidCliInfo.value = const AndroidCliInfo(
      version: '1.0.15985488',
      sdkVersion: '36.1.0 (API 37)',
      sdkPath: '/home/jwill/Android/Sdk',
      status: ToolStatus.ok,
    );

    await tester.pumpWidget(AndroidSdkStudioApp(appSignals: appSignals));
    await tester.pump();

    expect(find.text('Android CLI & SDK'), findsOneWidget);
    expect(find.text('SDK Version: 36.1.0 (API 37)'), findsOneWidget);
    expect(find.text('CLI Version: 1.0.15985488'), findsOneWidget);
    expect(find.text('/home/jwill/Android/Sdk'), findsOneWidget);
  });
}

