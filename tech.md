# ScholarFlux — Technical Documentation

A Flutter mobile app for students to manage subjects, assignments, tests, homework, class schedules, and grades. Built with a **Liquid Glass** dark UI theme, **Riverpod** for state management, **Hive** for local persistence, and **GoRouter** for declarative navigation.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Entry Point & App Shell](#entry-point--app-shell)
3. [Core Layer](#core-layer)
   - [Local Database (Hive)](#local-database-hive)
   - [App Preferences](#app-preferences)
   - [Routing](#routing)
   - [Navigation Shell](#navigation-shell)
   - [Theme & Colors](#theme--colors)
   - [Typography](#typography)
   - [Animations](#animations)
   - [Glass Container](#glass-container)
   - [Glass Helpers (Confirm Dialog)](#glass-helpers-confirm-dialog)
4. [Data Layer — Hive Repositories](#data-layer--hive-repositories)
   - [HiveSubjectRepository](#hivesubjectrepository)
   - [HiveItemRepository](#hiveitemrepository)
   - [HiveClassRepository](#hiveclassrepository)
5. [Feature: Subjects](#feature-subjects)
   - [Subject Domain Model](#subject-domain-model)
   - [SubjectDomain (Grading Domain)](#subjectdomain-grading-domain)
   - [SubjectRepository (Abstract)](#subjectrepository-abstract)
   - [SubjectsController (Riverpod)](#subjectscontroller-riverpod)
   - [SubjectsScreen](#subjectsscreen)
   - [SubjectDetailScreen](#subjectdetailscreen)
   - [EditSubjectScreen](#editsubjectscreen)
6. [Feature: Items (Assignments / Homework / Tests)](#feature-items)
   - [Item Domain Model](#item-domain-model)
   - [ItemType / ItemPriority / ItemStatus Enums](#itemtype--itempriority--itemstatus-enums)
   - [ItemRepository (Abstract)](#itemrepository-abstract)
   - [ItemsController (Riverpod)](#itemscontroller-riverpod)
   - [EditItemScreen](#edititemscreen)
   - [ItemDetailScreen](#itemdetailscreen)
7. [Feature: Dashboard](#feature-dashboard)
8. [Feature: Calendar](#feature-calendar)
9. [Feature: Classes (Schedule)](#feature-classes-schedule)
   - [ClassEntry Domain Model](#classentry-domain-model)
   - [ClassRepository (Abstract)](#classrepository-abstract)
   - [ClassesController (Riverpod)](#classescontroller-riverpod)
   - [ScheduleScreen](#schedulescreen)
   - [EditClassScreen](#editclassscreen)
10. [Feature: Onboarding](#feature-onboarding)

---

## Architecture Overview

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp.router setup
├── core/
│   ├── storage/                 # Hive initialization & preferences
│   ├── routing/                 # GoRouter config & NavShell
│   ├── theme/                   # Colors, typography, ThemeData
│   └── widgets/                 # Reusable glass UI components & animations
├── data/
│   └── repositories/            # Hive-backed repository implementations
└── features/
    ├── subjects/                # Subject CRUD, domain averages
    ├── items/                   # Assignment/homework/test management
    ├── classes/                 # Weekly class schedule
    ├── dashboard/               # Home screen aggregating data
    ├── calendar/                # Monthly calendar with item dots
    └── onboarding/              # First-launch walkthrough
```

**Patterns used:**
- **Feature-first folder structure**: Each feature has `domain/`, `data/`, `application/`, and `presentation/` subfolders.
- **Repository pattern**: Abstract interfaces in `data/`, Hive implementations in `data/repositories/`.
- **Riverpod `AsyncNotifier`**: Controllers wrap repositories and expose reactive state.
- **Immutable domain models**: All models are `@immutable` with `copyWith`, `toMap`, and `fromMap`.

---

## Entry Point & App Shell

### `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.init();
  runApp(const ProviderScope(child: ScholarFluxApp()));
}
```

**Logic:**
1. Ensures Flutter binding is ready (needed for async operations before `runApp`).
2. Calls `LocalDb.init()` to initialize Hive and open all four boxes (`subjects`, `items`, `classes`, `preferences`).
3. Wraps the app in `ProviderScope` so all Riverpod providers are available throughout the widget tree.

### `app.dart` — `ScholarFluxApp`

```dart
class ScholarFluxApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ScholarFlux',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: goRouter,
    );
  }
}
```

Uses `MaterialApp.router` to integrate with GoRouter's declarative routing. The theme is forced to `AppTheme.dark` (Liquid Glass dark mode).

---

## Core Layer

### Local Database (Hive)

**File:** `core/storage/local_db.dart`

```dart
class LocalDb {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(subjectsBoxName);   // 'subjects'
    await Hive.openBox<Map>(itemsBoxName);       // 'items'
    await Hive.openBox<Map>(classesBoxName);     // 'classes'
    await Hive.openBox(preferencesBoxName);       // 'preferences'
  }

  static Box<Map> get subjectsBox => Hive.box<Map>(subjectsBoxName);
  static Box<Map> get itemsBox    => Hive.box<Map>(itemsBoxName);
  static Box<Map> get classesBox  => Hive.box<Map>(classesBoxName);
  static Box get preferencesBox   => Hive.box(preferencesBoxName);
}
```

**Logic:**
- Initializes Hive with Flutter's document directory via `Hive.initFlutter()`.
- Opens four named boxes. The first three store `Map` values (serialized domain objects), the fourth stores arbitrary key-value preferences.
- Static getters provide singleton access to each box throughout the app.

---

### App Preferences

**File:** `core/storage/app_preferences.dart`

```dart
class AppPreferences {
  static Box get _box => LocalDb.preferencesBox;
  static const String _onboardingSeenKey = 'onboarding_seen';

  static bool get hasSeenOnboarding =>
      _box.get(_onboardingSeenKey, defaultValue: false) as bool;

  static Future<void> setOnboardingSeen() async {
    await _box.put(_onboardingSeenKey, true);
  }
}
```

**Logic:** A simple wrapper around the preferences Hive box. Currently tracks only whether the onboarding screen has been shown. Uses `defaultValue: false` so the first launch returns `false`.

---

### Routing

**File:** `core/routing/app_router.dart`

**GoRouter configuration** with a `StatefulShellRoute.indexedStack` for the four bottom tabs:

| Tab Index | Path | Screen |
|-----------|------|--------|
| 0 | `/dashboard` | `DashboardScreen` |
| 1 | `/subjects` | `SubjectsScreen` (with nested routes) |
| 2 | `/calendar` | `CalendarScreen` |
| 3 | `/schedule` | `ScheduleScreen` (with nested routes) |

**Key nested routes under `/subjects`:**

```
/subjects/new                         → EditSubjectScreen (create)
/subjects/:subjectId                  → SubjectDetailScreen
/subjects/:subjectId/edit             → EditSubjectScreen (edit)
/subjects/:subjectId/items/new        → EditItemScreen (create)
/subjects/:subjectId/items/:itemId    → ItemDetailScreen
/subjects/:subjectId/items/:itemId/edit → EditItemScreen (edit)
```

**Key nested routes under `/schedule`:**

```
/schedule/new                → EditClassScreen (create)
/schedule/:classId/edit      → EditClassScreen (edit)
```

**Page transition — `_fadeSlide`:**

```dart
CustomTransitionPage<void> _fadeSlide(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}
```

**Logic:** Combines a fade-in with a subtle 4% horizontal slide from the right, using an `easeOutCubic` curve for a smooth iOS-like feel. Applied to all detail/edit pages via `pageBuilder`.

---

### Navigation Shell

**File:** `core/routing/nav_shell.dart`

```dart
class NavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  // ...
}
```

**Logic:**
- Receives GoRouter's `StatefulNavigationShell` to preserve tab state across navigation.
- Renders a **floating bottom navigation bar** with a frosted glass effect:
  - `BackdropFilter` with `blur(sigmaX: 30, sigmaY: 30)` blurs the content behind the bar.
  - Gradient fill from 10% → 5% white creates the translucent glass look.
  - 4 tabs: Dashboard, Subjects, Calendar, Schedule (icons + labels).
  - `navigationShell.goBranch(index)` switches tabs while preserving each tab's navigation stack.
  - A specular highlight line at the top edge simulates light reflection on glass.

---

### Theme & Colors

**File:** `core/theme/colors.dart`

```dart
abstract final class AppColors {
  static const Color scaffoldBg     = Color(0xFF0A0A0F);   // Near-black
  static const Color surfaceCard    = Color(0xFF1A1A1F);   // Dark card
  static const Color glassFill      = Color(0x1AFFFFFF);   // 10% white
  static const Color glassBorder    = Color(0x1AFFFFFF);   // 10% white
  static const Color glassHighlight = Color(0x0DFFFFFF);   // 5% white
  static const Color primary        = Color(0xFF5A8AF2);   // Blue accent
  static const Color primaryGlow    = Color(0x335A8AF2);   // 20% primary
  static const Color error          = Color(0xFFFF453A);   // Red
  static const Color success        = Color(0xFF30D158);   // Green
  static const Color warning        = Color(0xFFFFD60A);   // Yellow
  // ... text colors, chip colors, dividers
}
```

**Logic:** All colors are static constants in an abstract final class (cannot be instantiated). The palette follows Apple's dark mode conventions with Liquid Glass translucency.

**File:** `core/theme/app_theme.dart`

```dart
abstract final class AppTheme {
  static ThemeData get dark { ... }
}
```

**Logic:** Assembles a complete Material 3 dark `ThemeData` applying glass-style defaults to:
- `CardTheme` — glass fill, no elevation, rounded corners, thin border
- `AppBarTheme` — fully transparent background
- `InputDecorationTheme` — glass-filled fields with rounded borders
- `ChipThemeData` — rounded pills with primary selection color
- `FloatingActionButtonTheme` — primary blue, rounded
- `DialogTheme` — dark glass dialog with rounded corners

---

### Typography

**File:** `core/theme/typography.dart`

```dart
abstract final class AppTypography {
  static const TextStyle headerLarge  = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, ...);
  static const TextStyle headerAccent = TextStyle(fontSize: 28, color: AppColors.primary, ...);
  static const TextStyle sectionTitle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, ...);
  static const TextStyle cardTitle    = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, ...);
  static const TextStyle cardSubtitle = TextStyle(fontSize: 13, color: AppColors.textSecondary, ...);
  static const TextStyle badge        = TextStyle(fontSize: 14, color: AppColors.primary, ...);
  static const TextStyle body         = TextStyle(fontSize: 15, ...);
  static const TextStyle caption      = TextStyle(fontSize: 11, color: AppColors.textSecondary, ...);
  // ... dateLabel, calendarDay, chip
}
```

**Logic:** Static text styles used consistently across all screens. Each style specifies size, weight, color, and optional letter-spacing/height for pixel-perfect layouts.

---

### Animations

**File:** `core/widgets/animations.dart`

#### `AnimatedListItem`

```dart
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;        // default: 350ms
  final Duration staggerDelay;    // default: 50ms
}
```

**Logic:**
1. Creates an `AnimationController` on `initState`.
2. After a staggered delay (`staggerDelay * index`), starts a combined **fade-in** (opacity 0→1 with `easeOut`) and **slide-up** (offset `(0, 0.08)` → `(0, 0)` with `easeOutCubic`).
3. Each item in a list waits an extra 50ms per index, creating a cascading entrance effect.
4. The controller is disposed in `dispose()` to avoid memory leaks.

#### `TapScale`

```dart
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;  // default: 0.97
}
```

**Logic:**
- On `tapDown`, animates the child to 97% scale (100ms, `easeInOut`).
- On `tapUp` or `tapCancel`, reverses to 100% (200ms).
- Creates an iOS-like "press in" micro-interaction.
- Used by `GlassContainer` when `onTap` is provided.

#### `FadeInWidget`

```dart
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;  // default: 400ms
  final Duration delay;     // default: 0
}
```

**Logic:** Simple fade-in using an `AnimationController`. If `delay > 0`, waits before starting. Uses `easeOut` curve. Useful for screen-level entrance animations.

---

### Glass Container

**File:** `core/widgets/glass_container.dart`

```dart
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;    // default: 20
  final double blurSigma;       // default: 24
  final Color? fillColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
}
```

**Logic:**
1. **ClipRRect** clips the container to rounded corners.
2. **BackdropFilter** applies a Gaussian blur (`sigma: 24`) to whatever is behind it — creating the frosted glass effect.
3. Inner **Container** has a diagonal `LinearGradient` fill (12% → 6% of the fill color) with a thin 0.5px border.
4. A **Positioned** specular highlight (1px tall gradient line) is overlaid at the top edge to simulate light reflection.
5. If `onTap` or `onLongPress` is provided, the container is wrapped in `TapScale` for the press animation.
6. If `margin` is provided, wrapped in a `Padding`.

This is the primary card/container widget used across all screens.

---

### Glass Helpers (Confirm Dialog)

**File:** `core/widgets/glass_helpers.dart`

```dart
Future<bool?> showGlassConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Delete',
  Color? confirmColor,
})
```

**Logic:**
1. Shows a modal dialog with `showDialog<bool>`.
2. Outer `BackdropFilter` blurs the entire screen behind the dialog (`sigma: 12`).
3. Inner content is a double-blurred glass card (`sigma: 30`) with the same gradient + border treatment as `GlassContainer`.
4. A specular highlight is rendered at the top center.
5. Cancel button returns `false`, confirm button returns `true`.
6. Confirm text color defaults to `AppColors.error` (red) but can be overridden.

Used for delete confirmations throughout the app.

---

## Data Layer — Hive Repositories

All three repositories follow the same pattern: they implement an abstract interface, access a typed Hive box, and convert between `Map` and domain models.

### HiveSubjectRepository

**File:** `data/repositories/hive_subject_repository.dart`

```dart
class HiveSubjectRepository implements SubjectRepository {
  Box<Map> get _box => LocalDb.subjectsBox;

  Future<List<Subject>> getAll() async {
    return _box.values
        .map((map) => Subject.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<Subject?> getById(String id) async {
    final map = _box.get(id);
    if (map == null) return null;
    return Subject.fromMap(Map<String, dynamic>.from(map));
  }

  Future<void> add(Subject subject) async => await _box.put(subject.id, subject.toMap());
  Future<void> update(Subject subject) async => await _box.put(subject.id, subject.toMap());
  Future<void> delete(String id) async => await _box.delete(id);
}
```

**Logic:** `getAll()` sorts subjects by `updatedAt` descending (most recently modified first). Uses `Map<String, dynamic>.from(map)` to convert Hive's internal `_$Map` to a clean type-safe map for the `fromMap` factory.

### HiveItemRepository

**File:** `data/repositories/hive_item_repository.dart`

**Logic:** Same Hive pattern with custom sorting:
- Pending items come before completed items (`status.index` comparison).
- Within the same status, sorted by `dueDate` ascending (earliest due first).
- Items with no due date are pushed to the end.

Additional method:

```dart
Future<void> deleteBySubjectId(String subjectId) async {
  final keys = _box.keys.where((key) {
    final map = _box.get(key);
    return map?['subjectId'] == subjectId;
  }).toList();
  for (final key in keys) {
    await _box.delete(key);
  }
}
```

**Logic:** Iterates all box entries, finds keys whose `subjectId` matches, and deletes them. This is called when a subject is deleted to cascade-delete its items.

### HiveClassRepository

**File:** `data/repositories/hive_class_repository.dart`

**Logic:** Same Hive pattern with `compareTo` sorting (by `startTime` string comparison, which works for `HH:mm` format). Additional query methods:
- `getBySubjectId(subjectId)` — filters all classes for a given subject.
- `getByDayOfWeek(dayOfWeek)` — filters all classes for a given weekday.
- `deleteBySubjectId(subjectId)` — cascade-deletes classes when a subject is removed.

---

## Feature: Subjects

### Subject Domain Model

**File:** `features/subjects/domain/subject.dart`

```dart
class Subject {
  final String id;
  final String name;
  final String? room;
  final List<SubjectDomain> domains;
  final double maxGrade;        // grading ceiling (e.g. 20, 100)
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### `domainAverages(List<Item> items) → Map<String, double>`

```dart
Map<String, double> domainAverages(List<Item> items) {
  final result = <String, double>{};
  for (final domain in domains) {
    final domainItems = items.where((i) => i.domainId == domain.id && i.grade != null);
    if (domainItems.isEmpty) continue;
    final sum = domainItems.fold<double>(0, (s, i) => s + i.grade!);
    result[domain.id] = sum / domainItems.length;
  }
  return result;
}
```

**Logic:** For each domain, collects all graded items belonging to that domain, sums their grades, and divides by count to get the arithmetic mean. Domains with no graded items are excluded from the result.

#### `averageGrade(List<Item> items) → double?`

```dart
double? averageGrade(List<Item> items) {
  if (domains.isEmpty) {
    // No domains: simple average of all graded items
    final graded = items.where((i) => i.grade != null).toList();
    if (graded.isEmpty) return null;
    return graded.fold<double>(0, (s, i) => s + i.grade!) / graded.length;
  }
  final avgs = domainAverages(items);
  if (avgs.isEmpty) return null;
  double totalWeight = 0, weightedSum = 0;
  for (final domain in domains) {
    final avg = avgs[domain.id];
    if (avg != null) {
      weightedSum += avg * domain.weight;
      totalWeight += domain.weight;
    }
  }
  if (totalWeight == 0) return null;
  return weightedSum / totalWeight;
}
```

**Logic:**
- **No domains defined:** Falls back to a simple arithmetic mean of all graded items.
- **With domains:** Computes a weighted average: `Σ(domain_avg × domain_weight) / Σ(domain_weight)`. Only domains that have graded items contribute. Returns `null` if no grades exist.

### SubjectDomain (Grading Domain)

```dart
class SubjectDomain {
  final String id;
  final String name;
  final double weight;  // percentage, e.g. 60.0 for 60%
}
```

**Logic:** Represents a grading domain within a subject (e.g., "Practical" 40%, "Theoretical" 60%). The `weight` field is a percentage used in the weighted average calculation.

### SubjectRepository (Abstract)

```dart
abstract class SubjectRepository {
  Future<List<Subject>> getAll();
  Future<Subject?> getById(String id);
  Future<void> add(Subject subject);
  Future<void> update(Subject subject);
  Future<void> delete(String id);
}
```

**Logic:** Defines the contract for subject persistence. Implemented by `HiveSubjectRepository`.

### SubjectsController (Riverpod)

**File:** `features/subjects/application/subjects_controller.dart`

```dart
final subjectsProvider = AsyncNotifierProvider<SubjectsNotifier, List<Subject>>(...);

class SubjectsNotifier extends AsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() => _repo.getAll();

  Future<void> addSubject({...}) async { ... }
  Future<void> updateSubject(Subject subject) async { ... }
  Future<void> deleteSubject(String id) async { ... }
}
```

**Logic:**
- `build()` loads all subjects on first access.
- `addSubject()` creates a new `Subject` with a generated ID (microsecond timestamp in base-36), persists it, and calls `ref.invalidateSelf()` to refresh all watchers.
- `updateSubject()` stamps a new `updatedAt`, persists, and invalidates.
- `deleteSubject()` removes from Hive and invalidates.
- `_generateId()` uses `DateTime.now().microsecondsSinceEpoch.toRadixString(36)` for compact unique IDs.

**Additional providers:**

```dart
final subjectByIdProvider = FutureProvider.family<Subject?, String>((ref, id) async {
  return ref.watch(subjectRepositoryProvider).getById(id);
});
```

### SubjectsScreen

**Logic:**
- Watches `subjectsProvider` for the list of subjects.
- Shows a date header (`_SubjectsHeader`) with "Month Day, Weekday" format.
- Renders `_SubjectCard` widgets in a `SliverList` with `AnimatedListItem` for staggered entrance.
- Empty state shows an icon + "No subjects yet" message.
- FAB navigates to `new-subject`.

**`_SubjectCard`:** Watches `itemsBySubjectProvider` to display the weighted average (`_MediaBadge`) and per-domain scores (`_DomainScoresRow`). Tapping navigates to `subject-detail`.

### SubjectDetailScreen

**Logic:**
- Watches both `subjectByIdProvider` and `itemsBySubjectProvider`.
- Shows a header card with subject name, average grade, and domain weight percentages.
- Lists all items as `_ItemTile` widgets with status icons (✓ for completed, ⚠ for overdue, ○ for pending).
- Each tile shows: title, type, due date, grade badge, domain name, and weight percentage.
- AppBar actions: Edit (navigates to `edit-subject`) and Delete (shows glass confirm dialog, then cascade-deletes items + subject).

### EditSubjectScreen

**Logic:**
- `ConsumerStatefulWidget` with form fields: name (required), room (optional), max grade (default 20).
- **Domains section:** Dynamic list of domain rows. Each row has a name field and a weight percentage field. Users can add (`_addDomain`) or remove (`_removeDomain`) domains.
- **Edit mode:** If `subjectId` is provided, loads existing subject data once (`_loadExisting` with `_loaded` guard).
- **Save logic:** Validates the form, builds domain list, warns if weights don't sum to 100% (shows glass confirm dialog), then either creates or updates the subject via `SubjectsNotifier`.

---

## Feature: Items

### Item Domain Model

**File:** `features/items/domain/item.dart`

```dart
class Item {
  final String id;
  final String subjectId;
  final String title;
  final ItemType type;
  final String description;
  final DateTime? dueDate;
  final ItemPriority priority;
  final ItemStatus status;
  final String? origin;       // who assigned it
  final double? weight;       // percentage weight (tests only)
  final double? grade;
  final String? domainId;     // links to SubjectDomain
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### Computed properties:

```dart
bool get isOverdue =>
    status == ItemStatus.pending &&
    dueDate != null &&
    dueDate!.isBefore(DateTime.now());

bool get isUpcoming =>
    status == ItemStatus.pending &&
    dueDate != null &&
    dueDate!.isAfter(DateTime.now()) &&
    dueDate!.difference(DateTime.now()).inDays <= 7;

bool get isCompleted => status == ItemStatus.completed;
```

**Logic:**
- `isOverdue`: Pending item whose due date has already passed.
- `isUpcoming`: Pending item due within the next 7 days.
- `isCompleted`: Status is `completed`.

### ItemType / ItemPriority / ItemStatus Enums

```dart
enum ItemType { assignment, homework, test }
enum ItemPriority { low, medium, high }
enum ItemStatus { pending, completed }
```

Each enum has a `label` getter returning a human-readable string. `ItemType.fromString()` parses case-insensitively with a fallback to `assignment`.

### ItemRepository (Abstract)

```dart
abstract class ItemRepository {
  Future<List<Item>> getAll();
  Future<List<Item>> getBySubjectId(String subjectId);
  Future<Item?> getById(String id);
  Future<void> add(Item item);
  Future<void> update(Item item);
  Future<void> delete(String id);
  Future<void> deleteBySubjectId(String subjectId);
}
```

### ItemsController (Riverpod)

**File:** `features/items/application/items_controller.dart`

**Core notifier methods:**

- `addItem(...)`: Creates an `Item` with generated ID, persists, invalidates.
- `updateItem(Item)`: Stamps `updatedAt`, persists, invalidates.
- `deleteItem(String id)`: Removes from Hive, invalidates.
- `toggleComplete(Item)`: Flips `pending ↔ completed` status.
- `deleteItemsBySubject(String subjectId)`: Cascade-deletes all items for a subject.

**Derived providers (all auto-refresh when `itemsProvider` changes):**

| Provider | Logic |
|----------|-------|
| `itemsBySubjectProvider(subjectId)` | Filters items by `subjectId` |
| `itemByIdProvider(id)` | Fetches single item by ID |
| `upcomingItemsProvider` | Items where `isUpcoming == true` |
| `overdueItemsProvider` | Items where `isOverdue == true` |
| `futureItemsProvider` | Pending items with due date > 7 days from now |
| `itemsByMonthProvider((year, month))` | Items due in a given month, sorted by date |
| `itemsByDateProvider(date)` | Items due on a specific date, sorted by date |

### EditItemScreen

**Logic:**
- Form fields: title (required), type (chip selector), description, due date (date picker), origin, priority (dropdown), domain (dropdown from subject's domains), grade, weight (only for tests).
- **Grade locking:** If a due date is set in the future, the grade field is disabled with a lock icon and hint text "Grade (available after due date)".
- **Edit mode:** Loads existing item data into controllers via `_loadExisting`.
- **Save:** Validates, then creates or updates via `ItemsNotifier`.

### ItemDetailScreen

**Logic:**
- Shows a header card with title, grade badge, and domain info.
- A list of `_DetailRow` widgets for type, due date, priority, status, origin, grade, weight.
- Description section shown if non-empty.
- AppBar edit button navigates to `edit-item`, delete button shows glass confirm dialog.

---

## Feature: Dashboard

**File:** `features/dashboard/presentation/dashboard_screen.dart`

**Logic:**
- Watches four providers: `upcomingItemsProvider`, `futureItemsProvider`, `subjectsProvider`, `todayClassesProvider`.
- Builds a subject name lookup map from the subjects list.

**Sections (top to bottom):**

1. **Date Header (`_DateHeader`)**: Displays "Month Day, Weekday" with the weekday in primary color using `RichText`.

2. **Weekday Chips (`_WeekdayChips`)**: Row of Mon–Fri chips; today's weekday is highlighted. Non-interactive (display only).

3. **Classes Section**: Today's classes from `todayClassesProvider`. Each card shows start/end time on the left, a blue vertical divider, and the subject name + location on the right. Uses `GlassContainer` with `AnimatedListItem` stagger.

4. **Upcoming Section**: Items due within 7 days. Each `_ItemCard` shows title, type badge, subject name, due date, and optional grade badge. Tapping navigates to `item-detail`.

5. **Future Work Section**: Items due beyond 7 days. Same `_ItemCard` layout.

**`_PlaceholderCard`:** Shown when a section has no data — glass container with centered icon and message.

**`_TypeBadge`:** Small pill showing the item type label (Assignment/Homework/Test).

---

## Feature: Calendar

**File:** `features/calendar/presentation/calendar_screen.dart`

**Logic:**

**State:**
- `_selectedMonth` and `_selectedYear` (default: current month/year).
- `_selectedDay` — nullable; set when user taps a day cell.

**Sections:**

1. **Date Header**: Same "Month Day, Weekday" style as dashboard.

2. **Month Chips**: Horizontal scrollable `ListView` of Jan–Dec chips. Tapping changes `_selectedMonth` and clears `_selectedDay`.

3. **Weekday Headers**: Row of Mon–Sun labels.

4. **Calendar Grid (`_CalendarGrid`):**
   ```dart
   // Calculates leading empty cells for the first week
   for (var i = 1; i < firstWeekday; i++) {
     cells.add(const SizedBox(width: 36, height: 36));
   }
   ```
   - Each day cell is 36×36.
   - **Today** gets a blue circular background.
   - **Selected day** gets a blue circular border.
   - **Days with items** have primary-colored text with bold weight.
   - `Wrap` widget handles automatic row breaking at 7 columns.
   - Spacing is calculated dynamically: `(screenWidth - 32 - 7*36) / 6`.

5. **Selected Day Items**: If a day is tapped, shows items due on that date using `itemsByDateProvider`.

6. **Future Work Section**: Lists all items in the selected month using `itemsByMonthProvider`, displayed as `_FutureWorkTile` rows with title, subject name, and formatted date.

**`_FutureWorkTile._formatDate`:** Formats as `DD/MM/YY` with zero-padding.

---

## Feature: Classes (Schedule)

### ClassEntry Domain Model

**File:** `features/classes/domain/class_entry.dart`

```dart
class ClassEntry {
  final String id;
  final String subjectId;
  final int dayOfWeek;      // 1 = Monday .. 7 = Sunday
  final String startTime;   // "HH:mm"
  final String endTime;     // "HH:mm"
  final String? room;
  final String? floor;
  final String? teacher;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### Computed properties:

```dart
int compareTo(ClassEntry other) => startTime.compareTo(other.startTime);
```
Sorts by start time lexicographically (works because `HH:mm` format is zero-padded).

```dart
String get timeRange => '$startTime – $endTime';

String? get location {
  final parts = <String>[];
  if (room != null && room!.isNotEmpty) parts.add('Room $room');
  if (floor != null && floor!.isNotEmpty) parts.add('Floor $floor');
  return parts.isEmpty ? null : parts.join(', ');
}
```

**Logic:** `location` combines room and floor into a single display string. Returns `null` if both are empty.

### ClassRepository (Abstract)

```dart
abstract class ClassRepository {
  Future<List<ClassEntry>> getAll();
  Future<ClassEntry?> getById(String id);
  Future<List<ClassEntry>> getBySubjectId(String subjectId);
  Future<List<ClassEntry>> getByDayOfWeek(int dayOfWeek);
  Future<void> add(ClassEntry entry);
  Future<void> update(ClassEntry entry);
  Future<void> delete(String id);
  Future<void> deleteBySubjectId(String subjectId);
}
```

### ClassesController (Riverpod)

**Core notifier methods:** `addClass`, `updateClass`, `deleteClass`, `deleteClassesBySubject` — same pattern as other controllers.

**Derived providers:**

| Provider | Logic |
|----------|-------|
| `classesByDayProvider(dayOfWeek)` | All classes on a given weekday, sorted by start time |
| `classesBySubjectProvider(subjectId)` | All classes for a subject, sorted by start time |
| `todayClassesProvider` | Classes matching `DateTime.now().weekday`, sorted |
| `classByIdProvider(id)` | Single class lookup by ID |

### ScheduleScreen

**Logic:**
- Watches `classesProvider` and `subjectsProvider`.
- Groups classes by `dayOfWeek` into a `Map<int, List<ClassEntry>>`.
- Sorts days numerically and classes within each day by start time.
- Renders weekday headers (`ClassEntry.weekdayLabels[day]`) followed by `_ClassTile` cards.

**`_ClassTile`:** Glass container showing:
- Left column: start time (bold) and end time (subtle).
- Blue vertical divider bar (3px wide, 36px tall).
- Right column: subject name, room · teacher info.
- Chevron icon on the far right.
- `onTap` navigates to `edit-class`, `onLongPress` triggers delete confirmation.

### EditClassScreen

**Logic:**
- Subject picker: `DropdownButtonFormField` populated from `subjectsProvider`. Required field.
- Day of week: 7 `ChoiceChip` widgets (Mon–Sun).
- Time pickers: Two `GestureDetector` → `InputDecorator` widgets that open a custom `_TimeWheelPicker` in a modal bottom sheet.
- Room, floor, teacher: Optional text fields.
- **Validation:** Start time must be before end time (compared as formatted strings).
- **Save:** Creates or updates via `ClassesNotifier`.

**`_TimeWheelPicker`:**

```dart
class _TimeWheelPicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;
}
```

**Logic:** Two `ListWheelScrollView` widgets side by side (hours 0–23, minutes 0–59) with `FixedExtentScrollPhysics` for snap-to-item behavior. Selected items are highlighted with primary text color. The `onChanged` callback fires on every scroll, and the bottom sheet's "Done" button applies the selection to state.

---

## Feature: Onboarding

**File:** `features/onboarding/presentation/onboarding_screen.dart`

```dart
class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          children: const [
            _OnboardingPage(icon: ..., title: 'School life is chaotic', subtitle: ...),
            _OnboardingPage(icon: ..., title: 'ScholarFlux helps', subtitle: ...),
            _OnboardingPage(icon: ..., title: 'Get started', subtitle: ...),
          ],
        ),
      ),
    );
  }
}
```

**Logic:** A simple 3-page horizontal `PageView`. Each page (`_OnboardingPage`) centers an icon, title, and subtitle vertically. The user swipes between pages. Currently no "Skip" or "Get Started" button wired to `AppPreferences.setOnboardingSeen()`.
