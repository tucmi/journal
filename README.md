<p align="center">
  <img src="assets/logo.png" alt="Simplications logo" width="120">
</p>

# Journal

A Flutter app for short spoken journal entries: tap, say what is happening right now, and the app saves the transcript with a timestamp.

It complements the [SensorKit](https://simplications.tucmi.de/sensorkit/), a set of sensors that sends data to a Raspberry Pi (InfluxDB and Grafana). Entries are created independently of the sensor data and can be reunited with it later, because **time is the join key**. Each entry is stored and exported as a Grafana annotation.

> **Status:** early development. Android only. The app has not yet been field-tested on a physical device.

## Features

- **One-tap recording:** tap the mic button, speak, tap again. German speech to text through the operating system's recognizer. Only the transcript is stored, never audio.
- **Browse:** entries grouped by day, with text search and a date-range filter.
- **Edit:** correct the transcript, change the date and time (useful for entries made later), or delete an entry.
- **Home screen widget:** an Android widget that opens the app and starts recording immediately (deep link `journal://record`).
- **Export and import:** a JSON array in the SensorKit annotation format through the share sheet, and import of the same format.
- **Onboarding:** explains the app, asks which SensorKit the device belongs to (`sa-sa-sk-1` to `sa-sa-sk-12`) and requests the microphone permission.

## Export format

The export is a JSON array of Grafana annotations. Only four fields carry data; the rest are emitted empty so the file matches what SensorKit tooling expects.

| Field | Meaning |
|---|---|
| `id` | The SensorKit id plus a random suffix, e.g. `sa-sa-sk-1-3f9c2a` |
| `created` | When the entry was recorded: epoch milliseconds, UTC |
| `login`, `email` | The SensorKit id chosen on first launch (both carry the same value) |
| `text` | The transcript, as edited |

```json
[
  {
    "id": "sa-sa-sk-1-3f9c2a",
    "created": 1737361838180,
    "login": "sa-sa-sk-1",
    "email": "sa-sa-sk-1",
    "text": "Kaffee gekocht",
    "alertId": 0,
    "tags": [],
    "data": {}
  }
]
```

(The real export contains every Grafana field; this example is shortened.)

`created` is epoch milliseconds in UTC, as Grafana and InfluxDB use, so entries line up with sensor data directly. Importing skips entries whose `id` already exists.

## Privacy

- Entries are stored in a JSON file in the app's private documents directory. Nothing leaves the device unless you export.
- Speech recognition is done by the Android system. Depending on the device and whether an offline German language pack is installed, Android may send audio to an online recognition service. The app does not currently force on-device recognition.

## Getting started

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.13.5`) and the Android SDK.

```sh
flutter pub get
flutter run            # with an Android device or emulator attached
flutter test
flutter analyze
flutter build apk
```

For quick local testing there is also a Windows runner (`flutter run -d windows`). It is not built in CI and not a supported target: speech recognition and the widget are Android only, so recording reports the recognizer as unavailable there, but browsing, editing, search and import work.

Speech recognition and the widget need a real device or an emulator with Google services; they cannot be exercised by the unit and widget tests.

### Project layout

```text
lib/
  data/        entry storage, filtering, export codec, settings, file transfer
  models/      Entry and its Grafana annotation mapping
  recording/   recording state machine, speech service, record requests
  ui/          screens: onboarding, list, edit, SensorKit picker
android/       manifest, home screen widget, deep link handling
windows/       generated runner for local testing only
test/          unit and widget tests, mirroring lib/
```

The design decisions and the roadmap are written down in [PLAN.md](PLAN.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Changes are tracked in [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE)
