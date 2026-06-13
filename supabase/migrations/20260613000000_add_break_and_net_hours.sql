-- ============================================================================
-- Agrega columna break_minutes (descanso de 30 min al medio día)
-- y total_net_hours (horas netas después del break) a report_labor_logs
-- ============================================================================

ALTER TABLE public.report_labor_logs
  ADD COLUMN break_minutes integer NOT NULL DEFAULT 30,
  ADD COLUMN total_net_hours numeric NOT NULL DEFAULT 0;

-- Backfill: calcular total_net_hours para registros existentes
-- Fórmula: (check_out - check_in) en horas - break_minutes/60
-- Para registros existentes sin break, asumimos 30 min si la jornada >= 6h
UPDATE public.report_labor_logs
SET
  break_minutes = CASE
    WHEN check_out_time IS NOT NULL
      AND (EXTRACT(EPOCH FROM check_out_time - check_in_time) / 3600) >= 6
    THEN 30 ELSE 0
  END,
  total_net_hours = CASE
    WHEN check_out_time IS NOT NULL THEN
      GREATEST(0,
        (EXTRACT(EPOCH FROM check_out_time - check_in_time) / 3600)
        - CASE
            WHEN (EXTRACT(EPOCH FROM check_out_time - check_in_time) / 3600) >= 6
            THEN 30.0 / 60.0 ELSE 0
          END
      )
    ELSE 0
  END;

NOTIFY pgrst, 'reload schema';
