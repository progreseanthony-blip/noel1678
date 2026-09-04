-- ============================================================
-- Migration: Limpieza de duplicados historicos de new_service
-- Contexto: antes del single-writer (migracion 20260819000000), el trigger
-- y el cliente (applyBaselineImpact) podian crear cada uno un
-- project_service para el mismo detalle new_service. El perdedor quedaba
-- sin recursos o huerfano, y sus filas se mostraban en Timeline como
-- "General / Unassigned".
--
-- Idempotente y segura: solo fusiona filas con MISMO (project_id,
-- source_co_id, name); conserva la que tiene mas recursos; re-apunta
-- detalles, recursos y tareas al sobreviviente; borra perdedores solo
-- cuando ya nada los referencia. Si no hay duplicados, no hace nada.
-- ============================================================

DO $$
DECLARE
  v_grp     record;
  v_loser   record;
  v_keep    uuid;
  v_res     int;
BEGIN
  -- 1. Fusionar duplicados con mismo (project_id, source_co_id, name)
  FOR v_grp IN
    SELECT project_id, source_co_id, name
    FROM public.project_services
    WHERE source_co_id IS NOT NULL
    GROUP BY project_id, source_co_id, name
    HAVING COUNT(*) > 1
  LOOP
    -- Conservar el que tiene mas recursos (el creado por applyBaselineImpact);
    -- desempate por antiguedad.
    SELECT ps.id INTO v_keep
    FROM public.project_services ps
    WHERE ps.project_id = v_grp.project_id
      AND ps.source_co_id = v_grp.source_co_id
      AND ps.name = v_grp.name
    ORDER BY
      ((SELECT COUNT(*) FROM public.project_machinery m WHERE m.project_service_id = ps.id)
     + (SELECT COUNT(*) FROM public.project_labor l WHERE l.project_service_id = ps.id)
     + (SELECT COUNT(*) FROM public.project_materials ma WHERE ma.project_service_id = ps.id)
     + (SELECT COUNT(*) FROM public.project_instruments i WHERE i.project_service_id = ps.id)) DESC,
      ps.created_at ASC
    LIMIT 1;

    IF v_keep IS NULL THEN
      CONTINUE;
    END IF;

    -- Re-apuntar al sobreviviente todo lo que apuntaba a los perdedores
    FOR v_loser IN
      SELECT id
      FROM public.project_services
      WHERE project_id = v_grp.project_id
        AND source_co_id = v_grp.source_co_id
        AND name = v_grp.name
        AND id <> v_keep
    LOOP
      UPDATE public.project_machinery
      SET project_service_id = v_keep
      WHERE project_service_id = v_loser.id;

      UPDATE public.project_labor
      SET project_service_id = v_keep
      WHERE project_service_id = v_loser.id;

      UPDATE public.project_materials
      SET project_service_id = v_keep
      WHERE project_service_id = v_loser.id;

      UPDATE public.project_instruments
      SET project_service_id = v_keep
      WHERE project_service_id = v_loser.id;

      UPDATE public.change_order_details
      SET project_service_id = v_keep
      WHERE project_service_id = v_loser.id;

      UPDATE public.project_tasks
      SET project_service_id = v_keep
      WHERE project_service_id = v_loser.id;

      -- Borrar el perdedor solo si ya nada lo referencia
      SELECT
        (SELECT COUNT(*) FROM public.project_machinery WHERE project_service_id = v_loser.id)
      + (SELECT COUNT(*) FROM public.project_labor WHERE project_service_id = v_loser.id)
      + (SELECT COUNT(*) FROM public.project_materials WHERE project_service_id = v_loser.id)
      + (SELECT COUNT(*) FROM public.project_instruments WHERE project_service_id = v_loser.id)
      + (SELECT COUNT(*) FROM public.change_order_details WHERE project_service_id = v_loser.id)
      + (SELECT COUNT(*) FROM public.project_tasks WHERE project_service_id = v_loser.id)
      INTO v_res;

      IF v_res = 0 THEN
        DELETE FROM public.project_services WHERE id = v_loser.id;
      END IF;
    END LOOP;
  END LOOP;

  -- 2. Re-apuntar recursos huerfanos (project_service_id NULO por ON DELETE
  -- SET NULL) al unico servicio sobreviviente de su misma CO, cuando no hay
  -- ambiguedad (un solo project_service para ese project_id + source_co_id).
  -- Estos huerfanos son los que hoy se ven como "General / Unassigned".
  UPDATE public.project_machinery m
  SET project_service_id = s.id
  FROM public.project_services s
  WHERE m.project_service_id IS NULL
    AND m.source_co_id IS NOT NULL
    AND s.project_id = m.project_id
    AND s.source_co_id = m.source_co_id
    AND (SELECT COUNT(*) FROM public.project_services s2
         WHERE s2.project_id = m.project_id
           AND s2.source_co_id = m.source_co_id) = 1;

  UPDATE public.project_labor l
  SET project_service_id = s.id
  FROM public.project_services s
  WHERE l.project_service_id IS NULL
    AND l.source_co_id IS NOT NULL
    AND s.project_id = l.project_id
    AND s.source_co_id = l.source_co_id
    AND (SELECT COUNT(*) FROM public.project_services s2
         WHERE s2.project_id = l.project_id
           AND s2.source_co_id = l.source_co_id) = 1;

  UPDATE public.project_materials ma
  SET project_service_id = s.id
  FROM public.project_services s
  WHERE ma.project_service_id IS NULL
    AND ma.source_co_id IS NOT NULL
    AND s.project_id = ma.project_id
    AND s.source_co_id = ma.source_co_id
    AND (SELECT COUNT(*) FROM public.project_services s2
         WHERE s2.project_id = ma.project_id
           AND s2.source_co_id = ma.source_co_id) = 1;

  UPDATE public.project_instruments i
  SET project_service_id = s.id
  FROM public.project_services s
  WHERE i.project_service_id IS NULL
    AND i.source_co_id IS NOT NULL
    AND s.project_id = i.project_id
    AND s.source_co_id = i.source_co_id
    AND (SELECT COUNT(*) FROM public.project_services s2
         WHERE s2.project_id = i.project_id
           AND s2.source_co_id = i.source_co_id) = 1;

  -- 3. Purga de operadores fantasma del trigger viejo
  -- (handle_machinery_operator_assignment antes de la 20260819000002):
  -- role_name 'Operador de %' con linked_machinery_id, sin servicio ni CO.
  -- Si su maquinaria tiene servicio, lo hereda; si ya existe el operador
  -- real del plan (otro labor con mismo rol bajo ese servicio), se borra.
  FOR v_loser IN
    SELECT l.id, l.project_id, l.role_name, l.linked_machinery_id,
           m.project_service_id AS maq_service, m.source_co_id AS maq_co
    FROM public.project_labor l
    JOIN public.project_machinery m ON m.id = l.linked_machinery_id
    WHERE l.role_name LIKE 'Operador de %'
      AND l.linked_machinery_id IS NOT NULL
      AND l.project_service_id IS NULL
  LOOP
    IF v_loser.maq_service IS NOT NULL THEN
      -- Si ya hay un operador real para esa maquinaria+servicio, borrar;
      -- si no, adoptar el fantasma bajo el servicio de su maquinaria.
      SELECT id INTO v_keep
      FROM public.project_labor
      WHERE linked_machinery_id = v_loser.linked_machinery_id
        AND id <> v_loser.id
        AND project_service_id = v_loser.maq_service
      LIMIT 1;

      IF v_keep IS NOT NULL THEN
        DELETE FROM public.project_labor WHERE id = v_loser.id;
      ELSE
        UPDATE public.project_labor
        SET project_service_id = v_loser.maq_service,
            source_co_id = COALESCE(v_loser.maq_co, source_co_id),
            change_type = CASE WHEN v_loser.maq_co IS NOT NULL THEN 'change_order' ELSE change_type END
        WHERE id = v_loser.id;
      END IF;
    END IF;
  END LOOP;
END
$$;
