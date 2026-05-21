# AGENTS.md — Noel 1678

## Project overview
Flutter web monorepo (Melos workspace `noel_1678`) for golf course construction/renovation management. App name: `noel_app`.

## Monorepo structure
```
apps/main_app/              # Entrypoint Flutter app (noel_app)
packages/core/              # noel_core: env config, theme, estimation logic
packages/data/              # noel_data: Supabase client, Riverpod services
packages/ui_components/     # noel_ui_components: shared widgets (stub)
```

## Required command order
Always run in this sequence:
1. `melos get` — fetches deps across all packages
2. `melos gen` — runs `build_runner build --delete-conflicting-outputs` everywhere
   - Must be re-run after any change to Riverpod annotated services or data models
   - `.g.dart` files are **gitignored** and must be regenerated locally
3. Build/run the app

## How to run
```bash
# Development (Chrome)
cd apps/main_app
flutter run -d chrome --web-port 8081

# Production web build
flutter build web --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=SUPABASE_URL=<prod-url> \
  --dart-define=SUPABASE_ANON_KEY=<prod-key>
```

## Environment & configuration
- Configuration uses **compile-time `--dart-define` flags**, not `.env` at runtime
- Read via `String.fromEnvironment()` in `packages/core/lib/src/config/env_config.dart`
- Defaults point to local Supabase at `http://127.0.0.1:54421`
- `.env` at repo root is for reference only; not loaded by the app

## Supabase local dev
- Supabase CLI project at `supabase/`
- Local Supabase runs on ports 54421–54424 (config: `supabase/config.toml`)
- `supabase db push` deploys migrations; **never sync data, only schema (DDL)**
- Seed data: `supabase/seed.sql`

## Code generation
- Riverpod providers use `@riverpod` annotation → generates `.g.dart` part files
- Triggered by: `melos gen`
- CI runs `build_runner` in both `packages/data` and `apps/main_app` before build

## Architecture notes
- **State management**: Riverpod with code generation
- **Routing**: GoRouter, initial location `/signin`, routes defined in `apps/main_app/lib/src/routing/router.dart`
- **Feature structure**: `apps/main_app/lib/src/features/<name>/presentation/pages/`
- **Theme**: centralized in `packages/core/lib/src/theme/app_theme.dart` — use `Theme.of(context)`, never hardcoded colors
- **Data layer**: Supabase is the remote backend. The `AppDatabase` class in the data package is a **stub for web compatibility** — Drift/SQLite is not wired in
- **Auth**: Supabase Auth, service at `packages/data/lib/src/services/auth_service.dart`

## CI/CD (GitHub Actions)
- `.github/workflows/deploy.yaml` — triggers on push to `master`/`main`
- Builds web, pushes Supabase migrations, deploys to Firebase Hosting
- Required secrets: `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `SUPABASE_PROJECT_ID`, `FIREBASE_TOKEN`, `FIREBASE_PROJECT_ID`

## Git conventions
- Feature branches: `feat/description`
- Merge to `main` when done, push to `origin main`
