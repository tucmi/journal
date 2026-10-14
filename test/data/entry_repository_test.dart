import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal/data/entry_repository.dart';
import 'package:journal/models/entry.dart';

Entry entry(String id, int hour, [String text = 't']) => Entry(
      id: id,
      created: DateTime.utc(2025, 1, 1, hour),
      sensorKitId: 'sa-sa-sk-1',
      text: text,
    );

void main() {
  late Directory dir;
  late File file;
  late EntryRepository repo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('journal_repo_');
    file = File('${dir.path}/entries.json');
    repo = EntryRepository(file);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<EntryRepository> reopen() async {
    final r = EntryRepository(file);
    await r.load();
    return r;
  }

  test('load without a file yields no entries', () async {
    await repo.load();
    expect(repo.entries, isEmpty);
  });

  test('add persists and survives a reload', () async {
    await repo.add(entry('a', 10, 'hallo'));
    final reloaded = await reopen();
    expect(reloaded.entries, [entry('a', 10, 'hallo')]);
  });

  test('entries are sorted newest first', () async {
    await repo.add(entry('early', 8));
    await repo.add(entry('late', 20));
    await repo.add(entry('mid', 12));
    expect(repo.entries.map((e) => e.id), ['late', 'mid', 'early']);
    expect((await reopen()).entries.map((e) => e.id), ['late', 'mid', 'early']);
  });

  test('add rejects a duplicate id', () async {
    await repo.add(entry('a', 10));
    expect(() => repo.add(entry('a', 11)), throwsArgumentError);
  });

  test('update replaces text and moves the entry when created changes',
      () async {
    await repo.add(entry('a', 10));
    await repo.add(entry('b', 12));
    await repo.update(entry('a', 14, 'neu'));
    expect(repo.entries.map((e) => e.id), ['a', 'b']);
    expect(repo.byId('a')!.text, 'neu');
    expect((await reopen()).byId('a')!.text, 'neu');
  });

  test('update rejects an unknown id', () async {
    expect(() => repo.update(entry('x', 1)), throwsArgumentError);
  });

  test('remove deletes and reports whether anything was removed', () async {
    await repo.add(entry('a', 10));
    expect(await repo.remove('a'), isTrue);
    expect(await repo.remove('a'), isFalse);
    expect((await reopen()).entries, isEmpty);
  });

  test('addAll skips existing and repeated ids', () async {
    await repo.add(entry('a', 10, 'orig'));
    final added = await repo.addAll([
      entry('a', 10, 'other'),
      entry('b', 11),
      entry('b', 12),
    ]);
    expect(added, 1);
    expect(repo.entries, hasLength(2));
    expect(repo.byId('a')!.text, 'orig');
  });

  test('notifies listeners on changes', () async {
    var calls = 0;
    repo.addListener(() => calls++);
    await repo.add(entry('a', 10));
    await repo.update(entry('a', 10, 'x'));
    await repo.remove('a');
    expect(calls, 3);
  });

  test('stores the file as a JSON array of annotations', () async {
    await repo.add(entry('a', 10));
    final raw = jsonDecode(await file.readAsString()) as List<dynamic>;
    expect(raw, hasLength(1));
    expect((raw.single as Map)['login'], 'sa-sa-sk-1');
    expect((raw.single as Map).containsKey('dashboardUID'), isTrue);
  });

  test('leaves no temp file behind', () async {
    await repo.add(entry('a', 10));
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('a corrupt file is moved aside and the journal starts empty', () async {
    await file.writeAsString('not json');
    await repo.load();
    expect(repo.entries, isEmpty);
    expect(File('${file.path}.corrupt').readAsStringSync(), 'not json');
    await repo.add(entry('a', 10));
    expect((await reopen()).entries, hasLength(1));
  });
}
