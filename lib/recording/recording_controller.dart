import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/entry_repository.dart';
import '../data/settings.dart';
import '../models/entry.dart';
import 'speech_service.dart';

enum RecordingState { idle, listening, finishing }

enum RecordingProblem { notConfigured, unavailable, recognizer, noSpeech }

/// Runs one recording at a time: listen, then save the transcript as an entry
/// stamped with the moment recording started.
class RecordingController extends ChangeNotifier {
  RecordingController({
    required this.speech,
    required this.repository,
    required this.settings,
    this.localeId = 'de_DE',
    this.finalResultTimeout = const Duration(seconds: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SpeechService speech;
  final EntryRepository repository;
  final Settings settings;
  final String localeId;

  /// How long to wait for the recognizer's final result after stopping.
  final Duration finalResultTimeout;
  final DateTime Function() _now;

  RecordingState _state = RecordingState.idle;
  RecordingProblem? _problem;
  String _partialText = '';
  String? _problemDetail;
  DateTime? _startedAt;
  Completer<void>? _finalResult;
  Future<void> _pendingFinish = Future.value();

  RecordingState get state => _state;
  bool get isListening => _state == RecordingState.listening;

  /// The transcript so far while listening.
  String get partialText => _partialText;

  /// Why the last attempt failed, cleared when a new recording starts.
  RecordingProblem? get problem => _problem;
  String? get problemDetail => _problemDetail;

  /// Completes when any save started by the recognizer ending on its own is done.
  Future<void> get settled => _pendingFinish;

  /// The entry saved by the last successful recording.
  Entry? lastEntry;

  Future<void> start() async {
    if (_state != RecordingState.idle) return;
    _problem = null;
    _problemDetail = null;
    _partialText = '';
    lastEntry = null;

    if (!settings.isConfigured) return _fail(RecordingProblem.notConfigured);
    if (!await speech.initialize()) return _fail(RecordingProblem.unavailable);

    _startedAt = _now();
    _finalResult = Completer<void>();
    _state = RecordingState.listening;
    notifyListeners();
    await speech.start(
      localeId: localeId,
      onResult: _onResult,
      onError: (m) => _onError(m),
    );
  }

  /// Stops listening and saves the entry. Does nothing unless listening.
  Future<void> stop() async {
    if (_state != RecordingState.listening) return;
    _state = RecordingState.finishing;
    notifyListeners();
    await speech.stop();
    await _finalResult?.future.timeout(finalResultTimeout, onTimeout: () {});
    await _finish();
  }

  /// Stops listening and throws the transcript away.
  Future<void> cancel() async {
    if (_state == RecordingState.idle) return;
    await speech.stop();
    _reset();
  }

  void _onResult(String text, bool isFinal) {
    if (_state == RecordingState.idle) return;
    _partialText = text;
    notifyListeners();
    if (!isFinal) return;
    final waiting = _finalResult;
    if (waiting != null && !waiting.isCompleted) waiting.complete();
    // The recognizer ended on its own (e.g. a pause): save without a tap.
    if (_state == RecordingState.listening) {
      _state = RecordingState.finishing;
      notifyListeners();
      _pendingFinish = _finish();
    }
  }

  void _onError(String message) {
    if (_state == RecordingState.idle) return;
    // Keep whatever was heard: an error after speech should not lose it.
    if (_partialText.trim().isNotEmpty) {
      _state = RecordingState.finishing;
      _pendingFinish = _finish();
      return;
    }
    _reset();
    _fail(RecordingProblem.recognizer, detail: message);
  }

  Future<void> _finish() async {
    if (_state == RecordingState.idle) return;
    final text = _partialText.trim();
    final startedAt = _startedAt!;
    _reset();
    if (text.isEmpty) return _fail(RecordingProblem.noSpeech);
    final entry = Entry.create(
      sensorKitId: settings.sensorKitId!,
      text: text,
      created: startedAt,
    );
    await repository.add(entry);
    lastEntry = entry;
    notifyListeners();
  }

  void _reset() {
    _state = RecordingState.idle;
    _partialText = '';
    _startedAt = null;
    _finalResult = null;
    notifyListeners();
  }

  void _fail(RecordingProblem problem, {String? detail}) {
    _problem = problem;
    _problemDetail = detail;
    notifyListeners();
  }
}
