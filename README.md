# ScholarFlux — Your study life, organized (Cool AF)

> A minimalist, delightful Flutter app to manage subjects, assignments, tests and your calendar — built local-first with a pluggable sync layer.

🔥 Features

- Create, edit and delete subjects and items (assignments, homework, tests).
- Local-first storage (Hive) with a repository abstraction for future cloud sync.
- Dark-first design inspired by Reference.png — clean, fast, and keyboard-friendly.

🚀 Tech stack

- Flutter (Dart)
- Riverpod for state management
- Hive for local storage
- go_router for navigation

> Project layout: see `mobile/` for the full Flutter app implementation and `plan.md` for the roadmap.

Getting started

Prerequisites: Flutter SDK (stable), Xcode/Android Studio for simulators or a physical device.

Quick start:

```bash
cd mobile
flutter pub get
flutter run -d <device-id>  # e.g. flutter devices then flutter run -d <id>
```

Developer notes

- The app initializes Hive on startup (see `mobile/lib/core/storage/local_db.dart`).
- Domain models live under `mobile/lib/features/*/domain` and repositories are in `mobile/lib/data/repositories`.
- To run static analysis: `dart analyze` from the `mobile/` directory.

