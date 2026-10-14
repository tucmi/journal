# Contributing

Thanks for helping with Journal. This is a small project; a few conventions keep it easy to maintain.

## Before you start

Read [README.md](README.md) for what the app does and [PLAN.md](PLAN.md) for the design decisions. For anything bigger than a bug fix, open an issue first so the approach can be agreed before you write code.

Constraints that shape most decisions:

- **Time is the join key.** The export must stay in the SensorKit Grafana annotation format, and `created` stays epoch milliseconds in UTC. Changing the format is a breaking change for everyone who joins entries with sensor data.
- **Transcript only.** The app does not store audio.
- **Few dependencies.** Prefer the Flutter SDK and plain Dart; add a package only when it clearly pays for itself.
- **German UI, English code.** User-facing strings are German. Code, comments, commit messages and docs are English.

## Setup

You need [Flutter](https://docs.flutter.dev/get-started/install) and the Android SDK.

```sh
git clone https://github.com/tucmi/journal.git
cd journal
flutter pub get
flutter test
```

## Making a change

1. Create a branch from `main`.
2. Keep the change focused: one concern per pull request.
3. Add or update tests. Logic lives in plain classes (`lib/data`, `lib/recording`) that are tested without a device; screens are covered by widget tests. Platform plugins sit behind small interfaces (`SpeechService`, `FileTransfer`, `RecordRequests`) so tests can use fakes.
4. Run the checks, which must all pass (the CI workflow runs the same ones, and also builds the Android debug APK, on every push to `main` and every pull request):

   ```sh
   dart format lib test
   flutter analyze
   flutter test
   ```

5. Add a line under **Unreleased** in [CHANGELOG.md](CHANGELOG.md) for anything a user or integrator would notice.
6. Open a pull request that says what changed and why. If it touches speech recognition, the widget or sharing, say which device and Android version you tried it on, since those cannot be tested automatically.

## Code style

- Follow `flutter_lints` (see `analysis_options.yaml`) and format with `dart format`.
- Match the surrounding code: naming, comment density and structure. Comments explain why, not what.
- State is held in `ChangeNotifier`s and rendered with `ListenableBuilder`; keep it that way unless there is a reason not to.

## Commits

Write the subject in the imperative mood and keep it short, as in the existing history, for example `Add JSON export via share sheet and import via file picker`. Explain the reason in the body when it is not obvious.

## Reporting bugs

Open an issue with the device model, Android version, what you did, what you expected and what happened. For a recognition problem, say whether the device was online and which language packs are installed. Please do not paste real journal entries or SensorKit ids you consider private.

## License

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).
