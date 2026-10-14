import 'package:flutter_test/flutter_test.dart';
import 'package:journal/data/entry_query.dart';
import 'package:journal/models/entry.dart';

// Built from local times so the tests do not depend on the machine's zone.
Entry at(String id, DateTime local, String text) => Entry(
      id: id,
      created: local.toUtc(),
      sensorKitId: 'sa-sa-sk-1',
      text: text,
    );

void main() {
  final kaffee = at('1', DateTime(2025, 3, 10, 8, 15), 'Kaffee gekocht');
  final regen = at('2', DateTime(2025, 3, 10, 23, 59), 'Es regnet');
  final fenster = at('3', DateTime(2025, 3, 12, 0, 0), 'Fenster geöffnet');
  final all = [fenster, regen, kaffee];

  group('EntryQuery.text', () {
    test('matches case-insensitively on substrings', () {
      expect(const EntryQuery(text: 'KAFFEE').apply(all), [kaffee]);
      expect(const EntryQuery(text: 'ffn').apply(all), [fenster]);
    });

    test('ignores surrounding whitespace', () {
      expect(const EntryQuery(text: '  regnet ').apply(all), [regen]);
    });

    test('blank text matches everything', () {
      expect(const EntryQuery(text: '   ').apply(all), all);
      expect(const EntryQuery().isEmpty, isTrue);
    });

    test('handles umlauts', () {
      expect(const EntryQuery(text: 'GEÖFFNET').apply(all), [fenster]);
    });

    test('returns nothing when nothing matches', () {
      expect(const EntryQuery(text: 'xyz').apply(all), isEmpty);
    });
  });

  group('EntryQuery date range', () {
    test('from is inclusive and ignores time of day', () {
      final q = EntryQuery(from: DateTime(2025, 3, 10, 23, 0));
      expect(q.apply(all), all);
      expect(EntryQuery(from: DateTime(2025, 3, 11)).apply(all), [fenster]);
    });

    test('to is inclusive through the end of that day', () {
      final q = EntryQuery(to: DateTime(2025, 3, 10, 1, 0));
      expect(q.apply(all), [regen, kaffee]);
      expect(EntryQuery(to: DateTime(2025, 3, 9)).apply(all), isEmpty);
    });

    test('from and to combine with text', () {
      final q = EntryQuery(
        text: 'e',
        from: DateTime(2025, 3, 10),
        to: DateTime(2025, 3, 10),
      );
      expect(q.apply(all), [regen, kaffee]);
      expect(q.isEmpty, isFalse);
    });
  });

  group('groupByDay', () {
    test('groups by local day and keeps order', () {
      final groups = groupByDay(all);
      expect(groups.keys, [DateTime(2025, 3, 12), DateTime(2025, 3, 10)]);
      expect(groups[DateTime(2025, 3, 10)], [regen, kaffee]);
    });

    test('is empty for no entries', () {
      expect(groupByDay(const []), isEmpty);
    });
  });
}
