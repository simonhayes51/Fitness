# ForgeFit 🔥

**All-in-One Gym & Nutrition Management App** — track workouts, dial in nutrition,
and watch your strength climb. Built with Flutter for beautiful, performant,
cross-platform (iOS + Android) experiences.

> _Forge your strongest self._

---

## 1. Project overview & tech-stack justification

ForgeFit is an **offline-first** fitness app with optional cloud sync. Every
feature works with no network connection; your data lives on-device in Hive and
can be mirrored to Firebase when configured.

| Concern | Choice | Why |
|---|---|---|
| **Framework** | Flutter + Dart | One codebase, 60fps UIs, Material 3, great charting & camera plugins. |
| **State management** | Riverpod (`flutter_riverpod`) | Compile-safe dependency injection, testable, no `BuildContext` coupling, easy to mock. |
| **Architecture** | Layered MVVM-ish: `models → repositories → providers (view-models) → screens` | Clear separation; UI never touches storage directly. |
| **Local persistence** | Hive | Fast, pure-Dart, no native deps; stores JSON-style maps so the schema stays flexible (no codegen needed to compile). |
| **Backend (optional)** | Firebase (Auth, Firestore, Storage, Messaging, Functions) | Managed auth (email/Google/Apple), realtime sync, push, serverless AI proxy. |
| **Navigation** | go_router | Declarative, deep-link ready, typed shell routes for the bottom-nav. |
| **Charts** | fl_chart | Lightweight, customisable line/bar charts for progress analytics. |
| **Barcode scanning** | mobile_scanner | Modern, performant ML-Kit-backed scanner for food logging. |
| **Notifications** | flutter_local_notifications + timezone | Rest timers, reminders, streak nudges — all local, no server required. |

## 2. Folder structure

```
lib/
├── main.dart                  # Boot: Hive init, seed, notifications, runApp
├── app.dart                   # MaterialApp.router, theming, localisation
├── core/                      # Cross-cutting, framework-level code
│   ├── constants/             # App constants + enums (goals, units, set types)
│   ├── router/                # go_router config (bottom-nav shell + routes)
│   ├── theme/                 # Colors, Material 3 dark/light themes
│   └── utils/                 # Pure helpers: calculations (1RM/TDEE), formatters
├── data/                      # The data layer
│   ├── models/                # Plain Dart models with toMap/fromMap
│   ├── repositories/          # CRUD + queries over the local store
│   └── services/              # Hive, seeding, notifications, food API, export, AI coach
├── features/                  # Feature-first UI modules (one folder per area)
│   ├── onboarding/            # First-launch profile setup
│   ├── dashboard/             # Home: rings, streak, coach tips
│   ├── workout/               # Routines, live logger, history
│   ├── exercises/             # 500+ library, detail, custom, picker
│   ├── nutrition/             # Diary, macros, water, food search, barcode
│   ├── progress/              # Charts: weight, volume, muscle split, goals
│   └── profile/               # Profile + settings
└── shared/
    ├── providers/             # Riverpod providers (DI + view-models)
    └── widgets/               # Reusable UI (cards, rings, macro bars, shell)

assets/data/                   # Seed catalogues (exercises.json, foods.json)
scripts/generate_exercises.py  # Regenerates the 500+ exercise dataset
docs/                          # Architecture, schema, Firebase setup, roadmap
test/                          # Unit tests (calculations covered)
```

## 3. Running the app

> Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
> (3.19+) and Dart 3.3+.

```bash
# 1. Generate the native iOS/Android/web platform folders for this project.
#    (They are intentionally not committed — this regenerates them in place.)
flutter create .

# 2. Fetch dependencies.
flutter pub get

# 3. Run on a connected device or emulator.
flutter run

# 4. Run the tests.
flutter test
```

The app runs **fully offline out of the box** — no API keys required. Barcode
food lookup uses the free [Open Food Facts](https://world.openfoodfacts.org/)
API (no key) and degrades gracefully when offline.

## 4. Database / models

See [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) for the full local Hive
box layout and the proposed Firestore document structure.

## 5. Extending the catalogues & adding keys

- **Add exercises:** edit `scripts/generate_exercises.py` and run
  `python3 scripts/generate_exercises.py`, or append objects directly to
  `assets/data/exercises.json` (matching the `Exercise` model). Users can also
  create custom exercises in-app.
- **Add foods:** append to `assets/data/foods.json`, or scan/log custom foods
  in-app. Barcode scans fall back to Open Food Facts and are cached locally.
- **Swap the food API / add keys:** all networking lives in
  `lib/data/services/food_api_service.dart`. Point it at Nutritionix / USDA and
  pass keys via `--dart-define` (never hard-code secrets).
- **Enable Firebase:** follow [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md).

## 6. Roadmap (v2+)

See [`docs/ROADMAP.md`](docs/ROADMAP.md) — AI coaching (Gemini/OpenAI),
Apple Health / Google Fit, wearables, social feed, recipe builder, and more.

---

### Feature checklist (v1 MVP)

- ✅ Onboarding with TDEE/macro calculation
- ✅ 500+ exercise library (searchable/filterable, lazy-loaded) + custom exercises
- ✅ Routine templates (presets + custom editor)
- ✅ Live workout logger: sets, weight, reps, RPE, set types (warm-up/drop/failure), supersets
- ✅ Auto rest timer with local notifications
- ✅ 1RM calculator, volume tracking, PRs, progressive-overload hints, per-exercise charts
- ✅ Nutrition diary with macro rings, water tracking, barcode scanning, custom foods
- ✅ Body-weight & measurement tracking with charts
- ✅ Analytics: weight trend, volume, weekly muscle split, streaks
- ✅ Goals with progress + achievement notifications
- ✅ Rule-based AI coach (LLM integration point ready)
- ✅ Dark/light/system themes, metric/imperial units
- ✅ CSV/JSON export, full data wipe
- ✅ Offline-first local persistence (Hive)
