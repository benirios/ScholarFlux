# ScholarFlux — Implementation Plan

Date: 2026-02-27

Overview
- Build a cross-platform Flutter app for iOS and Android to help students manage their subjects and coursework.
- Users can create subjects and, inside each subject, add assignments, homework, tests and similar items.
- UI and dark theme should follow the reference image at ScholarFlux/Copilot/Context/Reference.png.

Scope (MVP)
- Subjects: add / edit / delete / list.
- Items inside subjects: add / edit / delete assignments, homework, tests; fields: title, type, due date, notes, priority, optional attachments.
- Calendar view and a "future work" list as in the reference.
- Dark theme with styles and components matching the reference.
- Local-first storage with a pluggable sync layer for optional cloud sync.

Out of scope (MVP)
- Single-sign-on or school system integrations.
- Complex grade-management rules beyond simple averages.
- Cross-platform desktop or web targets (mobile only for now).

Architecture & Tech Decisions
- Framework: Flutter (chosen).
- State management: Riverpod recommended (can change to Provider/Bloc if preferred).
- Storage: Local DB (Hive or sqflite) with a repository abstraction to make cloud sync pluggable.
- Optional cloud sync: Firebase (Auth + Firestore + Storage) if chosen.
- Testing: Unit and widget tests; CI via GitHub Actions later.

Milestones & Todos
1. create-flutter-app
   - Scaffold a new Flutter project under mobile/ with package name and platform support for iOS and Android.
2. ui-layout-reference
   - Implement base UI and navigation: calendar, subjects list, subject detail, item list/detail; apply dark theme tokens.
3. subjects-model
   - Define Subject and Item models and repository interfaces (types: Assignment, Homework, Test).
4. subject-crud
   - Implement the UI and persistence for creating, editing, deleting subjects.
5. item-crud
   - Implement CRUD for items inside subjects including validation and local persistence.
6. storage-architecture
   - Choose and implement local DB (Hive or sqflite) and create repository layer; make cloud sync pluggable.
7. styling-theme
   - Implement color tokens, typography, and reusable components to match Reference.png.
8. calendar-integration
   - Add calendar/day/week views and future-work list with date highlighting.
9. ios-android-build
   - Configure platform builds, app icons, splash screens, and verify on simulator/emulator.
10. tests-and-docs
   - Add basic unit/widget tests and update README with setup and run instructions.

Questions (RESOLVED)
1) Q1: **Local-first only** — no cloud sync in MVP; repository abstraction keeps it pluggable.
2) Q2: **No authentication** — no Firebase Auth needed.
3) Q3: **Attachments deferred** — items are text-only for MVP.
4) Q4: **Riverpod** — chosen for state management.
5) Q5: **English only** — no i18n in MVP.
6) Bundle ID: **com.scholarflux.app**

Next steps
- Answer Q1 (storage/sync approach). After that, mark `create-flutter-app` as in_progress and begin scaffolding.
- Iteratively implement milestones in the order above; each todo will be tracked in the session DB.



Screens

- Onboarding
  - 3 swipable screens: 1) The pain (chaotic school life), 2) How ScholarFlux helps (subjects, items, calendar), 3) Get started (create subject / continue local). Onboarding is skippable and shown only on first launch.

- Dashboard
  - Widgets: Next class (requires schedule feature), Upcoming assignments/homeworks/tests, Today's summary, Future-work list, Quick-add button.

- Subject Detail
  - Shows list of items for the subject with filter/sort and add item button.

- Create / Edit Item
  - Fields: Title, Type (Assignment/Homework/Test), Subject (select), Origin (who assigned it), Description, Due date, Priority, Optional attachments. Tests include a numeric "weight" field representing % contribution to final grade.

- Item Detail
  - View/edit fields, mark complete, set reminders, attach files.

- Calendar view
  - Day/week calendar highlighting items and a future-work list.

