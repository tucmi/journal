import 'package:speech_to_text/speech_to_text.dart';

import 'speech_service.dart';

/// [SpeechService] backed by the OS recognizer via the `speech_to_text`
/// package.
class SpeechToTextService implements SpeechService {
  SpeechToTextService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  void Function(String message)? _onError;
  bool _initialized = false;

  /// Initialising talks to the OS recognizer service, which is slow on weak
  /// phones, so a success is remembered. A failure is retried next time (the
  /// user may have granted the permission in between).
  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (e) => _onError?.call(e.errorMsg),
      );
    } on Object {
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<void> start({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String message) onError,
  }) async {
    _onError = onError;
    try {
      await _speech.listen(
        onResult: (r) => onResult(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          localeId: localeId,
          // Journal entries can be a few sentences with pauses to think.
          listenFor: const Duration(minutes: 5),
          pauseFor: const Duration(seconds: 10),
        ),
      );
    } on Object catch (e) {
      onError(e.toString());
    }
  }

  @override
  Future<void> stop() => _speech.stop();
}
