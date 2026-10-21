import 'package:flutter_test/flutter_test.dart';
import 'package:android_sdk_installer/models/environment_models.dart';
import 'package:android_sdk_installer/services/system_service.dart';
import 'package:android_sdk_installer/state/app_signals.dart';

class MockSystemService extends SystemService {
  bool deleteCalled = false;
  String? deletedName;

  @override
  Future<bool> deleteEmulator(String name) async {
    deleteCalled = true;
    deletedName = name;
    return true;
  }

  @override
  Future<List<AvdItem>> listAvds() async {
    return const [AvdItem(name: 'Device2')];
  }
}

void main() {
  test('AppSignals.deleteAvd triggers service call and updates list', () async {
    final mockService = MockSystemService();
    final appSignals = AppSignals(systemService: mockService);

    appSignals.avdsList.value = const [
      AvdItem(name: 'Device1'),
      AvdItem(name: 'Device2'),
    ];

    await appSignals.deleteAvd('Device1');

    expect(mockService.deleteCalled, true);
    expect(mockService.deletedName, 'Device1');
    expect(appSignals.avdsList.value.length, 1);
    expect(appSignals.avdsList.value.first.name, 'Device2');
  });
}