Notes
- Onboarding should be shown on first launch and be skippable.
- Dashboard's "Next class" requires modeling class schedules/times per subject; confirm if this should be included in MVP (question below).



MVP Screens Count

For the MVP, estimated screens needed: 8

1. Onboarding (container with 3 swipe pages)
2. Dashboard
3. Subjects List (shows all subjects and summary info: notes, upcoming assignments/tests/homeworks)
4. Create Subject (form to add a subject, including schedule optional fields)
5. Subject Detail (list of items per subject and subject notes)
6. Create/Edit Item (form for assignments/homework/tests; choose subject, origin, description; tests have weight)
7. Item Detail (view and edit an item; mark complete; set reminders)
8. Calendar View (day/week view and future-work list)

Notes: Onboarding can be a single screen container with three pages; Create forms can be modal bottom sheets or full screens depending on UX.

---

Saved plan created by Copilot CLI.

## Project Architecture

- Architecture style: layered, feature-first Flutter app with clear separation of concerns.
- Layers:
  - **Presentation**: Screens, widgets, navigation, theming, and user-facing components.
  - **Application / State**: Riverpod providers/notifiers that coordinate UI events, validation, and use case execution.
  - **Domain**: Pure Dart models (Subject, Item, etc.) and business rules (e.g., deriving upcoming work, simple grade/weight calculation).
  - **Data**: Repository interfaces and implementations for local DB (Hive or sqflite) and optional remote sync (Firebase).
- Feature modules (each has `presentation`, `application`, `domain`, `data` as needed):
  - **onboarding** — first-launch flow and persisted "seen" flag.
  - **dashboard** — today/this week summary, upcoming assignments/tests, future-work list.
  - **subjects** — subject list, creation/editing, schedule metadata.
  - **items** — assignments/homeworks/tests CRUD, completion state, reminders.
  - **calendar** — date-based views into items and filters.
- Cross-cutting concerns:
  - **core/theme**: Colors, typography, shapes, dark theme configuration.
  - **core/routing**: App routes (onboarding, dashboard, subjects, calendar, item detail, etc.).
  - **core/widgets**: Shared UI components (buttons, cards, chips, list tiles, empty states).
  - **core/storage**: Abstractions for secure storage/preferences and database initialization.

## Proposed Repository and App File Tree

```text
ScholarFlux/
  Copilot/
    Context/
      Reference.png
  mobile/
    pubspec.yaml
    analysis_options.yaml
    lib/
      main.dart
      app.dart
      core/
        routing/
          app_router.dart
        theme/
          app_theme.dart
          colors.dart
          typography.dart
        widgets/
          primary_button.dart
          card_shell.dart
          empty_state.dart
        storage/
          local_db.dart
          app_preferences.dart
      features/
        onboarding/
          presentation/
            onboarding_screen.dart
          application/
            onboarding_controller.dart
        dashboard/
          presentation/
            dashboard_screen.dart
          application/
            dashboard_controller.dart
        subjects/
          domain/
            subject.dart
          data/
            subject_repository.dart
            local_subject_datasource.dart
          presentation/
            subjects_screen.dart
            edit_subject_screen.dart
          application/
            subjects_controller.dart
        items/
          domain/
            item.dart
            item_type.dart
          data/
            item_repository.dart
            local_item_datasource.dart
          presentation/
            edit_item_screen.dart
            item_detail_screen.dart
          application/
            items_controller.dart
        calendar/
          presentation/
            calendar_screen.dart
          application/
            calendar_controller.dart
      data/
        repositories/
          hive_subject_repository.dart
          hive_item_repository.dart
        local/
          hive_adapters.dart
    test/
      core/
      features/
        subjects/
        items/
        calendar/

  docs/
    product/
      mvp-plan.md        # Optional: deeper product notes, user stories
      user-flows.md      # Optional: flows for onboarding, subject/item lifecycle
```

