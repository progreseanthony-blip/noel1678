-- Basic Seed for local development
-- Insert Labor Roles
INSERT INTO public.labor_roles (description, hourly_rate) VALUES
('SUPERVISOR', 45.00),
('Excavator Operator', 35.00),
('Truck Operator', 28.00),
('Shaper Class B', 32.00),
('Scraper operator', 34.00),
('Laborer', 20.00)
ON CONFLICT DO NOTHING;

-- Insert Machinery
INSERT INTO public.machinery (description, machinery_type, fuel_gallons, capacity_yards, trips_per_day) VALUES
('Excavator CAT 320', 'hauling', 5.5, 1.5, 60),
('Dump Truck 14yd', 'hauling', 8.0, 14.0, 15),
('Dozer D6', 'hauling', 6.0, 0, 0),
('Roller CS56', 'hauling', 4.0, 0, 0)
ON CONFLICT DO NOTHING;

-- Insert Services (Catalog)
INSERT INTO public.services (description, unit) VALUES
('TOPSOIL STRIPPING', 'CY'),
('BULK EXCAVATION', 'CY'),
('FINISH GRADING', 'SQFT'),
('SUBGRADE PREP', 'SQFT'),
('BASE COURSE', 'CY')
ON CONFLICT DO NOTHING;

-- Insert a Test Quote/Project
DO $$
DECLARE
    quote_id UUID;
    serv1_id UUID;
    serv2_id UUID;
BEGIN
    INSERT INTO public.quotes (title, status)
    VALUES ('Project Golf 2 - Baseline Test', 'Accepted')
    RETURNING id INTO quote_id;

    -- Insert Quote Services (with direct_cost for weighted progress calculation)
    INSERT INTO public.quote_services (quote_id, name, unit_of_measure, quantity, direct_cost, completion_pct, completion_status)
    VALUES 
    (quote_id, 'BULK EXCAVATION', 'CY', 5000, 50000, 50, 'in_progress'),
    (quote_id, 'FINISH GRADING', 'SQFT', 45000, 30000, 0, 'pending');

    -- Insert a Project linked to this quote
    INSERT INTO public.projects (quote_id, title, status)
    VALUES (quote_id, 'Execution Golf 2 - Phase 1', 'active');
END $$;
