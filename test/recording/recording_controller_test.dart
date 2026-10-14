import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal/data/entry_repository.dart';
import 'package:journal/data/settings.dart';
import 'package:journal/recording/recording_controller.dart';
import 'package:journal/recording/speech_service.dart';

class FakeSpeech implements SpeechService {
  bool available = true;
  bool started = false;
  String? locale;
  late void Function(String, bool) onResult;
  late void Function(String) onError;

  /// Text delivered as the final result when stop() is called, if any.
  String? finalOnStop;

  @override
  Future<bool> initialize() async => available;

  @override
  Future<void> start({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String message) onError,
  }) async {
    started = true;
    locale = localeId;
    this.onResult = onResult;
    this.onError = onError;
  }

  @override
  Future<void> stop() async {
    started = false;
    final text = finalOnStop;
    if (text != null) onResult(text, true);
  }
}

void main() {
  late Directory dir;
  late FakeSpeech speech;
  late EntryRepository repo;
  late Settings settings;
  late RecordingController controller;
  var clock = DateTime.utc(2025, 5, 1, 12);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('journal_rec_');
    speech = FakeSpeech();
    repo = EntryRepository(File('${dir.path}/entries.json'));
    settings = Settings(File('${dir.path}/settings.json'));
    await settings.setSensorKitId('sa-sa-sk-4');
    clock = DateTime.utc(2025, 5, 1, 12);
    controller = RecordingController(
      speech: speech,
      repository: repo,
      settings: settings,
      finalResultTimeout: const Duration(milliseconds: 50),
      now: () => clock,
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('start begins listening with the German locale', () async {
    await controller.start();
    expect(controller.state, RecordingState.listening);
    expect(speech.started, isTrue);
    expect(speech.locale, 'de_DE');
  });

  test('stop saves the final transcript stamped with the start time', () async {
    await controller.start();
    clock = clock.add(const Duration(seconds: 20));
    speech.finalOnStop = 'Es klingelt an der Tür';
    await controller.stop();

    expect(controller.state, RecordingState.idle);
    expect(repo.entries, hasLength(1));
    final e = repo.entries.single;
    expect(e.text, 'Es klingelt an der Tür');
    expect(e.created, DateTime.utc(2025, 5, 1, 12));
    expect(e.sensorKitId, 'sa-sa-sk-4');
    expect(e.id, startsWith('sa-sa-sk-4-'));
    expect(controller.lastEntry, e);
    expect(controller.problem, isNull);
  });

  test('partial results are exposed while listening', () async {
    await controller.start();
    speech.onResult('Es klin', false);
    expect(controller.partialText, 'Es klin');
  });

  test(
    'stop falls back to the last partial result after the timeout',
    () async {
      await controller.start();
      speech.onResult('nur partiell', false);
      await controller.stop();
      expect(repo.entries.single.text, 'nur partiell');
    },
  );

  test('a final result while listening saves without a stop', () async {
    await controller.start();
    speech.onResult('Pause erkannt', true);
    await controller.settled;
    expect(controller.state, RecordingState.idle);
    expect(repo.entries.single.text, 'Pause erkannt');
  });

  test('nothing is saved when no speech was heard', () async {
    await controller.start();
    await controller.stop();
    expect(repo.entries, isEmpty);
    expect(controller.problem, RecordingProblem.noSpeech);
    expect(controller.state, RecordingState.idle);
  });

  test('whitespace-only transcripts count as no speech', () async {
    await controller.start();
    speech.finalOnStop = '   ';
    await controller.stop();
    expect(repo.entries, isEmpty);
    expect(controller.problem, RecordingProblem.noSpeech);
  });

  test('refuses to record before a SensorKit id is chosen', () async {
    final fresh = Settings(File('${dir.path}/none.json'));
    final c = RecordingController(
      speech: speech,
      repository: repo,
      settings: fresh,
    );
    await c.start();
    expect(c.problem, RecordingProblem.notConfigured);
    expect(c.state, RecordingState.idle);
    expect(speech.started, isFalse);
  });

  test('reports when speech recognition is unavailable', () async {
    speech.available = false;
    await controller.start();
    expect(controller.problem, RecordingProblem.unavailable);
    expect(controller.state, RecordingState.idle);
  });

  test('a recognizer error without speech reports the problem', () async {
    await controller.start();
    speech.onError('error_network');
    expect(controller.problem, RecordingProblem.recognizer);
    expect(controller.problemDetail, 'error_network');
    expect(controller.state, RecordingState.idle);
    expect(repo.entries, isEmpty);
  });

  test('a recognizer error after speech keeps what was heard', () async {
    await controller.start();
    speech.onResult('schon gesagt', false);
    speech.onError('error_speech_timeout');
    await controller.settled;
    expect(repo.entries.single.text, 'schon gesagt');
    expect(controller.problem, isNull);
  });

  test('cancel discards the transcript', () async {
    await controller.start();
    speech.onResult('verwerfen', false);
    await controller.cancel();
    expect(controller.state, RecordingState.idle);
    expect(controller.partialText, '');
    expect(repo.entries, isEmpty);
  });

  test('stop and a second start are ignored in the wrong state', () async {
    await controller.stop();
    expect(controller.state, RecordingState.idle);
    await controller.start();
    await controller.start();
    expect(controller.state, RecordingState.listening);
  });

  test('a new recording clears the previous problem', () async {
    await controller.start();
    await controller.stop();
    expect(controller.problem, RecordingProblem.noSpeech);
    await controller.start();
    expect(controller.problem, isNull);
  });
}
