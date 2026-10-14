import 'package:speech_to_text/speech_to_text.dart';

import 'speech_service.dart';

/// [SpeechService] backed by the OS recognizer via the `speech_to_text`
/// package.
class SpeechToTextService implements SpeechService {
  SpeechToTextService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  void Function(String message)? _onError;

  @override
  Future<bool> initialize() async {
    try {
      return await _speech.initialize(
        onError: (e) => _onError?.call(e.errorMsg),
      );
    } on Object {
      return false;
    }
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
