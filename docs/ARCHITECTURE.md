# Architecture

ForgeFit uses a pragmatic, layered architecture with Riverpod for dependency
injection and state. The golden rule: **the UI never talks to storage
directly** — it goes through providers, which expose repositories, which wrap
the local database.

```
┌────────────────────────────────────────────────────────────┐
│  features/**/*_screen.dart   (UI — ConsumerWidget/State)    │
│      watches/reads providers; never imports Hive            │
└───────────────┬────────────────────────────────────────────┘
                │ ref.watch / ref.read
┌───────────────▼────────────────────────────────────────────┐
│  shared/providers/*           (Riverpod = view-models + DI) │
│   - infrastructure: localDb, notifications, foodApi         │
│   - repositories: exercise/workout/routine/nutrition/profile│
│   - stateful: profileProvider, activeWorkoutProvider, …     │
└───────────────┬────────────────────────────────────────────┘
                │
┌───────────────▼────────────────────────────────────────────┐
│  data/repositories/*          (CRUD + queries + analytics)  │
│      map between models and stored maps                     │
└───────────────┬────────────────────────────────────────────┘
                │
┌───────────────▼────────────────────────────────────────────┐
│  data/services/local_db_service.dart  (Hive boxes of Maps)  │
│  data/models/*  (toMap / fromMap, DateTimes as ISO strings) │
└────────────────────────────────────────────────────────────┘
```

## Why maps instead of Hive TypeAdapters?

Models persist as plain `Map<String, dynamic>` (JSON-shaped). This means:

- **No code generation required to compile** — clone the repo and run.
- The same `toMap()` powers persistence *and* JSON export.
- Schema evolution is forgiving (`fromMap` tolerates missing keys).

If you prefer compile-time-typed boxes, you can later annotate the models with
`@HiveType` and run `build_runner`; the repository layer is the only thing that
would change.

## State refresh model

Reads from Hive are synchronous and cheap, so derived screens simply
`ref.watch(dataRevisionProvider)` — a monotonically increasing counter bumped
after every mutation (`ref.read(dataRevisionProvider.notifier).state++`). This
keeps the mental model trivial and avoids a web of fine-grained streams for an
app where a user mutates one record at a time.

The two genuinely "live" pieces of state use `StateNotifier`:

- `activeWorkoutProvider` — the in-progress session (mutated constantly while
  logging; re-emits a cloned `Workout` to notify listeners).
- `restTimerProvider` — the countdown timer.

## Adding cloud sync (Firebase)

The design keeps sync orthogonal to the UI. To add it:

1. Create `FirestoreSyncService` that listens to the same Hive boxes and mirrors
   changes to `users/{uid}/...` collections (see `DATABASE_SCHEMA.md`).
2. On sign-in, pull remote → merge into Hive → the `dataRevisionProvider` bump
   refreshes the UI.
3. Mark records with `synced: false` on local writes (the `Workout` model
   already carries this flag) and flush them when connectivity returns.

No screen code changes, because screens only know about repositories/providers.
