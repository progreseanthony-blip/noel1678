# Worker Time Confirmation

## Objetivo
Permitir que el trabajador valide y confirme las horas registradas en su jornada antes de que se compute la nómina (Payroll Period), usando una tablet/dispositivo en campo.

## Flujo General

```
Supervisor registra horas en Daily Report
  → Abre Payroll Period → Worker Confirmations
    → Supervisor selecciona trabajador
      → Le pasa la tablet al trabajador
        → Trabajador ve desglose diario de sus horas
          → Si está de acuerdo → firma digital → Confirma
          → Si no está de acuerdo → Disputa + nota
            → Queda registrado en worker_time_confirmations
              → Payroll solo calcula sobre horas confirmadas
```

## Nueva Tabla

```sql
worker_time_confirmations (
  id                    uuid primary key default gen_random_uuid(),
  payroll_period_id     uuid references payroll_periods(id) on delete cascade,
  worker_id             uuid references workers(id) on delete cascade,
  total_regular_hours   numeric not null default 0,
  total_overtime_hours  numeric not null default 0,
  status                text not null default 'pending'
                        check (status in ('pending', 'confirmed', 'disputed')),
  confirmed_at          timestamptz,
  confirmed_by          uuid references auth.users(id),
  signature_data        text,
  notes                 text,
  created_at            timestamptz default now(),
  unique(payroll_period_id, worker_id)
);
```

## Archivos a crear

### Migración SQL
- `supabase/migrations/20260609000000_create_worker_time_confirmations.sql`

### Data Package
- `packages/data/lib/src/services/payroll_service.dart`
  - Métodos: `precomputeConfirmations()`, `getConfirmations()`, `confirmHours()`, `disputeHours()`, `getWorkerHourBreakdown()`

### UI — Main App

- `apps/main_app/lib/src/features/payroll/presentation/widgets/worker_confirmations_table.dart`
  - Tabla dentro del período con status de cada trabajador

- `apps/main_app/lib/src/features/payroll/presentation/pages/worker_confirmation_page.dart`
  - Pantalla tablet-friendly full-screen
  - Desglose día por día de horas del trabajador
  - Canvas de firma digital (finger draw)
  - Botones Confirm / Dispute

### Router
- `apps/main_app/lib/src/routing/router.dart`
  - Ruta: `/projects/:id/payroll/:periodId/confirm/:workerId`

### Modificaciones
- `apps/main_app/lib/src/features/payroll/presentation/pages/payroll_period_page.dart`
  - Agregar sección "Worker Confirmations" con tabla de status
  - Alerta si hay pending/disputed antes de calcular

## Integración con Payroll

- `calculatePeriod()` debe advertir si hay workers sin confirmar
- El cálculo puede filtrar solo horas confirmadas
- Período se puede cerrar solo cuando todos están confirmados (opcional futuro)

## UI Preview

```
┌─────────────────────────────────────┐
│  ← Back                            │
│                                     │
│  👷 JUAN PÉREZ                      │
│  Period: Jun 01 - Jun 15, 2026      │
│                                     │
│  ── Hour Breakdown ──              │
│  📅 Jun 01: 8.0h regular           │
│  📅 Jun 02: 9.0h regular + 1.0h OT │
│  📅 Jun 03: 8.0h regular           │
│  ...                                │
│  ────────────────────               │
│  Total:    40.0h regular            │
│  Overtime:  2.0h                    │
│                                     │
│  ┌─────────────────────────┐       │
│  │ ✍️  Sign below          │       │
│  │ ┌─────────────────────┐ │       │
│  │ │                     │ │       │
│  │ │   (finger draw)     │ │       │
│  │ │                     │ │       │
│  │ └─────────────────────┘ │       │
│  └─────────────────────────┘       │
│                                     │
│  [   DISPUTE   ]  [ ✅ CONFIRM   ] │
└─────────────────────────────────────┘
```
