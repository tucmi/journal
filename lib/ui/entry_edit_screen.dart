import 'package:flutter/material.dart';

import '../data/entry_repository.dart';
import '../models/entry.dart';
import 'format.dart';

/// Edit the transcript and timestamp of an entry, or delete it.
class EntryEditScreen extends StatefulWidget {
  const EntryEditScreen({
    super.key,
    required this.repository,
    required this.entry,
  });

  final EntryRepository repository;
  final Entry entry;

  @override
  State<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  late final TextEditingController _text = TextEditingController(
    text: widget.entry.text,
  );
  late DateTime _created = widget.entry.created.toLocal();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _created,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    setState(() {
      _created = DateTime(
        date.year,
        date.month,
        date.day,
        _created.hour,
        _created.minute,
        _created.second,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_created),
    );
    if (time == null) return;
    setState(() {
      _created = DateTime(
        _created.year,
        _created.month,
        _created.day,
        time.hour,
        time.minute,
        _created.second,
      );
    });
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    await widget.repository.update(
      widget.entry.copyWith(text: text, created: _created),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.repository.remove(widget.entry.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eintrag'),
        actions: [
          IconButton(
            tooltip: 'Löschen',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
          IconButton(
            tooltip: 'Speichern',
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(formatDate(_created)),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(formatTime(_created)),
                  onPressed: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            minLines: 5,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Text',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
