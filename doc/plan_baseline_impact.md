# Plan: Baseline Impact para Scope Change COs

## Overview

Cuando un CO de tipo `scope_change` se aprueba, el sistema debe ajustar los recursos planeados del proyecto (`project_labor`, `project_machinery`, `project_materials`, `project_instruments`) para reflejar el cambio de alcance.

## Fase 1: DB Migration (`20260713070000`)

```sql
-- 1. source_co_id en tablas de recursos
ALTER TABLE public.project_labor 
    ADD COLUMN source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;
ALTER TABLE public.project_machinery 
    ADD COLUMN source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;
ALTER TABLE public.project_materials 
    ADD COLUMN source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;
ALTER TABLE public.project_instruments 
    ADD COLUMN source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;

-- 2. source_co_id en quote_services (para servicios nuevos creados vía CO)
ALTER TABLE public.quote_services 
    ADD COLUMN source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;

-- 3. Tabla de ajustes planeados (antes de aprobación)
CREATE TABLE public.change_order_resource_plans (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    change_order_detail_id uuid NOT NULL REFERENCES public.change_order_details(id) ON DELETE CASCADE,
    resource_type text NOT NULL CHECK (resource_type IN ('labor', 'machinery', 'material', 'instrument')),
    
    -- Para ajuste proporcional sobre servicio existente
    proportional_factor numeric,
    
    -- Para recursos explícitos (servicio nuevo o ajuste manual)
    catalog_id uuid,
    resource_name text NOT NULL,
    quantity numeric NOT NULL DEFAULT 1,
    unit text,
    unit_cost numeric DEFAULT 0,
    monthly_cost numeric,
    is_principal boolean DEFAULT true,
    parent_resource_name text,
    hours_per_day numeric,
    fuel_gph numeric,
    fuel_price numeric,
    trips_per_day numeric,
    capacity_per_trip numeric,
    performance_per_day numeric,
    calculation_metadata jsonb,
    
    notes text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE public.change_order_resource_plans ENABLE ROW LEVEL SECURITY;
```

## Fase 2: Backend — `billing_service.dart`

```dart
// ── Baseline Impact (Resource Plans) ──

Future<List<Map<String, dynamic>>> getResourcePlans(String coDetailId);

Future<void> saveResourcePlans(
  String coDetailId,
  List<Map<String, dynamic>> plans,
);

Future<void> applyBaselineImpact(String changeOrderId) async {
  // Llamado al aprobar el CO.
  // Para cada detail con line_type = 'existing_service' | 'new_service':
  //   1. Leer resource_plans
  //   2. Si existing_service con proportional_factor:
  //      - Clonar recursos existentes con cantidades * proportional_factor
  //      - change_type = 'change_order', source_co_id = changeOrderId
  //   3. Si new_service o recursos explícitos:
  //      - Crear quote_service si es nuevo
  //      - Insertar project_labor/machinery/materials/instruments
  //   4. Si deduction:
  //      - Marcar recursos como inactivos o reducir cantidades
}

Future<Map<String, dynamic>> createQuoteServiceFromCO(
  String changeOrderId, 
  Map<String, dynamic> serviceData,
);
```

### Controller (`change_order_controller.dart`)

```dart
Future<void> approveChangeOrder(String id) async {
  // Lógica existente + svc.applyBaselineImpact(id)
}
```

## Fase 3: UI — Formulario CO

### Nuevo widget: `baseline_impact_section.dart`

**Ubicación:** En `change_order_form_page.dart`, debajo de Line Items, solo visible para `scope_change`.

### Para `existing_service`:
- Input numérico: "% de recursos adicionales" (default = % de cambio en cantidad)
- Vista previa de recursos a agregar
- Botón "Adjust Manually" → diálogo para cantidades exactas

### Para `new_service`:
Mini-estimación con pestañas:

| Pestaña | Selector | Inputs libres |
|---|---|---|
| **Labor** | `labor_roles` (catálogo) | Cantidad, hourly_rate, per_diem |
| **Machinery** | `machinery` (catálogo) | Cantidad, monthly_rent, fuel_gph, fuel_price, hours/day |
| **Materials** | `materials` (catálogo) | Cantidad, unit_price, unit |
| **Equipment** | `logistics_equipment` (catálogo) | Cantidad, unit_price, days |

**Nota:** Los precios **no** vienen del catálogo. Se ingresan manualmente, igual que en la estimación original.

## Fase 4: UI — Detail Page

Sección nueva **"Baseline Impact"** (solo `scope_change`):
- Lista de recursos agregados/modificados por el CO
- Cada recurso: tipo, nombre, cantidad, costo unitario
- Badge "Change Order"

## Fase 5: Daily Reports

Sin cambios. Ya consultan todos los `project_labor`, `project_machinery`, `project_materials`, `project_instruments`. Los nuevos recursos aparecerán automáticamente.

## Archivos a Modificar/Crear

| Archivo | Acción |
|---|---|
| `supabase/migrations/20260713070000_baseline_impact.sql` | Crear |
| `packages/data/lib/src/services/billing_service.dart` | +5 métodos nuevos |
| `apps/.../change_orders/presentation/providers/change_order_controller.dart` | Modificar `approveChangeOrder` |
| `apps/.../change_orders/presentation/pages/change_order_form_page.dart` | Agregar `_buildBaselineImpact()` |
| `apps/.../change_orders/presentation/widgets/baseline_impact_section.dart` | Crear |
| `apps/.../change_orders/presentation/widgets/resource_adjustment_dialog.dart` | Crear |
| `apps/.../change_orders/presentation/pages/change_order_detail_page.dart` | Agregar sección impacto |
| Build runner + build web | Ejecutar |

## Estimación

~8 h (1 día laboral)
