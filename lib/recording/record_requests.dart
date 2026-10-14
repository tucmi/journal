import 'package:flutter/services.dart';

/// "Start recording now" requests from outside the app, e.g. the Android home
/// screen widget opening `journal://record`.
abstract class RecordRequests {
  /// True if the app was launched by such a request. Reports it only once.
  Future<bool> takeInitial();

  /// Calls [onRequest] for every request that arrives while the app runs.
  void listen(void Function() onRequest);
}

/// No outside requests (tests, platforms without a widget).
class NoRecordRequests implements RecordRequests {
  const NoRecordRequests();

  @override
  Future<bool> takeInitial() async => false;

  @override
  void listen(void Function() onRequest) {}
}

/// Talks to `MainActivity` over a method channel.
class ChannelRecordRequests implements RecordRequests {
  ChannelRecordRequests({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('de.tucmi.journal/launch');

  final MethodChannel _channel;

  @override
  Future<bool> takeInitial() async {
    try {
      return await _channel.invokeMethod<bool>('takeRecordRequest') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  void listen(void Function() onRequest) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'recordRequested') onRequest();
    });
  }
}
