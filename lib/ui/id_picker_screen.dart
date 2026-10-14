import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../models/entry.dart';

/// Shown on first launch (and from the list's menu) to choose the SensorKit id.
class IdPickerScreen extends StatelessWidget {
  const IdPickerScreen({super.key, required this.settings, this.onDone});

  final Settings settings;

  /// Called after an id was saved, e.g. to close the screen when it was pushed.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SensorKit wählen')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Welches SensorKit gehört zu diesem Gerät? Die Auswahl wird '
                'in jedem Eintrag mit exportiert.',
              ),
            ),
            for (final id in sensorKitIds)
              ListTile(
                title: Text(id),
                trailing: id == settings.sensorKitId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () async {
                  await settings.setSensorKitId(id);
                  onDone?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}
