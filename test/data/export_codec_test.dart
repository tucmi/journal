import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal/data/export_codec.dart';
import 'package:journal/models/entry.dart';

void main() {
  final a = Entry(
    id: 'sa-sa-sk-3-000001',
    created: DateTime.utc(2025, 1, 1, 10),
    sensorKitId: 'sa-sa-sk-3',
    text: 'Eins',
  );
  final b = Entry(
    id: 'sa-sa-sk-3-000002',
    created: DateTime.utc(2025, 1, 1, 11),
    sensorKitId: 'sa-sa-sk-3',
    text: 'Zwei "mit" Umlaut ä\nund Zeilenumbruch',
  );

  group('encodeExport', () {
    test('produces a JSON array of annotations', () {
      final decoded = jsonDecode(encodeExport([a, b])) as List<dynamic>;
      expect(decoded, hasLength(2));
      expect((decoded.first as Map)['id'], a.id);
      expect((decoded.first as Map)['login'], 'sa-sa-sk-3');
    });

    test('encodes no entries as an empty array', () {
      expect(jsonDecode(encodeExport(const [])), isEmpty);
    });
  });

  group('decodeExport', () {
    test('round-trips entries including special characters', () {
      expect(decodeExport(encodeExport([a, b])), [a, b]);
    });

    test('reads a Grafana annotations file with integer ids', () {
      final source = jsonEncode([
        {
          'id': 43,
          'alertId': 0,
          'created': 1737966649640,
          'updated': 1737967288146,
          'time': 1737361838180,
          'timeEnd': 1737966638181,
          'text': 'Aufgabe 10',
          'tags': ['Messgröße: Mehrere'],
          'login': 'sa-sa-sk-1',
          'email': 'sa-sa-sk-1',
          'data': {},
        }
      ]);
      final entries = decodeExport(source);
      expect(entries.single.id, '43');
      expect(entries.single.text, 'Aufgabe 10');
      expect(entries.single.created.millisecondsSinceEpoch, 1737966649640);
    });

    test('rejects text that is not JSON', () {
      expect(() => decodeExport('hello'), throwsFormatException);
    });

    test('rejects JSON that is not an array', () {
      expect(() => decodeExport('{"id": 1}'), throwsFormatException);
    });

    test('rejects an array containing a non-object', () {
      expect(() => decodeExport('[1, 2]'), throwsFormatException);
    });

    test('rejects fields of the wrong type', () {
      expect(
        () => decodeExport('[{"id": "a", "created": "x", "login": "l"}]'),
        throwsFormatException,
      );
    });

    test('rejects the whole file if one entry is invalid', () {
      final source = jsonEncode([a.toJson(), {'text': 'no id'}]);
      expect(() => decodeExport(source), throwsFormatException);
    });
  });

  test('exportFileName embeds the SensorKit id and a sortable timestamp', () {
    final name = exportFileName('sa-sa-sk-1', DateTime(2025, 10, 4, 9, 5, 7));
    expect(name, 'journal_sa-sa-sk-1_20251004_090507.json');
  });
}
