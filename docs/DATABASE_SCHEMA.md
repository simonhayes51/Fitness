# Database schema

## Local (Hive)

Each box stores records keyed by `id`, with the value being the model's
`toMap()`. `DateTime`s are stored as ISO-8601 strings.

| Box (`AppConstants`) | Key | Value model | Notes |
|---|---|---|---|
| `exercises` | exercise id | `Exercise` | Seeded from `assets/data/exercises.json` (500+). Custom exercises use `custom-…` ids. |
| `workouts` | workout id | `Workout` | Completed + in-progress sessions. |
| `routines` | routine id | `Routine` | Templates; presets seeded on first launch. |
| `foods` | food id | `Food` | Seed + barcode-cached + custom foods. |
| `food_logs` | entry id | `FoodLogEntry` | Diary entries; grouped by `dayKey`. |
| `body_metrics` | metric id | `BodyMetric` | Weight + measurements over time. |
| `goals` | goal id | `Goal` | Strength/weight/nutrition/habit goals. |
| `water_logs` | `yyyy-MM-dd` | `WaterLog` | One per day. |
| `profile` | `'me'` | `UserProfile` | Single record. |
| `settings` | string key | primitive | Theme, seed flag, misc preferences. |

### Model relationships

```
UserProfile (1) ──────────────► derives ► MacroTargets, TDEE, BMR, BMI
Routine (1) ──< RoutineExercise (n) ──► references Exercise.id
Workout (1) ──< WorkoutExercise (n) ──< SetEntry (n)
              └ references Exercise.id   └ weight, reps, rpe, type, completed
FoodLogEntry (n) ──► embeds Food snapshot (so edits to the DB don't rewrite history)
BodyMetric (n) ──► weight + measurements{site: cm}
Goal (n) ──► start / current / target → progress 0..1
```

## Cloud (proposed Firestore layout)

Mirror the local boxes under each user. Embedding sets inside a workout document
keeps a session a single read/write (well under the 1 MiB doc limit).

```
users/{uid}
  ├── profile            (doc: UserProfile)
  ├── workouts/{id}      (doc: Workout, exercises[] embedded)
  ├── routines/{id}      (doc: Routine)
  ├── foods/{id}         (doc: Food — custom/cached only)
  ├── foodLogs/{id}      (doc: FoodLogEntry)
  ├── bodyMetrics/{id}   (doc: BodyMetric)
  ├── goals/{id}         (doc: Goal)
  └── waterLogs/{dayKey} (doc: WaterLog)
```

The shared exercise catalogue can live in a top-level read-only collection:

```
exercises/{id}           (doc: Exercise)   // public, read-only
```

### Security rules (starting point)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    // Public, read-only exercise catalogue.
    match /exercises/{id} {
      allow read: if true;
      allow write: if false;
    }
    // A user may only read/write their own subtree.
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```
