/// The part of speech recognition the app depends on, so recording logic can
/// be tested without a microphone.
abstract class SpeechService {
  /// Prepares the recognizer and asks for permission. Returns false if speech
  /// recognition is unavailable or permission was denied.
  Future<bool> initialize();

  /// Starts listening. [onResult] receives the transcript so far; the last
  /// call has `isFinal == true`. [onError] reports recognizer failures.
  Future<void> start({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String message) onError,
  });

  /// Stops listening. The final result may still arrive via `onResult`.
  Future<void> stop();
}
