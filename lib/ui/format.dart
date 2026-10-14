const _weekdays = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

const _months = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// `14.10.2026`
String formatDate(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.day)}.${_two(l.month)}.${l.year}';
}

/// `14:05`
String formatTime(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

/// `Mittwoch, 14. Oktober 2026`
String formatDayHeading(DateTime t) {
  final l = t.toLocal();
  final weekday = _weekdays[l.weekday - 1];
  return '$weekday, ${l.day}. ${_months[l.month - 1]} ${l.year}';
}
