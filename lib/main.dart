import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'data/entry_repository.dart';
import 'data/settings.dart';
import 'recording/recording_controller.dart';
import 'recording/speech_service.dart';
import 'ui/entry_list_screen.dart';
import 'ui/id_picker_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final repository = EntryRepository(File('${dir.path}/entries.json'));
  final settings = Settings(File('${dir.path}/settings.json'));
  await Future.wait([repository.load(), settings.load()]);
  runApp(
    JournalApp(
      repository: repository,
      settings: settings,
      // TODO: replace with the speech_to_text implementation.
      speech: const UnavailableSpeechService(),
    ),
  );
}

/// Placeholder until a real recognizer is wired in: recording reports
/// "unavailable".
class UnavailableSpeechService implements SpeechService {
  const UnavailableSpeechService();

  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> start({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String message) onError,
  }) async {}

  @override
  Future<void> stop() async {}
}

class JournalApp extends StatefulWidget {
  const JournalApp({
    super.key,
    required this.repository,
    required this.settings,
    required this.speech,
  });

  final EntryRepository repository;
  final Settings settings;
  final SpeechService speech;

  @override
  State<JournalApp> createState() => _JournalAppState();
}

class _JournalAppState extends State<JournalApp> {
  late final RecordingController _recorder = RecordingController(
    speech: widget.speech,
    repository: widget.repository,
    settings: widget.settings,
  );

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => widget.settings.isConfigured
            ? EntryListScreen(
                repository: widget.repository,
                settings: widget.settings,
                recorder: _recorder,
              )
            : IdPickerScreen(settings: widget.settings),
      ),
    );
  }
}
