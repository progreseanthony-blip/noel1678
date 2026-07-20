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

## Melos 7 migration complete
- Project uses Dart pub workspaces (`workspace:` key in root `pubspec.yaml`)
- All Melos config lives under `melos:` key in root `pubspec.yaml` (no more `melos.yaml`)
- All packages have `resolution: workspace` in their `pubspec.yaml`
- Local package deps use `any` version constraint (workspace resolution handles linking)

## Required command order
Always run in this sequence:
1. `dart pub get` (at repo root) — resolves workspace deps via `melos` dev dependency
2. `melos run gen` — runs `build_runner build --delete-conflicting-outputs` everywhere
   - Must be re-run after any change to Riverpod annotated services or data models
   - `.g.dart` files are **gitignored** and must be regenerated locally
   - **Note:** `melos run gen` uses `melos exec` internally — if `melos` is not in PATH, run build_runner manually in each package:
     - `packages/core`
     - `packages/data`
     - `apps/main_app`
3. Build/run the app

## How to run
```bash
# Required before first run / after dependency changes
dart pub get  # Resolves workspace deps
melos run gen   # Runs build_runner everywhere

# Development (Chrome) — loads config from .env
melos run dev

# Production web build — loads config from .env.production (CI does this automatically)
# Config is passed via --dart-define, sourced from .env.production in the deploy workflow
```

## Environment & configuration
- Configuration uses **compile-time `--dart-define` flags**, not `.env` at runtime
- Read via `String.fromEnvironment()` in `packages/core/lib/src/config/env_config.dart`
- `.env` at repo root is the source of truth for development — loaded by `scripts/run_dev.ps1` → `melos dev`
- `.env.production` at repo root is the source of truth for production — loaded by CI workflow
- Defaults in `env_config.dart` serve only as fallback; update `.env` / `.env.production` for actual config changes

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
- **Routing**: GoRouter with auth redirect (`/projects` as landing when logged in, `/signin` when not), routes defined in `apps/main_app/lib/src/routing/router.dart`
- **Feature structure**: `apps/main_app/lib/src/features/<name>/presentation/pages/`
- **Theme**: centralized in `packages/core/lib/src/theme/app_theme.dart` — use `Theme.of(context)`, never hardcoded colors
- **Data layer**: Supabase is the remote backend. The `AppDatabase` class in the data package is a **stub for web compatibility** — Drift/SQLite is not wired in
- **Auth**: Supabase Auth, service at `packages/data/lib/src/services/auth_service.dart`

## CI/CD (GitHub Actions)
- `.github/workflows/deploy.yaml` — triggers on push to `master`/`main`
- Builds web, pushes Supabase migrations, deploys to Firebase Hosting
- Required secrets: `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `SUPABASE_PROJECT_ID`, `FIREBASE_TOKEN`, `FIREBASE_PROJECT_ID`

## ⚠️ Database safety rules
- NEVER run `supabase db reset` unless the user explicitly requests it
- ALWAYS run `scripts/db_backup.ps1` BEFORE any destructive DB operation
- `supabase db reset` DROPS ALL DATA — warn the user clearly before executing
- Backups are stored in `backups/` and are git-committed

## Git conventions
- Feature branches: `feat/description`
- Merge to `main` when done, push to `origin main`

---
## Session: Project Completion Cycle (feat/project-completion)

### Objective
Complete project lifecycle: service completion (with slider % + "Mark Complete"), project close with validation checklist, portfolio dashboard as landing page.

### Branch: feat/project-completion (from main after feat/machinery-return merge)

### Completed
- **Phase 1**: Migration `20260720000000_add_service_completion.sql` — added `completion_status`, `completion_pct`, `completed_at`, `completed_by` to `quote_services`
- **Phase 1b**: Migration `20260720000001_add_project_completion_fields.sql` — added `completed_at`, `completed_by`, `completion_notes` to `projects` (applied via `supabase db query`)
- **Phase 2**: `ServiceCompletionDialog` — slider 0-100%, "Mark Complete"/"Save Progress", saves to DB. Integrated in all 4 tabs (machinery, materials, instruments, labor) with completion badge and "Complete/Edit" button per service header
- **Phase 3**: Overall progress bar in `ProjectDetailPage` header — weighted by `direct_cost`, animated `LinearProgressIndicator` with % label and "X of Y services completed" subtitle
- **Phase 4**: `CloseProjectDialog` — validation checklist (services completed, machinery received/returned, materials received, instruments received), admin-only close button, completion notes field
- **Phase 5**: Portfolio dashboard — `ProjectsListPage` enhanced with stats cards (Total/Active/Completed/On Hold), status filter dropdown, progress bars per project with "X of Y services" detail
- **Routing**: Auth redirect added — logged-in users land on `/projects`, unauthenticated users redirected to `/signin`

### Key decisions
- Progress weighted by `direct_cost` (not simple ratio) — must unify across all modules later
- Admin detection via `profiles.role == 'Admin'` — only admins can close/reopen projects
- Completed button shows "Completed" (disabled) when project is already completed

### Files changed
- `supabase/migrations/20260720000001_add_project_completion_fields.sql` (new)
- `apps/main_app/lib/src/features/projects/presentation/widgets/service_completion_dialog.dart` (new, Phase 2)
- `apps/main_app/lib/src/features/projects/presentation/widgets/close_project_dialog.dart` (new, Phase 4)
- `apps/main_app/lib/src/features/projects/presentation/pages/project_detail_page.dart` (modified: Phase 2-4)
- `apps/main_app/lib/src/features/projects/presentation/pages/projects_list_page.dart` (rewritten: Phase 5, navigation to /dashboard)
- `apps/main_app/lib/src/features/projects/presentation/pages/project_dashboard_page.dart` (NEW — lightweight tracking dashboard)
- `apps/main_app/lib/src/routing/router.dart` (modified: auth redirect, added `/projects/:id/dashboard` route, Phase 5)
- `apps/main_app/lib/src/shared/widgets/sidebar.dart` (modified: Portfolio as top-level nav item, decoupled from Projects section)

### Key decisions (updated)
- Portfolio nav is independent top-level item (`Icons.space_dashboard`), not under Projects > Planning
- Clicking project in portfolio → `/projects/:id/dashboard` (new lightweight page), NOT Resource Planning
- Progress auto-calculated from daily reports via `ProductionMeasurementService` (same data as Production Metrics), NOT `quote_services.completion_pct`
- Dashboard shows: overall progress bar with EVM metrics (CPI, SPI, Earned/Actual), quick actions to related modules, service-level progress table with costs, recent daily reports

### Pending
- **Phase 6**: Protect edits on completed projects — add banner/disable buttons in `reception_page.dart` and other edit pages
