import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/entry.dart';

/// Holds all entries in memory (newest first) and persists them to [file] as a
/// JSON array of Grafana annotations, the same shape as the export.
class EntryRepository extends ChangeNotifier {
  EntryRepository(this.file);

  final File file;
  List<Entry> _entries = const [];

  /// All entries, newest first.
  List<Entry> get entries => _entries;

  /// Reads [file]. A missing file means no entries; an unreadable one is
  /// moved aside to `<file>.corrupt` so it is not overwritten.
  Future<void> load() async {
    if (!await file.exists()) {
      _entries = const [];
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      _entries = _sorted(
        decoded.map((e) => Entry.fromJson(e as Map<String, dynamic>)),
      );
    } on Object {
      await file.rename('${file.path}.corrupt');
      _entries = const [];
    }
    notifyListeners();
  }

  Entry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> add(Entry entry) async {
    if (byId(entry.id) != null) {
      throw ArgumentError.value(entry.id, 'entry', 'id already exists');
    }
    await _commit([..._entries, entry]);
  }

  /// Replaces the entry with the same id.
  Future<void> update(Entry entry) async {
    if (byId(entry.id) == null) {
      throw ArgumentError.value(entry.id, 'entry', 'no such entry');
    }
    await _commit([for (final e in _entries) e.id == entry.id ? entry : e]);
  }

  /// Returns false if there was no such entry.
  Future<bool> remove(String id) async {
    if (byId(id) == null) return false;
    await _commit(_entries.where((e) => e.id != id));
    return true;
  }

  /// Adds the given entries, skipping ids that already exist. Returns how many
  /// were added.
  Future<int> addAll(Iterable<Entry> incoming) async {
    final known = {for (final e in _entries) e.id};
    final fresh = <Entry>[];
    for (final e in incoming) {
      if (known.add(e.id)) fresh.add(e);
    }
    if (fresh.isNotEmpty) await _commit([..._entries, ...fresh]);
    return fresh.length;
  }

  /// Updates the in-memory list and notifies listeners right away, so the UI
  /// never waits on the disk, then persists. The returned future completes once
  /// the change is on disk (and throws if writing failed).
  Future<void> _commit(Iterable<Entry> next) {
    _entries = _sorted(next);
    notifyListeners();
    return _persist();
  }

  Future<void>? _writer;
  bool _dirty = false;

  /// Writes the latest [_entries]. Writes never overlap, and changes made while
  /// one is running are folded into a single follow-up write of the newest
  /// state, so a burst of edits costs at most two writes.
  Future<void> _persist() {
    _dirty = true;
    return _writer ??= _drain().whenComplete(() => _writer = null);
  }

  Future<void> _drain() async {
    while (_dirty) {
      _dirty = false;
      final snapshot = _entries;
      // Write to a temp file first so a crash cannot truncate the journal.
      final tmp = File('${file.path}.tmp');
      await tmp.parent.create(recursive: true);
      await tmp.writeAsString(
        jsonEncode([for (final e in snapshot) e.toJson()]),
        flush: true,
      );
      await tmp.rename(file.path);
    }
  }

  static List<Entry> _sorted(Iterable<Entry> entries) => List.unmodifiable(
    entries.toList()..sort((a, b) => b.created.compareTo(a.created)),
  );
}
