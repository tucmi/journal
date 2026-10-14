import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/entry.dart';

/// App settings, stored as a small JSON file. Currently only the SensorKit id
/// chosen on first launch.
class Settings extends ChangeNotifier {
  Settings(this.file);

  final File file;
  String? _sensorKitId;

  /// The chosen SensorKit id, or null before the first-launch pick.
  String? get sensorKitId => _sensorKitId;

  bool get isConfigured => _sensorKitId != null;

  Future<void> load() async {
    _sensorKitId = null;
    if (await file.exists()) {
      try {
        final json = jsonDecode(await file.readAsString());
        final id = json is Map ? json['sensorKitId'] : null;
        if (id is String && sensorKitIds.contains(id)) _sensorKitId = id;
      } on FormatException {
        // Unreadable settings: ask for the id again.
      }
    }
    notifyListeners();
  }

  Future<void> setSensorKitId(String id) async {
    if (!sensorKitIds.contains(id)) {
      throw ArgumentError.value(id, 'id', 'not a SensorKit id');
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'sensorKitId': id}), flush: true);
    _sensorKitId = id;
    notifyListeners();
  }
}
