import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal/data/entry_repository.dart';
import 'package:journal/data/settings.dart';
import 'package:journal/main.dart';
import 'package:journal/models/entry.dart';

void main() {
  late Directory dir;
  late EntryRepository repo;
  late Settings settings;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('journal_ui_');
    repo = EntryRepository(File('${dir.path}/entries.json'));
    settings = Settings(File('${dir.path}/settings.json'));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    JournalApp(
      repository: repo,
      settings: settings,
      speech: const UnavailableSpeechService(),
    ),
  );

  Entry entry(String text, DateTime local) =>
      Entry.create(sensorKitId: 'sa-sa-sk-1', text: text, created: local);

  testWidgets('first launch shows the id picker, then the list', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('SensorKit wählen'), findsOneWidget);
    expect(find.text('sa-sa-sk-1'), findsOneWidget);

    await tester.runAsync(() async {
      await settings.setSensorKitId('sa-sa-sk-3');
    });
    await tester.pumpAndSettle();
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Noch keine Einträge.'), findsOneWidget);
  });

  testWidgets('entries are grouped by day and searchable', (tester) async {
    await tester.runAsync(() async {
      await settings.setSensorKitId('sa-sa-sk-1');
      await repo.addAll([
        entry('Kaffee gekocht', DateTime(2026, 10, 14, 9, 5)),
        entry('Spaziergang im Park', DateTime(2026, 10, 14, 17, 30)),
        entry('Zug verpasst', DateTime(2026, 10, 13, 8, 0)),
      ]);
    });
    await pump(tester);

    expect(find.text('Mittwoch, 14. Oktober 2026'), findsOneWidget);
    expect(find.text('Dienstag, 13. Oktober 2026'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);

    await tester.tap(find.byTooltip('Suchen'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'park');
    await tester.pump();
    expect(find.text('Spaziergang im Park'), findsOneWidget);
    expect(find.text('Kaffee gekocht'), findsNothing);
    expect(find.text('Dienstag, 13. Oktober 2026'), findsNothing);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('Keine Treffer.'), findsOneWidget);
  });

  testWidgets('editing an entry saves the new text', (tester) async {
    late Entry original;
    await tester.runAsync(() async {
      await settings.setSensorKitId('sa-sa-sk-1');
      original = entry('Kaffe gekocht', DateTime(2026, 10, 14, 9, 5));
      await repo.add(original);
    });
    await pump(tester);

    await tester.tap(find.text('Kaffe gekocht'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Kaffee gekocht');
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Speichern'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(repo.byId(original.id)!.text, 'Kaffee gekocht');
    expect(find.text('Kaffee gekocht'), findsOneWidget);
  });

  testWidgets('deleting an entry asks first and then removes it', (
    tester,
  ) async {
    late Entry original;
    await tester.runAsync(() async {
      await settings.setSensorKitId('sa-sa-sk-1');
      original = entry('Weg damit', DateTime(2026, 10, 14, 9, 5));
      await repo.add(original);
    });
    await pump(tester);

    await tester.tap(find.text('Weg damit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Eintrag löschen?'), findsOneWidget);
    await tester.tap(find.text('Löschen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // The delete started in the fake-async zone, so real file IO and
    // microtask flushing (pump) have to take turns.
    for (var i = 0; i < 50 && repo.entries.isNotEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(repo.entries, isEmpty);
    expect(find.text('Noch keine Einträge.'), findsOneWidget);
  });

  testWidgets('record button reports an unavailable recognizer', (
    tester,
  ) async {
    await tester.runAsync(() => settings.setSensorKitId('sa-sa-sk-1'));
    await pump(tester);

    await tester.tap(find.byTooltip('Aufnehmen'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Spracherkennung nicht verfügbar oder Mikrofon nicht erlaubt.'),
      findsOneWidget,
    );
  });
}