> Note: The `mobile/` folder does not exist yet; it will be created when the Flutter app is scaffolded (milestone: `create-flutter-app`).

## 1-Week MVP Execution Plan (1 hour/day)

High-level mapping: the existing milestones (`create-flutter-app`, `ui-layout-reference`, `subjects-model`, `subject-crud`, `item-crud`, `storage-architecture`, `styling-theme`, `calendar-integration`, `ios-android-build`, `tests-and-docs`) are spread across seven focused daily sessions of ~60 minutes each.

### Day 1 — Setup & Architecture (≈60 min)
- 10 min — Re-read this plan, answer open questions Q1–Q5 at least at a "good enough" level (e.g., choose Riverpod, Hive, local-first only for now).
- 35 min — Run `flutter create` inside `mobile/` with proper bundle ID, clean up boilerplate, and set up `core/` + `features/` folder structure.
- 15 min — Implement `app_router.dart` with stub routes for onboarding, dashboard, subjects list, subject detail, item detail, and calendar; commit.

### Day 2 — Theming & Navigation Shell (≈60 min)
- 10 min — Define core color palette and typography in `core/theme/` based on Reference.png.
- 35 min — Wire up `main.dart` and `app.dart` to use the theme, Riverpod providers, and router; create basic scaffold layouts for dashboard, subjects list, and calendar screens (static content).
- 15 min — Quick manual run on simulator/emulator (iOS/Android) to validate navigation and theme; adjust any obvious UX issues.

### Day 3 — Domain Models & Local Storage Skeleton (≈60 min)
- 15 min — Implement `Subject` and `Item` domain models (with types: Assignment, Homework, Test) plus simple helpers (e.g., isOverdue, isUpcoming).
- 30 min — Choose local DB (e.g., Hive), add dependency, create adapters, and define repository interfaces for subjects/items.
- 15 min — Create basic Riverpod providers for repositories and mock implementations that return in-memory data to unblock UI work.

### Day 4 — Subject CRUD (≈60 min)
- 15 min — Implement `subjects_controller.dart` with state (list of subjects, loading, error) and actions (load, add, update, delete).
- 30 min — Build Subjects List and Edit Subject screens hooked up to the controller and repository; allow creating/editing/deleting subjects locally.
- 15 min — Manual test on device/simulator, capturing any UX friction for later polish.

### Day 5 — Item CRUD (≈60 min)
- 15 min — Implement `items_controller.dart` with filters for upcoming/overdue and per-subject views.
- 30 min — Build Edit Item and Item Detail screens with validation, linking items to subjects, and persistence via item repository.
- 15 min — Connect dashboard summary widgets to items/subjects providers to show simple "next due" and "upcoming" lists.

### Day 6 — Calendar & Future-Work View (≈60 min)
- 15 min — Implement a minimal calendar/day view component that can display items by due date (can be a custom list grouped by date if full calendar is too heavy).
- 30 min — Wire calendar and future-work list to item data, ensuring the UX matches the spirit of Reference.png.
- 15 min — Performance/UX pass: check scroll behavior, empty states, and error handling.

### Day 7 — Polish, Tests & Packaging (≈60 min)
- 20 min — Add a small set of unit tests (models, simple repository logic) and one or two widget tests (subject list, item form) to validate key flows.
- 20 min — Implement basic onboarding flow (even a simple single-screen first-launch gate) and ensure it's connected to storage.
- 20 min — Prepare builds for iOS and Android (icons, app name, bundle IDs), update README with run instructions, and make a final manual QA pass through core flows.

### Time Management Pattern for Each 1-Hour Session
- 5–10 min — Plan: review previous progress, update todos, and choose the single most important outcome for the session.
- 40–45 min — Focused implementation: keep scope tight, defer nice-to-haves, and avoid refactors that are not directly tied to the day's goal.
- 5–10 min — Wrap-up: run the app/tests, note any regressions or follow-ups in the plan, and commit with a clear message.
