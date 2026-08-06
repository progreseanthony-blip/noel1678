# Target Price Budgeting — Plan Automatizado (Futuro)

## Objetivo

Dado un precio fijo por servicio (impuesto por el contratante), el sistema debe proponer automáticamente una configuración de recursos (maquinaria, labor, materiales) que cumpla con el precio objetivo, usando datos históricos como referencia.

## Flujo

```
1. Usuario crea servicio (ej: BULK EXCAVATION)
2. Elige "Target Price Projection" (modo alternativo)
3. Ingresa:
   - Volumen/área a cubrir (yardas, SQFT, etc.)
   - Precio objetivo ($)
   - Plazo deseado (días hábiles)

4. Sistema:
   a) Query histórico: busca estimaciones del mismo tipo de servicio
      → extrae configuración típica (máquinas, trips, capacidad, cantidades)
   b) Calcula "costo natural" con esa configuración
   c) Muestra brecha: targetPrice - subTotal_natural
   d) Propone ajustes automáticos:
      - Ajustar OH% y profit% proporcionalmente (respetando rangos)
      - Ajustar monthly_rent_cost de las máquinas
      - Si brecha grande → sugerir ± máquinas o ± plazo

5. Usuario revisa, ajusta manualmente, confirma
6. Se guarda estimación normalmente (project monitoring intacto)
```

## Backend requerido

### 1. Query de datos históricos

```sql
-- JOIN quote_service_estimations + quote_services para mismo tipo de servicio
SELECT 
  qse.*,
  qser.machine_id, qser.quantity, qser.trips_per_day, 
  qser.capacity_per_trip, qser.performance_per_day,
  qs.unit_of_measure, qs.quantity as service_qty
FROM quote_service_estimations qse
JOIN quote_service_estimation_resources qser ON qser.estimation_id = qse.id
JOIN quote_services qs ON qs.id = qse.quote_service_id
WHERE qs.service_id = :catalogServiceId  -- mismo tipo de servicio
  AND qs.id != :currentServiceId
ORDER BY qse.created_at DESC
```

### 2. Algoritmo de recursos típicos

```dart
Map<String, dynamic> _suggestTypicalResources(List<Map<String, dynamic>> historicalEstimations) {
  // Agrupar por machine_id
  // Por cada máquina: mediana de quantity, trips_per_day, capacity_per_trip
  // Retornar lista de recursos sugeridos
}
```

### 3. Algoritmo de ajuste proporcional

```dart
/// Distribuye la brecha entre componentes flexibles respetando límites
/// 
/// Componentes flexibles con sus rangos:
/// - overhead_percentage: 5% - 25%
/// - profit_percentage: 5% - 35%  
/// - monthly_rent_cost: ±25% del valor original
/// - quantity (máquinas): ±50% (afecta plazo también)
///
/// Algoritmo:
/// 1. Calcular contribución de cada componente al costo total
/// 2. Ponderar ajuste según contribución
/// 3. Iterar hasta convergencia o máximo de iteraciones
/// 4. Si no converge, sugerir ajuste de plazo (±máquinas)
Map<String, dynamic> _autoAdjustBudget({
  required double targetPrice,
  required double currentSubTotal,
  required double currentOH,
  required double currentProfit,
  required List<MachineryEntry> machineries,
  required double workingDays,
  required double totalVolume,
}) { ... }
```

### 4. Configuración de reglas de presupuesto

Nueva tabla: `project_budget_rules`

```sql
CREATE TABLE project_budget_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  fuel_locked boolean DEFAULT true,        -- no ajustar combustible
  labor_locked boolean DEFAULT true,       -- no ajustar tarifas laborales
  material_max_adjust_pct numeric DEFAULT 10,  -- ±10%
  machinery_rent_max_adjust_pct numeric DEFAULT 25,  -- ±25%
  oh_min numeric DEFAULT 5, oh_max numeric DEFAULT 25,
  profit_min numeric DEFAULT 5, profit_max numeric DEFAULT 35,
  created_at timestamptz DEFAULT now()
);
```

## UI requerida

### 1. Panel "Target Price Projection" (nuevo paso 0 alternativo)

Alternativa al Planning normal con campos:
- Target Price ($)
- Target Working Days
- Auto-adjust toggles (fuel, labor, materials, rent)
- Botón "Calculate"

### 2. Resultados del ajuste

- Tabla con: Componente | Original | Ajustado | Diferencia
- Indicador visual del gap final
- Warnings si algún componente excede su rango
- Botón "Apply & Continue" → pasa a Resources step con valores ajustados

### 3. Panel de reglas (Settings)

- Por proyecto o global
- Sliders para rangos de OH, profit
- Toggles para componentes bloqueados
- Sliders para % máximo de ajuste por componente

## Archivos estimados

| Archivo | Propósito | Líneas |
|---------|-----------|--------|
| Nueva migración SQL | Tabla `project_budget_rules` | 20 |
| `packages/data/lib/src/services/budget_service.dart` | Query histórico + algoritmo | 250 |
| `quote_form_dialog.dart` | Panel Target Price + resultados | 300 |
| `service_estimation_dialog.dart` | Integración con modo alternativo | 150 |
| Settings page nueva | Reglas de presupuesto | 200 |

**Total estimado: ~920 líneas, 5 archivos.**
