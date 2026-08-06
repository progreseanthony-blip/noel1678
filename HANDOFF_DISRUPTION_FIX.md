# HANDOFF: Fix Disruption Bands & Labor End Date Extension

> Documento de handoff creado para que la próxima sesión entienda todo lo realizado
> y pueda continuar con el plan sin perder contexto.

---

## Resumen del estado

Sesión trabajó sobre la rama de plan de proyecto (`feat/project-completion` según AGENTS.md,
verificar `git branch` actual). Se corrigieron bugs en el Gantt de `project_detail_page.dart`
y en la lógica de shift de recursos por disruptions (`billing_service.dart`).

**Ambiente de prueba:** dev local (`scripts/run_dev.ps1`, puerto 8081, Supabase local
`http://127.0.0.1:8001`, `ENVIRONMENT=development`). El build web apunta a producción y NO
contiene los datos de prueba — no usar para validar.

---

## Bugs corregidos

### Bug 1 — Las disruption bands no se renderizaban (crítico)

**Causa raíz:** `_loadDisruptions` en `project_detail_page.dart` tenía `catch (_) {}`
silencioso que tragaba el error real. El error era:
`TypeError: JSArray<dynamic> is not a subtype of List<Map<String, dynamic>>`
En web, Supabase retorna `List<dynamic>` (JSArray) y el cast implícito a
`List<Map<String, dynamic>>` falla.

**Fix aplicado:**
- `project_detail_page.dart:2237-2245`: `rawDisruptions` + `List<Map<String, dynamic>>.from(rawDisruptions)`
- `project_detail_page.dart:2249-2252`: se eliminó la mutación directa del map de Supabase
  (ahora usa `Map<String, dynamic>.from(d)` para copiar primero)

**Fix colateral (mismo patrón JSArray):**
- `baseline_service.dart:17-23`: `getSnapshots()` ahora hace
  `List<Map<String, dynamic>>.from(raw ?? [])`

### Bug 2 — Color de franjas de disruption (cambio estético)

- `project_detail_page.dart:2263-2278`: `_disruptionColor` ahora usa tonos **pastel** por tipo:
  - Weather → `0xFFBBDEFB` (azul pastel)
  - Owner delay → `0xFFFFE0B2` (naranja pastel)
  - External dep / pending permit → `0xFFE1BEE7` (púrpura pastel)
  - Design change → `0xFFFFCDD2` (rojo pastel)
  - Default → `0xFFE0E0E0` (gris pastel)
- `_DisruptionStripePainter` (final del archivo, ~3522): rayado diagonal con opacity 0.55 y
  strokeWidth 3.0.

### Bug 3 — Labor end_date no se extiende por disruption

**Diagnóstico:** Los labors no se extendían porque el `schedule_impact_applied_at` ya estaba
seteado (ejecutado con código viejo que no shifteaba labors) y la idempotencia en
`applyScheduleImpact` bloquea re-ejecución.

**Fix ya en código (de sesión anterior):** `_shiftServiceResources` reescrito en
`billing_service.dart:965-1117`:
- Deriva fechas de `project_labor_assignments` cuando el parent `project_labor` tiene
  `start_date`/`end_date` NULL
- Shiftea tanto el parent como los assignments
- Loggea resultados con `debugPrint`

**Verificación exitosa:** Se ejecutó un test autenticado contra Supabase local que re-aplicó
`applyScheduleImpact` para los 4 COs con disruptions del proyecto de prueba. Resultado:

| Labor | Antes | Después | Delay |
|---|---|---|---|
| CLEARING CONSTRUCTION SUPERINTENDENT | 08-12 | 08-17 | +5 |
| CLEARING SHAPER CLASS B | 08-12 | 08-17 | +5 |
| TOPSOIL TRUCK OPERATOR | 10-22 | 11-02 | +11 |
| TOPSOIL Shaper Class B | 10-22 | 11-02 | +11 |
| TOPSOIL Scraper operator | 09-26 | 10-07 | +11 |

**IMPORTANTE:** Los datos en la DB local YA quedaron actualizados con estos shifts.

---

## Archivos modificados

