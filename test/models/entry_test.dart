import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal/models/entry.dart';

void main() {
  final created = DateTime.utc(2025, 1, 20, 9, 30, 38, 180);
  final entry = Entry(
    id: 'sa-sa-sk-1-3f9c2a',
    created: created,
    sensorKitId: 'sa-sa-sk-1',
    text: 'Gerade kocht der Kaffee',
  );

  group('toJson', () {
    test('exports the four used fields', () {
      final json = entry.toJson();
      expect(json['id'], 'sa-sa-sk-1-3f9c2a');
      expect(json['created'], created.millisecondsSinceEpoch);
      expect(json['login'], 'sa-sa-sk-1');
      expect(json['email'], 'sa-sa-sk-1');
      expect(json['text'], 'Gerade kocht der Kaffee');
    });

    test('exports unused Grafana fields empty', () {
      final json = entry.toJson();
      for (final key in ['alertName', 'dashboardUID', 'newState', 'prevState']) {
        expect(json[key], '');
      }
      for (final key in ['alertId', 'dashboardId', 'panelId', 'userId']) {
        expect(json[key], 0);
      }
      expect(json['time'], 0);
      expect(json['timeEnd'], 0);
      expect(json['tags'], isEmpty);
      expect(json['data'], isEmpty);
    });

    test('survives JSON encoding', () {
      expect(() => jsonEncode(entry.toJson()), returnsNormally);
    });
  });

  group('fromJson', () {
    test('round-trips toJson', () {
      final decoded = jsonDecode(jsonEncode(entry.toJson()));
      expect(Entry.fromJson(decoded as Map<String, dynamic>), entry);
    });

    test('accepts an integer id as in Grafana exports', () {
      final e = Entry.fromJson({
        'id': 43,
        'created': 1737966649640,
        'login': 'sa-sa-sk-1',
        'text': 'x',
      });
      expect(e.id, '43');
      expect(e.created.isUtc, isTrue);
    });

    test('falls back to email when login is missing', () {
      final e = Entry.fromJson(
          {'id': 'a', 'created': 1, 'email': 'sa-sa-sk-2', 'text': ''});
      expect(e.sensorKitId, 'sa-sa-sk-2');
    });

    test('defaults missing text to empty', () {
      final e =
          Entry.fromJson({'id': 'a', 'created': 1, 'login': 'sa-sa-sk-2'});
      expect(e.text, '');
    });

    test('rejects entries without id, created or login', () {
      expect(() => Entry.fromJson({'created': 1, 'login': 'x'}),
          throwsFormatException);
      expect(() => Entry.fromJson({'id': 'a', 'login': 'x'}),
          throwsFormatException);
      expect(() => Entry.fromJson({'id': 'a', 'created': 1}),
          throwsFormatException);
    });
  });

  group('Entry.create', () {
    test('stamps UTC time and prefixes the id with the SensorKit id', () {
      final e = Entry.create(
        sensorKitId: 'sa-sa-sk-7',
        text: 'hi',
        created: DateTime(2025, 1, 1, 12),
        random: Random(1),
      );
      expect(e.created.isUtc, isTrue);
      expect(e.id, startsWith('sa-sa-sk-7-'));
      expect(e.sensorKitId, 'sa-sa-sk-7');
    });

    test('defaults created to now', () {
      final before = DateTime.now().toUtc();
      final e = Entry.create(sensorKitId: 'sa-sa-sk-1', text: '');
      expect(e.created.isBefore(before), isFalse);
    });
  });

  group('generateId', () {
    test('is the SensorKit id plus six hex characters', () {
      expect(generateId('sa-sa-sk-1'), matches(r'^sa-sa-sk-1-[0-9a-f]{6}$'));
    });

    test('pads small random values', () {
      final id = generateId('k', random: _FixedRandom(0xab));
      expect(id, 'k-0000ab');
    });
  });

  test('copyWith changes text and created but keeps id', () {
    final changed = entry.copyWith(text: 'neu', created: DateTime.utc(2025));
    expect(changed.id, entry.id);
    expect(changed.text, 'neu');
    expect(changed.created, DateTime.utc(2025));
    expect(changed, isNot(entry));
  });

  test('sensorKitIds lists sa-sa-sk-1 to sa-sa-sk-12', () {
    expect(sensorKitIds, hasLength(12));
    expect(sensorKitIds.first, 'sa-sa-sk-1');
    expect(sensorKitIds.last, 'sa-sa-sk-12');
  });
}

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;
  @override
  int nextInt(int max) => value;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}
