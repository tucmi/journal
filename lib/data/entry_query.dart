import '../models/entry.dart';

/// Filters entries by text and by a date range. All fields are optional.
class EntryQuery {
  const EntryQuery({this.text = '', this.from, this.to});

  /// Case-insensitive substring match on the transcript. Blank matches all.
  final String text;

  /// First local day to include (time of day is ignored).
  final DateTime? from;

  /// Last local day to include (time of day is ignored).
  final DateTime? to;

  bool get isEmpty => text.trim().isEmpty && from == null && to == null;

  bool matches(Entry entry) {
    final needle = text.trim().toLowerCase();
    if (needle.isNotEmpty && !entry.text.toLowerCase().contains(needle)) {
      return false;
    }
    final day = dayOf(entry.created);
    if (from != null && day.isBefore(dayOf(from!))) return false;
    if (to != null && day.isAfter(dayOf(to!))) return false;
    return true;
  }

  List<Entry> apply(Iterable<Entry> entries) => entries.where(matches).toList();
}

/// Midnight of the local day containing [t].
DateTime dayOf(DateTime t) {
  final local = t.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Groups [entries] by local day, keeping their order. Days appear in the
/// order of their first entry, so newest-first input gives newest-first days.
Map<DateTime, List<Entry>> groupByDay(Iterable<Entry> entries) {
  final groups = <DateTime, List<Entry>>{};
  for (final e in entries) {
    groups.putIfAbsent(dayOf(e.created), () => []).add(e);
  }
  return groups;
}