| Archivo | Cambio | Líneas |
|---|---|---|
| `apps/main_app/lib/src/features/projects/presentation/pages/project_detail_page.dart` | Cast JSArray + colores pastel | 2237-2245, 2263-2278, ~2349-2391, ~3522-3549 |
| `packages/data/lib/src/services/baseline_service.dart` | Cast JSArray en `getSnapshots` | 17-23 |
| `packages/data/lib/src/services/billing_service.dart` | `_shiftServiceResources` reescrito (sesión anterior) | 965-1117 |

El test temporal (`packages/data/test/reapply_schedule_test.dart`) se eliminó.
`melos run gen` / build_runner ya se ejecutó en `packages/data` y `apps/main_app`.

---

## Pendientes / Plan por fases

### Fase 1 — Verificar el flujo UI completo
Crear un **nuevo CO tipo disruption** desde el UI, aprobarlo, y verificar en la consola del
navegador que aparecen los logs `[_shiftServiceResources] table=project_labor` con el shift
correcto. Confirmar en el Gantt que la barra de labor se extiende. Si no aparece, revisar
si `change_order_disruption_services` se está guardando bien desde el formulario
(`change_order_form_page.dart:848-863` / `902-917`).

### Fase 2 — Arreglar RenderFlex overflow en el Gantt
El Gantt muestra constantemente `A RenderFlex overflowed by XX pixels on the right`
(~línea 3110 de `project_detail_page.dart`). Posiblemente causado por barras/overlays que
exceden el ancho del Row. Revisar layout.

### Fase 3 — Revisar data posiblemente sobre-extendida en TOPSOIL
La re-aplicación masiva de los 4 COs pudo haber sobre-extendido TOPSOIL (doble aplicación de
delays). Si se necesita restaurar, recalcular desde baseline o snapshot.

### Fase 4 — Considerar helper para cast JSArray
El patrón `List<Map<String, dynamic>>.from(raw)` se repite en varios queries de Supabase en
web. Evaluar crear un helper/extension `safeCastList(raw)` y aplicarlo en todos los `.select()`.

---

## Cómo probar / Comandos

```bash
# Dev server (puerto 8081, carga config desde .env)
scripts/run_dev.ps1

# Si se modifica billing_service.dart o modelos (build_runner)
cd packages/data && dart run build_runner build --delete-conflicting-outputs
cd apps/main_app && dart run build_runner build --delete-conflicting-outputs
```

- **Credencial:** `samuel@mey.com` / `121212` (instancia local)
- **Proyecto de prueba:** `207e0a61-88f2-4892-91aa-83d1213a8687`
  (tiene 4 disruptions visibles en el Gantt)
- **Logs a buscar:** `[_loadDisruptions]`, `[_buildBarDisruptionOverlays]`,
  `[_shiftServiceResources]`, `[applyScheduleImpact]`

---

## Comandos útiles para inspeccionar la DB (docker)

```bash
# Contenedor local
docker exec supabase_db_Noel_1678 psql -U postgres -d postgres -c "<SQL>"

# COs aprobados con disruptions del proyecto de prueba
SELECT cd.id, co.co_number, cd.start_date, cd.end_date, cd.disruption_type,
       cd.schedule_impact_applied_at
FROM change_order_disruptions cd
JOIN change_orders co ON co.id = cd.change_order_id
WHERE co.project_id = '207e0a61-88f2-4892-91aa-83d1213a8687';

# Labors del proyecto de prueba
SELECT id, quote_service_id, role_name, start_date, end_date
FROM project_labor
WHERE project_id = '207e0a61-88f2-4892-91aa-83d1213a8687'
  AND quote_service_id IN ('b22d92b1-96c4-4603-84d2-748ba412c915',
                           '22e2ac07-bf12-4a1d-a192-5b25a6ddaacc');
```

---

## Notas de contexto (AGENTS.md relevantes)

- Monorepo Melos: `dart pub get` (raíz) → `melos run gen` → build/run
- `melos` NO está en PATH → build_runner manual en cada paquete
- ⚠️ NO correr `supabase db reset`; correr `scripts/db_backup.ps1` antes de ops destructivas
- Config por `--dart-define` desde `.env` / `.env.production`
- Gantt: `apps/main_app/lib/src/features/projects/presentation/pages/project_detail_page.dart`
- Disruption data flow: `change_order_form_page` → `billing_service.saveDisruptionRecords/Services`
  → `change_order_controller.approveChangeOrder` → `applyScheduleImpact` → `_shiftServiceResources`
