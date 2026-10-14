import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal/data/settings.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('journal_settings_');
    file = File('${dir.path}/sub/settings.json');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('starts unconfigured when no file exists', () async {
    final s = Settings(file);
    await s.load();
    expect(s.isConfigured, isFalse);
    expect(s.sensorKitId, isNull);
  });

  test(
    'setSensorKitId persists across instances and creates folders',
    () async {
      final s = Settings(file);
      await s.setSensorKitId('sa-sa-sk-12');
      expect(s.sensorKitId, 'sa-sa-sk-12');

      final again = Settings(file);
      await again.load();
      expect(again.sensorKitId, 'sa-sa-sk-12');
      expect(again.isConfigured, isTrue);
    },
  );

  test('the id can be changed later', () async {
    final s = Settings(file);
    await s.setSensorKitId('sa-sa-sk-1');
    await s.setSensorKitId('sa-sa-sk-2');
    final again = Settings(file);
    await again.load();
    expect(again.sensorKitId, 'sa-sa-sk-2');
  });

  test('rejects ids outside sa-sa-sk-1 to sa-sa-sk-12', () async {
    final s = Settings(file);
    expect(() => s.setSensorKitId('sa-sa-sk-13'), throwsArgumentError);
    expect(() => s.setSensorKitId(''), throwsArgumentError);
    expect(s.isConfigured, isFalse);
  });

  test('a corrupt or invalid file means unconfigured', () async {
    await file.parent.create(recursive: true);
    await file.writeAsString('{{{');
    final s = Settings(file);
    await s.load();
    expect(s.isConfigured, isFalse);

    await file.writeAsString('{"sensorKitId": "bogus"}');
    await s.load();
    expect(s.isConfigured, isFalse);
  });

  test('notifies listeners when the id changes', () async {
    final s = Settings(file);
    var calls = 0;
    s.addListener(() => calls++);
    await s.setSensorKitId('sa-sa-sk-5');
    expect(calls, 1);
  });
}
