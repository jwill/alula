import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_sdk_installer/android_sdk_installer.dart';
import 'package:android_sdk_installer/services/system_service.dart';

void main() {
  group('android_sdk_installer unit tests', () {
    test('getArchitecture returns a valid architecture', () {
      final arch = getArchitecture();
      expect(arch, isIn(['arm64-v8a', 'x86_64']));
    });

    test('getAndroidSystemImage returns expected format', () {
      final image = getAndroidSystemImage('35');
      expect(image, startsWith('system-images/android-35/google_apis/'));
      expect(image, anyOf(endsWith('x86_64'), endsWith('arm64-v8a')));
    });

    test('getAndroidCliPlatformKey returns supported platform', () {
      final key = getAndroidCliPlatformKey();
      expect(key, anyOf([
        'linux_x86_64',
        'linux_arm64',
        'darwin_x86_64',
        'darwin_arm64',
      ]));
    });

    test('SystemService detectSdkVersion resolves highest build-tools and platform API', () {
      final tempDir = Directory.systemTemp.createTempSync('sdk_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      Directory('${tempDir.path}/build-tools/34.0.0').createSync(recursive: true);
      Directory('${tempDir.path}/build-tools/36.1.0').createSync(recursive: true);
      Directory('${tempDir.path}/platforms/android-34').createSync(recursive: true);
      Directory('${tempDir.path}/platforms/android-37.0').createSync(recursive: true);

      final service = SystemService();
      final version = service.detectSdkVersion(tempDir.path);
      expect(version, equals('36.1.0 (API 37)'));
    });
  });
}

