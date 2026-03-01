<div align="center">

# 📚 ScholarFlux

**Your study life, organized.**

A beautiful, offline-first Flutter app to manage subjects, assignments, tests, grades, and your weekly class schedule — wrapped in a sleek Liquid Glass dark UI.

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20macOS-lightgrey)]()

</div>

---

## Table of Contents

- [Features](#-features)
- [Screenshots](#-screenshots)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Running on Simulators / Emulators](#-running-on-simulators--emulators)
- [Technical Documentation](#-technical-documentation)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

### 📊 Dashboard
- At-a-glance view of **today's classes**, **upcoming assignments** (due within 7 days), and **future work**.
- Date header with weekday chips for quick context.
- Tap any item to view full details.

### 📖 Subject Management
- Create subjects with a **name**, **room**, **max grade** scale (20, 100, etc.), and multiple **grading domains** with customizable weight percentages.
- **Weighted grade averages** computed automatically across domains.
- Per-domain score breakdown on every subject card.

### 📝 Items (Assignments, Homework & Tests)
- Track **assignments**, **homework**, and **tests** per subject.
- Fields: title, description, due date, priority (low/medium/high), origin (who assigned it), grade, domain, and weight.
- **Grade locking**: grades can only be entered after the due date passes.
- **Smart status indicators**: ✅ completed, ⚠️ overdue, ○ pending.
- Automatic sorting: pending items first, then by due date.

### 📅 Calendar
- Monthly calendar grid with **item dots** highlighting days with due items.
- Tap a day to see all items due on that date.
- Horizontal month chip selector for quick navigation.
- Future work list for the selected month.

### 🕐 Class Schedule
- Register weekly recurring classes linked to subjects.
- Specify **day of week**, **start/end time**, **room**, **floor**, and **teacher**.
- iOS-style **scroll wheel time picker**.
- Schedule grouped by weekday with classes sorted by time.
- Long-press to delete a class.

### 🎨 Liquid Glass UI
- Frosted glass containers with **backdrop blur**, translucent gradients, and specular highlights.
- Staggered fade+slide list animations.
- iOS-style tap-scale micro-interactions.
- Fully dark themed with Apple-inspired color palette.

### 💾 Offline-First
- **Zero network dependency** — all data stored locally with Hive.
- Repository pattern abstraction ready for future cloud sync.
- Instant reads and writes, no loading spinners for local data.

---

## 📸 Screenshots

> *Coming soon — run the app to see the Liquid Glass UI in action!*

---

## 🏗 Architecture

ScholarFlux follows a **feature-first clean architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│   Screens • Widgets • GoRouter Navigation   │
├─────────────────────────────────────────────┤
│              Application Layer              │
│     Riverpod AsyncNotifiers & Providers     │
├─────────────────────────────────────────────┤
│               Domain Layer                  │
│  Immutable Models • Business Logic • Enums  │
├─────────────────────────────────────────────┤
│                Data Layer                   │
│   Abstract Repositories → Hive Impl.       │
└─────────────────────────────────────────────┘
```

**Key patterns:**
- **Immutable domain models** with `copyWith`, `toMap`, `fromMap`
- **Repository pattern** — abstract interfaces with swappable implementations
- **Riverpod `AsyncNotifier`** — reactive state that auto-refreshes on mutations
- **Derived providers** — computed filtered/sorted views (upcoming items, today's classes, etc.)
- **ID generation** — microsecond timestamps in base-36 for compact unique IDs

---

## 🛠 Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter 3.41** | Cross-platform UI framework |
| **Dart** | Programming language |
| **Riverpod** | Reactive state management |
| **Hive** | Lightweight local NoSQL database |
| **GoRouter** | Declarative routing with nested navigation |
| **Material 3** | Design system (customized for Liquid Glass) |

---

## 📁 Project Structure

```
mobile/lib/
├── main.dart                          # Entry point — Hive init + ProviderScope
├── app.dart                           # MaterialApp.router with dark theme
│
├── core/
│   ├── storage/
│   │   ├── local_db.dart              # Hive box initialization & accessors
│   │   └── app_preferences.dart       # Key-value prefs (onboarding seen, etc.)
│   ├── routing/
│   │   ├── app_router.dart            # GoRouter config with all routes
│   │   └── nav_shell.dart             # Floating glass bottom navigation bar
│   ├── theme/
│   │   ├── colors.dart                # Color tokens (Liquid Glass palette)
│   │   ├── typography.dart            # Text style tokens
│   │   └── app_theme.dart             # Complete ThemeData assembly
│   └── widgets/
│       ├── glass_container.dart        # Frosted glass card component
│       ├── glass_helpers.dart          # Glass confirmation dialog
│       └── animations.dart            # AnimatedListItem, TapScale, FadeIn
│
├── data/
│   └── repositories/
│       ├── hive_subject_repository.dart
│       ├── hive_item_repository.dart
│       └── hive_class_repository.dart
│
└── features/
    ├── dashboard/
    │   └── presentation/
    │       └── dashboard_screen.dart   # Home screen with classes + items
    ├── subjects/
    │   ├── domain/
    │   │   └── subject.dart            # Subject + SubjectDomain models
    │   ├── data/
    │   │   └── subject_repository.dart # Abstract interface
    │   ├── application/
    │   │   └── subjects_controller.dart # Riverpod notifier + providers
    │   └── presentation/
    │       ├── subjects_screen.dart     # Subject list with grade averages
    │       ├── subject_detail_screen.dart # Subject detail + item list
    │       └── edit_subject_screen.dart  # Create/edit form with domains
    ├── items/
    │   ├── domain/
    │   │   ├── item.dart               # Item model with computed props
    │   │   └── item_type.dart          # ItemType, ItemPriority, ItemStatus
    │   ├── data/
    │   │   └── item_repository.dart    # Abstract interface
    │   ├── application/
    │   │   └── items_controller.dart   # Notifier + 7 derived providers
    │   └── presentation/
    │       ├── edit_item_screen.dart    # Create/edit form with grade lock
    │       └── item_detail_screen.dart  # Full item details view
    ├── calendar/
    │   └── presentation/
    │       └── calendar_screen.dart     # Monthly grid + day detail
    ├── classes/
    │   ├── domain/
    │   │   └── class_entry.dart         # ClassEntry model
    │   ├── data/
    │   │   └── class_repository.dart    # Abstract interface
    │   ├── application/
    │   │   └── classes_controller.dart  # Notifier + day/subject providers
    │   └── presentation/
    │       ├── schedule_screen.dart     # Weekly schedule grouped by day
    │       └── edit_class_screen.dart   # Create/edit with wheel picker
    └── onboarding/
        └── presentation/
            └── onboarding_screen.dart   # 3-page intro walkthrough
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.41 (stable channel)
- **Xcode** (for iOS/macOS) or **Android Studio** (for Android)
- A simulator, emulator, or physical device

### Quick Start

```bash
cd mobile
flutter pub get
flutter run
```

### Static Analysis

```bash
cd mobile
dart analyze
```

---

## 📱 Running on Simulators / Emulators

### iOS Simulator

```bash
cd mobile
xcrun simctl boot "iPhone 17 Pro" || true
open -a Simulator
flutter pub get
flutter run -d "iPhone 17 Pro"
```

### Android Emulator

```bash
cd mobile

# List available AVDs
$HOME/Library/Android/sdk/emulator/emulator -list-avds

# Launch emulator
$HOME/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36.1 &

# Wait for boot
$HOME/Library/Android/sdk/platform-tools/adb wait-for-device
$HOME/Library/Android/sdk/platform-tools/adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done'

# Run
flutter pub get
flutter run -d emulator-5554
```

> **Tip:** If you encounter an NDK `source.properties` error, delete the corrupted NDK folder:
> `rm -rf $HOME/Library/Android/sdk/ndk/28.2.13676358`

---

## 📖 Technical Documentation

For a deep-dive into every function, class, provider, and widget — including code snippets, logic explanations, and data flow diagrams — see **[tech.md](tech.md)**.

---

## 🗺 Roadmap

- [x] Subject CRUD with weighted grading domains
- [x] Items (assignments, homework, tests) with grades
- [x] Dashboard with today's classes and upcoming items
- [x] Monthly calendar with item indicators
- [x] Weekly class schedule management
- [x] Liquid Glass UI theme
- [x] Offline-first with Hive
- [ ] Onboarding flow completion (skip/done buttons)
- [ ] Cloud sync (Firebase / Supabase)
- [ ] Push notifications for due dates
- [ ] Grade trend charts and analytics
- [ ] Subject color coding
- [ ] Export/import data
- [ ] Widget for home screen (iOS/Android)
- [ ] Localization (PT, EN, ES)

---

## 🤝 Contributing

PRs welcome! Keep changes small and focused. For major features, open an issue first to discuss design and UX.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

