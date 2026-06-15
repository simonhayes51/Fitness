# Roadmap

## v1.0 — MVP (this release) ✅

Workout logging, 500+ exercise library, nutrition diary with barcode scanning,
progress analytics, goals, AI coach (rule-based), offline-first storage,
theming, units, export.

## v1.1 — Polish & cloud

- [ ] **Firebase auth** (email / Google / Apple) + onboarding gate.
- [ ] **Cloud sync** via `FirestoreSyncService` with offline conflict handling.
- [ ] **Recipe builder & meal templates** (compose foods into reusable meals).
- [ ] **Micronutrients** (fiber/sugar/sodium already modelled; surface them).
- [ ] **Food diary photos** (image_picker + Firebase Storage already wired).
- [ ] **Full localisation** — ARB files for ES/DE/FR (scaffolding in `app.dart`).
- [ ] **Plate calculator** & warm-up set generator.

## v2.0 — Intelligence & integrations

- [ ] **LLM coaching** — replace the rule-based `AiCoachService` with Gemini /
      OpenAI via a Cloud Functions proxy (integration point already documented
      in `ai_coach_service.dart`).
- [ ] **Apple Health / Google Fit** — import weight, steps, heart rate, and
      export workouts (`health` package).
- [ ] **Wearables** — Apple Watch / Wear OS companion for in-set logging and
      live heart rate during cardio.
- [ ] **Auto progression** — periodised programs that adjust load from logged
      performance and RPE.
- [ ] **Body-composition photos** with side-by-side progress comparisons.

## v2.1+ — Community & ecosystem

- [ ] **Social feed** — share workouts/PRs, follow friends, kudos.
- [ ] **Coach marketplace** — trainers publish programs.
- [ ] **Challenges & leaderboards** (volume, streaks, consistency).
- [ ] **Web dashboard** (Flutter web — the codebase is portable).
- [ ] **Advanced analytics** — fatigue management, e1RM trend regression,
      muscle-group recovery heatmap.

## Technical debt / hardening

- [ ] Migrate Hive maps to typed adapters if profiling warrants it.
- [ ] Widget + integration tests for the workout logger and nutrition diary.
- [ ] CI (GitHub Actions): `flutter analyze` + `flutter test` on PRs.
- [ ] Crash/analytics (Firebase Crashlytics + Analytics).
- [ ] Accessibility audit (semantics labels, dynamic type, contrast).
