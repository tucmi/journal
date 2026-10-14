import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../models/entry.dart';
import '../recording/speech_service.dart';
import 'logo.dart';

/// First-launch walkthrough: what the app does, which SensorKit this device
/// belongs to, and the microphone permission. Saving the SensorKit id on the
/// last step is what ends the onboarding.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.settings,
    required this.speech,
  });

  final Settings settings;
  final SpeechService speech;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Permission { unknown, asking, granted, denied }

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _lastPage = 2;

  int _page = 0;
  String? _sensorKitId;
  _Permission _permission = _Permission.unknown;

  @override
  void initState() {
    super.initState();
    _sensorKitId = widget.settings.sensorKitId;
  }

  bool get _canContinue => _page != 1 || _sensorKitId != null;

  Future<void> _askPermission() async {
    setState(() => _permission = _Permission.asking);
    final ok = await widget.speech.initialize();
    if (!mounted) return;
    setState(() => _permission = ok ? _Permission.granted : _Permission.denied);
  }

  Future<void> _next() async {
    if (_page < _lastPage) return setState(() => _page++);
    await widget.settings.setSensorKitId(_sensorKitId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: switch (_page) {
                  0 => _intro(context),
                  1 => _sensorKit(context),
                  _ => _microphone(context),
                },
              ),
            ),
            _navigation(),
          ],
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String text) =>
      Text(text, style: Theme.of(context).textTheme.headlineSmall);

  Widget _intro(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Logo(size: 120)),
        const SizedBox(height: 24),
        _heading(context, 'Willkommen im Simplications Journal'),
        const SizedBox(height: 16),
        const Text(
          'Sprich kurz ein, was gerade passiert. Die App wandelt es in Text '
          'um und speichert den Eintrag mit dem genauen Zeitpunkt.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Die Einträge ergänzen die Daten deines SensorKits: Über den '
          'Zeitstempel lassen sie sich später wieder mit den Sensordaten '
          'zusammenführen.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Gespeichert wird nur der Text, keine Tonaufnahme. Die '
          'Spracherkennung übernimmt dein Gerät; je nach Gerät nutzt es dafür '
          'einen Online-Dienst. Exportiert wird nur, wenn du es auslöst.',
        ),
      ],
    );
  }

  Widget _sensorKit(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, 'Welches SensorKit?'),
        const SizedBox(height: 16),
        const Text(
          'Wähle das SensorKit, zu dem dieses Gerät gehört. Die Auswahl steht '
          'in jedem exportierten Eintrag und lässt sich später im Menü ändern.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in sensorKitIds)
              ChoiceChip(
                label: Text(sensorKitDisplayName(id)),
                selected: id == _sensorKitId,
                onSelected: (_) => setState(() => _sensorKitId = id),
              ),
          ],
        ),
      ],
    );
  }

  Widget _microphone(BuildContext context) {
    final message = switch (_permission) {
      _Permission.granted => 'Mikrofon und Spracherkennung sind bereit.',
      _Permission.denied =>
        'Zugriff nicht erteilt oder Spracherkennung nicht verfügbar. Ohne '
            'Mikrofon kann die App nicht aufnehmen. Du kannst es später beim '
            'Aufnehmen erneut versuchen oder den Zugriff in den '
            'Systemeinstellungen erlauben.',
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, 'Mikrofon'),
        const SizedBox(height: 16),
        const Text(
          'Zum Aufnehmen braucht die App Zugriff auf das Mikrofon und die '
          'Spracherkennung deines Geräts. Die Aufnahme läuft nur, solange du '
          'sie gestartet hast.',
        ),
        const SizedBox(height: 24),
        if (_permission != _Permission.granted)
          FilledButton.icon(
            onPressed: _permission == _Permission.asking
                ? null
                : _askPermission,
            icon: const Icon(Icons.mic),
            label: Text(
              _permission == _Permission.denied
                  ? 'Erneut versuchen'
                  : 'Zugriff erlauben',
            ),
          ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _permission == _Permission.granted
                    ? Icons.check_circle
                    : Icons.info_outline,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _navigation() {
    final last = _page == _lastPage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          if (_page > 0)
            TextButton(
              onPressed: () => setState(() => _page--),
              child: const Text('Zurück'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: _canContinue ? _next : null,
            child: Text(last ? 'Fertig' : 'Weiter'),
          ),
        ],
      ),
    );
  }
}
