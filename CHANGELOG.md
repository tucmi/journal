# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Entry model that maps to and from a SensorKit Grafana annotation (`id`, `created`, `login`, `email`, `text`; all other fields exported empty).
- File-backed entry storage with add, update, remove and atomic writes; a corrupt file is moved aside to `.corrupt` instead of being overwritten.
- Text search, date-range filtering and grouping of entries by day.
- JSON export and import in the annotation format. Import validates the whole file first and skips entries whose `id` already exists.
- Settings store for the SensorKit id (`sa-sa-sk-1` to `sa-sa-sk-12`).
- One-tap recording with German speech to text through the Android recognizer. The entry is stamped with the moment recording started, a recording ends on its own after a pause, and whatever was heard is kept if the recognizer fails.
- Screens: entry list grouped by day with search and date range, entry editor for text and timestamp with delete confirmation, and a SensorKit picker reachable from the menu.
- Export through the share sheet and import through the file picker, from the list's menu.
- Android home screen widget and `journal://record` deep link that open the app and start recording, also when the app is already running.
- First-launch onboarding that explains the app, asks for the SensorKit id and requests the microphone permission.
- Project logo in the onboarding and the list's app bar.
- GitHub Actions CI that checks formatting, analyzes, runs the tests with coverage and builds the Android debug APK on every push to `main` and every pull request, plus Dependabot updates for pub packages and workflow actions.
- Windows runner for local testing (not built in CI, not a supported target).
- README, MIT license, contributing guide and this changelog.

[Unreleased]: https://github.com/tucmi/journal/commits/main
