import 'package:flutter/material.dart';

import '../data/entry_query.dart';
import '../data/entry_repository.dart';
import '../data/export_codec.dart';
import '../data/file_transfer.dart';
import '../data/settings.dart';
import '../models/entry.dart';
import '../recording/recording_controller.dart';
import 'entry_edit_screen.dart';
import 'format.dart';
import 'id_picker_screen.dart';
import 'logo.dart';

/// The main screen: entries grouped by day, search, date range, record button.
class EntryListScreen extends StatefulWidget {
  const EntryListScreen({
    super.key,
    required this.repository,
    required this.settings,
    required this.recorder,
    required this.transfer,
  });

  final EntryRepository repository;
  final Settings settings;
  final RecordingController recorder;
  final FileTransfer transfer;

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen> {
  String _text = '';
  DateTimeRange? _range;
  bool _searching = false;
  RecordingProblem? _shownProblem;

  EntryQuery get _query =>
      EntryQuery(text: _text, from: _range?.start, to: _range?.end);

  @override
  void initState() {
    super.initState();
    widget.recorder.addListener(_showProblem);
  }

  @override
  void dispose() {
    widget.recorder.removeListener(_showProblem);
    super.dispose();
  }

  void _showProblem() {
    final problem = widget.recorder.problem;
    if (problem == _shownProblem) return;
    _shownProblem = problem;
    if (problem == null || !mounted) return;
    final message = switch (problem) {
      RecordingProblem.notConfigured => 'Bitte zuerst ein SensorKit wählen.',
      RecordingProblem.unavailable =>
        'Spracherkennung nicht verfügbar oder Mikrofon nicht erlaubt.',
      RecordingProblem.recognizer => 'Spracherkennung fehlgeschlagen.',
      RecordingProblem.noSpeech => 'Nichts verstanden, nichts gespeichert.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (range != null) setState(() => _range = range);
  }

  void _openEdit(Entry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EntryEditScreen(repository: widget.repository, entry: entry),
      ),
    );
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    final entries = widget.repository.entries;
    if (entries.isEmpty) return _say('Keine Einträge zum Exportieren.');
    try {
      await widget.transfer.share(
        fileName: exportFileName(
          widget.settings.sensorKitId ?? 'journal',
          DateTime.now(),
        ),
        contents: encodeExport(entries),
      );
    } on Object {
      if (mounted) _say('Export fehlgeschlagen.');
    }
  }

  Future<void> _import() async {
    final String? source;
    try {
      source = await widget.transfer.pickJson();
    } on Object {
      if (mounted) _say('Datei konnte nicht gelesen werden.');
      return;
    }
    if (source == null) return;
    try {
      final added = await widget.repository.addAll(decodeExport(source));
      if (mounted) {
        _say(
          added == 0
              ? 'Nichts Neues importiert.'
              : '$added Einträge importiert.',
        );
      }
    } on FormatException {
      if (mounted) _say('Keine gültige Journal-Datei.');
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Simplications Journal',
      applicationVersion: '0.1.0',
      applicationIcon: const Logo(size: 48),
      applicationLegalese: '© Simplications-Projekt · MIT-Lizenz',
      children: const [
        SizedBox(height: 16),
        Text(
          'Das Simplications Journal ergänzt die Daten deines SensorKits: '
          'Du sprichst Einträge ein, die als Annotationen exportiert werden. '
          'Alle Einträge werden lokal auf dem Gerät gespeichert, ein Konto '
          'ist nicht nötig.',
        ),
        SizedBox(height: 12),
        Text(
          'Entwickelt vom Simplications-Projekt. Partner: Technische '
          'Universität Chemnitz, Hochschule Anhalt, Verbraucherzentrale '
          'Sachsen e.V. Koordination: Plattform Privatheit. Gefördert vom '
          'BMFTR.',
        ),
        SizedBox(height: 12),
        SelectableText('https://simplications.tucmi.de'),
      ],
    );
  }

  void _openIdPicker() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => IdPickerScreen(
          settings: widget.settings,
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Suchen',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _text = v),
              )
            : const Row(
                children: [
                  Logo(size: 28),
                  SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Simplications Journal'),
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: 'Suchen',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _text = '';
            }),
          ),
          IconButton(
            tooltip: 'Zeitraum',
            icon: const Icon(Icons.date_range),
            onPressed: _pickRange,
          ),
          PopupMenuButton<VoidCallback>(
            tooltip: 'Menü',
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(value: _export, child: const Text('Exportieren')),
              PopupMenuItem(value: _import, child: const Text('Importieren')),
              PopupMenuItem(
                value: _openIdPicker,
                child: const Text('SensorKit ändern'),
              ),
              PopupMenuItem(value: _showAbout, child: const Text('Über')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_range != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(
                    '${formatDate(_range!.start)} – ${formatDate(_range!.end)}',
                  ),
                  onDeleted: () => setState(() => _range = null),
                ),
              ),
            ),
          ListenableBuilder(
            listenable: widget.recorder,
            builder: (context, _) => widget.recorder.isListening
                ? Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.errorContainer,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.recorder.partialText.isEmpty
                          ? 'Ich höre zu …'
                          : widget.recorder.partialText,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.repository,
              builder: (context, _) => _buildList(context),
            ),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: widget.recorder,
        builder: (context, _) {
          final listening = widget.recorder.isListening;
          return FloatingActionButton.large(
            tooltip: listening ? 'Aufnahme beenden' : 'Aufnehmen',
            onPressed: widget.recorder.state == RecordingState.finishing
                ? null
                : listening
                ? widget.recorder.stop
                : widget.recorder.start,
            child: Icon(listening ? Icons.stop : Icons.mic),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final groups = groupByDay(_query.apply(widget.repository.entries));
    if (groups.isEmpty) {
      return Center(
        child: Text(
          widget.repository.entries.isEmpty
              ? 'Noch keine Einträge.'
              : 'Keine Treffer.',
        ),
      );
    }
    return ListView(
      children: [
        for (final MapEntry(key: day, value: entries) in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              formatDayHeading(day),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final e in entries)
            ListTile(
              leading: Text(formatTime(e.created)),
              title: Text(e.text, maxLines: 3, overflow: TextOverflow.ellipsis),
              onTap: () => _openEdit(e),
            ),
        ],
        const SizedBox(height: 96),
      ],
    );
  }
}
