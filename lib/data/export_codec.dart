import 'dart:convert';

import '../models/entry.dart';

/// Suggested file name for an export made at [now], e.g.
/// `journal_sa-sa-sk-1_20251014_093102.json`.
String exportFileName(String sensorKitId, DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  final t = now.toLocal();
  return 'journal_${sensorKitId}_${t.year}${two(t.month)}${two(t.day)}'
      '_${two(t.hour)}${two(t.minute)}${two(t.second)}.json';
}

/// Encodes [entries] as a JSON array of Grafana annotations.
String encodeExport(Iterable<Entry> entries) => const JsonEncoder.withIndent(
      '  ',
    ).convert([for (final e in entries) e.toJson()]);

/// Parses an export (or a SensorKit annotations file). Throws a
/// [FormatException] if [source] is not a JSON array of valid entries; nothing
/// is returned in that case, so a bad file never imports partially.
List<Entry> decodeExport(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    throw const FormatException('Not valid JSON');
  }
  if (decoded is! List) {
    throw const FormatException('Expected a JSON array of entries');
  }
  try {
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>)
          Entry.fromJson(item)
        else
          throw const FormatException('Array item is not an object'),
    ];
  } on TypeError {
    throw const FormatException('Entry has a field of the wrong type');
  }
}
