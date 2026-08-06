# Estado del Módulo: Execution Baseline - Recursos no Planificados

## Última Actualización: 2026-05-13 (Noche)

### Implementado:
1. **Migración DB:** Se añadieron columnas `quote_service_id` y `calculation_metadata` (JSONB) a `project_machinery`, `project_labor`, `project_materials` y `project_instruments`.
2. **Lógica de Herencia:** El diálogo de recursos extra ahora hereda automáticamente:
   - **Volumen (CY):** Extraído de la estimación original si el servicio es SQFT o CY.
   - **Rendimiento:** Viajes por día y capacidad por viaje si el equipo ya estaba presupuestado.
3. **UI Avanzada:**
   - Selector de maquinaria con imágenes (photo_url).
   - Desglose de costos: Renta + Combustible (GPH) + Logística.
4. **Dashboard:** Visualización del breakdown de costos en la lista de recursos del Baseline.

### Pendiente para Mañana:
- **Cálculo de Beneficio:** Implementar la lógica que determine cuánto dinero se ahorra al acortar días de servicio mediante el uso de recursos extra.
- **Validación de Flujo:** Pruebas finales de persistencia con los nuevos campos de metadata.

### Referencia Técnica:
- **Archivo Principal:** `lib/src/features/projects/presentation/widgets/add_unplanned_resource_dialog.dart`
- **ID de Conversación:** `67a2a69d-fd3a-467c-b20a-58f90158cd7c`
