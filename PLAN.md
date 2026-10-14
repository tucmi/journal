# Journal app: plan

Original brief: a Flutter journaling app for short spoken entries of what is currently happening. It complements the SensorKit (https://simplications.tucmi.de/sensorkit/): entries are created decoupled from sensor data but can be reunited later, so it needs a structured JSON export. Browse and edit entries by time and content, speech to text, a widget to jump straight into recording, minimal packages.

## Finding about SensorKit

SensorKit is a hardware kit, not an app. SensorTags, an AtomS3 and an M5StickC send data to a Raspberry Pi, which stores it in InfluxDB and shows it in Grafana. The page documents no export format or time sync, so the join key between entries and sensor data can only be time.

## Core design decision: time is the join key

The export follows the SensorKit Grafana annotation format (example: `Downloads/SK1_annotations.anonym.json`, a JSON array of annotation objects). Only four fields matter:

| Field | Meaning |
|---|---|
| `id` | String: a generated unique id extended with the SensorKit id, e.g. `sa-sa-sk-1-3f9c2a` |
| `created` | Single epoch-millisecond timestamp (UTC) of when the entry was recorded; replaces `time`/`timeEnd` |
| `login`, `email` | The SensorKit id, e.g. `sa-sa-sk-1`, selected once on first launch; both fields carry the same value |
| `text` | The speech-to-text transcript (editable) |

```json
[
  {
    "id": "sa-sa-sk-1-3f9c2a",
    "created": 1737361838180,
    "login": "sa-sa-sk-1",
    "email": "sa-sa-sk-1",
    "text": "..."
  }
]
```

- `created` as epoch ms UTC matches Grafana and Influx directly, so entries and sensor data line up on time.
- All other Grafana fields (`alertId`, `alertName`, `dashboardId`, `dashboardUID`, `panelId`, `userId`, `newState`, `prevState`, `updated`, `time`, `timeEnd`, `tags`, `avatarUrl`, `data`, ...) are emitted empty for now (`""`, `0`, `[]`, `{}` by type, as in the example file). Filling them is a later decision.
- SensorKit ids are `sa-sa-sk-1` through `sa-sa-sk-12`. First launch shows a fixed picker with these 12 values; the choice can be changed later in settings.
- The earlier clock-offset idea is dropped unless the Pi drift turns out to matter.
- Export: a single JSON array file via the share sheet; import of the same format.

## Features

1. **Record:** one tap starts recording and a second tap stops it. The entry is saved immediately with the timestamp, then transcribed.
2. **Browse:** a list grouped by day, with a text search over content, a date-range filter, and a day or timeline view.
3. **Edit:** correct the transcript, adjust the timestamps (useful for entries made later), delete entries, and add an optional tag or note.
4. **Quick-record widget:** a home screen widget or shortcut that deep-links into the app and starts recording at once.
5. **Export and import:** JSON export through the system share sheet, and import of the same format.

## Architecture and packages

| Need | Choice | Why |
|---|---|---|
| State | `ChangeNotifier` and `ListenableBuilder` | No package needed |
| Storage | One JSON file per entry, or one JSONL file, in the app documents directory | A journal holds thousands of entries at most, so search can filter in memory. No SQLite needed. |
| Paths | `path_provider` | Required |
| Speech to text | `speech_to_text` | Uses the OS recognizer. It can run on-device on Android and iOS, which fits a privacy-focused project. |
| Audio (optional) | `record` | Only if you want to keep the audio |
| Export | `share_plus` | Share sheet for the JSON file |
| Widget | `home_widget`, or a small native Android widget | See the open questions |

That is about 3 to 5 packages.

**Audio and speech to text conflict.** `speech_to_text` and a separate recorder both want the microphone, and they can conflict. If you keep the audio, an alternative is to record with `record` and transcribe afterwards. Whisper through `whisper.cpp` and FFI would be fully on-device and work on every platform, but it adds real complexity. Suggested start: `speech_to_text` and no stored audio.

## Phases

1. **Skeleton:** data model, JSON store, and list, detail and edit screens, all with fake data.
2. **Recording and speech to text:** record, transcribe, and save. This is the riskiest part, so test it on a real device early.
3. **Search and filter:** content search and a date range.
4. **Export and import:** annotation-format JSON array, share sheet, and a round-trip test.
5. **Quick-record widget:** deep link `journal://record`, plus the platform widget.
6. **Polish:** permissions, offline behaviour when no recognizer is available, first-launch SensorKit id picker, German UI.

## Decisions (2026-10-14)

- Platforms: Android first, iOS later.
- Audio: transcript only for v1.
- Language: German only.
- Project: standalone, not part of Simplications 2.0.
- SensorKit id: fixed list `sa-sa-sk-1` to `sa-sa-sk-12`, picked on first launch.

## Open questions (original)

1. **Target platforms:** Android only, Android and iOS, or desktop too? The SensorKit page mentions an iPad as the viewer. This matters most for the widget (Android App Widget versus iOS WidgetKit, which needs Swift) and for how good on-device speech to text is. Suggestion: Android first, then iOS.
2. **Keep the audio?** Keeping it makes transcripts verifiable and re-transcribable, but it adds storage, privacy handling and export size. Suggestion: transcript only for v1, with audio as an opt-in setting.
3. **Languages:** German only, or German and English?
4. **Who consumes the export?** Resolved: the SensorKit Grafana annotation format, reduced to the four fields above.
5. **Which project is this:** part of Simplications 2.0, or standalone? That affects naming, licensing, and whether it goes in the proposal.

Next step once 1 and 2 are answered: scaffold the Flutter project (phases 1 and 2), e.g. in a new folder under `c:\Users\andyb\Workspace\TUC\MI`.
