-- Migration: Seed 45 test workers for production/staging
-- Created: 2026-05-06

DO $$ 
DECLARE 
    role_id_var UUID;
BEGIN
    -- SUPERVISORES (5)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = 'SUPERVISOR' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        ('Carlos Rodriguez', 'ID-1001', role_id_var, 'Active'),
        ('Maria Gonzales', 'ID-1002', role_id_var, 'Active'),
        ('Jose Martinez', 'ID-1003', role_id_var, 'Active'),
        ('Luis Hernandez', 'ID-1004', role_id_var, 'Active'),
        ('Ana Lopez', 'ID-1005', role_id_var, 'Active')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

    -- EXCAVATOR OPERATORS (10)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = 'Excavator Operator' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        ('Juan Perez', 'OP-2001', role_id_var, 'Active'),
        ('Pedro Garcia', 'OP-2002', role_id_var, 'Active'),
        ('Miguel Angel', 'OP-2003', role_id_var, 'Active'),
        ('Francisco Javier', 'OP-2004', role_id_var, 'Active'),
        ('Antonio Jose', 'OP-2005', role_id_var, 'Active'),
        ('David Smith', 'OP-2006', role_id_var, 'Active'),
        ('James Wilson', 'OP-2007', role_id_var, 'Active'),
        ('Robert Brown', 'OP-2008', role_id_var, 'Active'),
        ('John Miller', 'OP-2009', role_id_var, 'Active'),
        ('Richard Moore', 'OP-2010', role_id_var, 'Active')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

    -- TRUCK OPERATORS (10)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = 'Truck Operator' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        ('Oscar Duarte', 'TK-3001', role_id_var, 'Active'),
        ('Ramon Valdez', 'TK-3002', role_id_var, 'Active'),
        ('Nelson Mendez', 'TK-3003', role_id_var, 'Active'),
        ('Victor Hugo', 'TK-3004', role_id_var, 'Active'),
        ('Hugo Sanchez', 'TK-3005', role_id_var, 'Active'),
        ('Mario Kempes', 'TK-3006', role_id_var, 'Active'),
        ('Gabriel Batistuta', 'TK-3007', role_id_var, 'Active'),
        ('Hernan Crespo', 'TK-3008', role_id_var, 'Active'),
        ('Lionel Messi', 'TK-3009', role_id_var, 'Active'),
        ('Diego Maradona', 'TK-3010', role_id_var, 'Active')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

    -- SHAPER CLASS B (10)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = 'Shaper Class B' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        ('Arthur Morgan', 'SH-4001', role_id_var, 'Active'),
        ('John Marston', 'SH-4002', role_id_var, 'Active'),
        ('Sadie Adler', 'SH-4003', role_id_var, 'Active'),
        ('Charles Smith', 'SH-4004', role_id_var, 'Active'),
        ('Bill Williamson', 'SH-4005', role_id_var, 'Active'),
        ('Javier Escuella', 'SH-4006', role_id_var, 'Active'),
        ('Dutch van der Linde', 'SH-4007', role_id_var, 'Active'),
        ('Hosea Matthews', 'SH-4008', role_id_var, 'Active'),
        ('Micah Bell', 'SH-4009', role_id_var, 'Active'),
        ('Lenny Summers', 'SH-4010', role_id_var, 'Active')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

    -- SCRAPER OPERATORS (10)
    SELECT id INTO role_id_var FROM public.labor_roles WHERE description = 'Scraper operator' LIMIT 1;
    IF role_id_var IS NOT NULL THEN
        INSERT INTO public.workers (full_name, id_number, role_id, status) VALUES
        ('Geralt of Rivia', 'SC-5001', role_id_var, 'Active'),
        ('Yennefer Vengerberg', 'SC-5002', role_id_var, 'Active'),
        ('Triss Merigold', 'SC-5003', role_id_var, 'Active'),
        ('Ciri Riannon', 'SC-5004', role_id_var, 'Active'),
        ('Vesemir Kaer', 'SC-5005', role_id_var, 'Active'),
        ('Lambert Eskel', 'SC-5006', role_id_var, 'Active'),
        ('Dandelion Julian', 'SC-5007', role_id_var, 'Active'),
        ('Zoltan Chivay', 'SC-5008', role_id_var, 'Active'),
        ('Sigismund Dijkstra', 'SC-5009', role_id_var, 'Active'),
        ('Emhyr Var Emreis', 'SC-5010', role_id_var, 'Active')
        ON CONFLICT (id_number) DO NOTHING;
    END IF;

END $$;
