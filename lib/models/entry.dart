import 'dart:math';

/// A spoken journal entry, exported in the SensorKit Grafana annotation shape.
class Entry {
  const Entry({
    required this.id,
    required this.created,
    required this.sensorKitId,
    required this.text,
  });

  /// Creates an entry stamped [created] with a fresh id for [sensorKitId].
  factory Entry.create({
    required String sensorKitId,
    required String text,
    DateTime? created,
    Random? random,
  }) {
    return Entry(
      id: generateId(sensorKitId, random: random),
      created: (created ?? DateTime.now()).toUtc(),
      sensorKitId: sensorKitId,
      text: text,
    );
  }

  factory Entry.fromJson(Map<String, dynamic> json) {
    final login = json['login'] ?? json['email'];
    if (json['id'] == null || json['created'] == null || login == null) {
      throw const FormatException('Entry needs id, created and login/email');
    }
    return Entry(
      id: json['id'].toString(),
      created: DateTime.fromMillisecondsSinceEpoch(
        (json['created'] as num).toInt(),
        isUtc: true,
      ),
      sensorKitId: login as String,
      text: (json['text'] as String?) ?? '',
    );
  }

  final String id;
  final DateTime created;
  final String sensorKitId;
  final String text;

  /// The full Grafana annotation; fields we do not use are exported empty.
  Map<String, dynamic> toJson() => {
    'id': id,
    'alertId': 0,
    'alertName': '',
    'dashboardId': 0,
    'dashboardUID': '',
    'panelId': 0,
    'userId': 0,
    'newState': '',
    'prevState': '',
    'created': created.millisecondsSinceEpoch,
    'updated': 0,
    'time': 0,
    'timeEnd': 0,
    'text': text,
    'tags': <String>[],
    'login': sensorKitId,
    'email': sensorKitId,
    'avatarUrl': '',
    'data': <String, dynamic>{},
  };

  Entry copyWith({DateTime? created, String? text}) => Entry(
    id: id,
    created: created?.toUtc() ?? this.created,
    sensorKitId: sensorKitId,
    text: text ?? this.text,
  );

  @override
  bool operator ==(Object other) =>
      other is Entry &&
      other.id == id &&
      other.created == created &&
      other.sensorKitId == sensorKitId &&
      other.text == text;

  @override
  int get hashCode => Object.hash(id, created, sensorKitId, text);

  @override
  String toString() => 'Entry($id, $created, $text)';
}

/// Builds `<sensorKitId>-<6 hex chars>`, e.g. `sa-sa-sk-1-3f9c2a`.
String generateId(String sensorKitId, {Random? random}) {
  final r = random ?? Random.secure();
  final suffix = r.nextInt(0x1000000).toRadixString(16).padLeft(6, '0');
  return '$sensorKitId-$suffix';
}

/// The twelve SensorKit ids, `sa-sa-sk-1` to `sa-sa-sk-12`.
final List<String> sensorKitIds = List.unmodifiable([
  for (var i = 1; i <= 12; i++) 'sa-sa-sk-$i',
]);

/// The name shown to users for [sensorKitId]: `sa-sa-sk-1` -> `tucmi-sensorkit-1`.
/// The internal id (used in exports) is unchanged.
String sensorKitDisplayName(String sensorKitId) =>
    'tucmi-sensorkit-${sensorKitId.split('-').last}';
