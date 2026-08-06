


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."handle_checkin_completion"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    duration_hours NUMERIC;
BEGIN
    IF NEW.status = 'completed' AND OLD.status = 'active' AND NEW.check_out IS NOT NULL THEN
        -- Calculate hours
        duration_hours := EXTRACT(EPOCH FROM (NEW.check_out - NEW.check_in)) / 3600;
        
        -- Update task
        IF NEW.project_task_id IS NOT NULL THEN
            UPDATE public.project_tasks
            SET actual_hours = actual_hours + duration_hours
            WHERE id = NEW.project_task_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_checkin_completion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_labor_checkin_changes"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.project_labor 
        SET active_employees = active_employees + 1
        WHERE id = NEW.project_labor_id;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.status = 'active' AND NEW.status = 'completed') THEN
            UPDATE public.project_labor 
            SET active_employees = active_employees - 1
            WHERE id = NEW.project_labor_id;
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        IF (OLD.status = 'active') THEN
            UPDATE public.project_labor 
            SET active_employees = active_employees - 1
            WHERE id = OLD.project_labor_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_labor_checkin_changes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_machinery_operator_assignment"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_role_name TEXT;
BEGIN
    -- We only auto-generate for unplanned machinery added during execution/re-planning phase.
    -- (Planned machinery from quotes already has its labor inserted via ProjectService.convertQuoteToProject)
    IF NEW.is_unplanned = true THEN
        v_role_name := 'Operador de ' || NEW.machinery_name;

        INSERT INTO public.project_labor (
            project_id, 
            role_name, 
            expected_employees, 
            is_unplanned, 
            linked_machinery_id
        ) VALUES (
            NEW.project_id,
            v_role_name,
            NEW.expected_quantity, -- Match the number of operators to the number of machines
            true,
            NEW.id
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_machinery_operator_assignment"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, email, name, role)
  values (new.id, new.email, new.raw_user_meta_data->>'name', 'Employee');
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_worker_role_change"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  prev_rate numeric;
begin
  if (TG_OP = 'UPDATE' and old.role_id is distinct from new.role_id) then
    -- Get previous hourly rate
    select hourly_rate into prev_rate from public.labor_roles where id = old.role_id;
    
    insert into public.worker_role_history (worker_id, previous_role_id, new_role_id, previous_hourly_rate)
    values (new.id, old.role_id, new.role_id, prev_rate);
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_worker_role_change"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."customers" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "ein" "text",
    "address" "text",
    "phone" "text",
    "email" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."customers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."labor_checkins" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "project_labor_id" "uuid" NOT NULL,
    "worker_id" "uuid" NOT NULL,
    "check_in" timestamp with time zone DEFAULT "now"() NOT NULL,
    "check_out" timestamp with time zone,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "observations" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "project_task_id" "uuid"
);


ALTER TABLE "public"."labor_checkins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."labor_roles" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "description" "text" NOT NULL,
    "hourly_rate" numeric DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."labor_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."logistics_applications" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."logistics_applications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."logistics_equipment" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "description" "text" NOT NULL,
    "photo_url" "text",
    "associated_service_ids" "uuid"[] DEFAULT '{}'::"uuid"[],
    "applications" "text"[] DEFAULT '{}'::"text"[],
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."logistics_equipment" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."machinery" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "description" "text" NOT NULL,
    "photo_url" "text",
    "capacity" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "delivery_cost" numeric DEFAULT 0,
    "default_trips_per_day" numeric DEFAULT 60 NOT NULL,
    "fuel_gallons" numeric DEFAULT 0,
    "capacity_yards" numeric DEFAULT 0,
    "trips_per_day" numeric DEFAULT 0,
    "yards_per_day" numeric DEFAULT 0,
    "machinery_type" "text" DEFAULT 'hauling'::"text",
    "associated_service_ids" "uuid"[] DEFAULT '{}'::"uuid"[],
    "applications" "text"[] DEFAULT '{}'::"text"[],
    "machinery_category" "text" DEFAULT 'support'::"text" NOT NULL,
    "operator_role_id" "uuid",
    CONSTRAINT "machinery_machinery_category_check" CHECK (("machinery_category" = ANY (ARRAY['transport'::"text", 'support'::"text", 'dual'::"text"])))
);


ALTER TABLE "public"."machinery" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."machinery_applications" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."machinery_applications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."machinery_inspections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_machinery_id" "uuid" NOT NULL,
    "internal_code" "text",
    "brand_model" "text",
    "ownership_type" "text" DEFAULT 'owned'::"text",
    "provider_name" "text",
    "hour_meter_start" numeric,
    "condition_status" "text" DEFAULT 'operational'::"text",
    "evidence_photos" "jsonb" DEFAULT '[]'::"jsonb",
    "observations" "text",
    "received_at" timestamp with time zone DEFAULT "now"(),
    "received_by" "uuid",
    CONSTRAINT "machinery_inspections_condition_status_check" CHECK (("condition_status" = ANY (ARRAY['excellent'::"text", 'operational'::"text", 'needs_maintenance'::"text", 'damaged'::"text"]))),
    CONSTRAINT "machinery_inspections_ownership_type_check" CHECK (("ownership_type" = ANY (ARRAY['owned'::"text", 'rented'::"text"])))
);


ALTER TABLE "public"."machinery_inspections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."material_receptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_material_id" "uuid" NOT NULL,
    "received_by" "uuid",
    "invoice_number" "text",
    "provider_name" "text",
    "quantity_received" numeric NOT NULL,
    "condition_status" "text" DEFAULT 'good'::"text",
    "observations" "text",
    "evidence_photos" "jsonb" DEFAULT '[]'::"jsonb",
    "received_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "material_receptions_condition_status_check" CHECK (("condition_status" = ANY (ARRAY['good'::"text", 'damaged'::"text", 'incomplete'::"text"])))
);


ALTER TABLE "public"."material_receptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."materials" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "unit" "text",
    "yield_factor" numeric DEFAULT 1.0,
    "associated_service_ids" "uuid"[] DEFAULT '{}'::"uuid"[],
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."materials" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "name" "text",
    "email" "text",
    "phone" "text",
    "role" "text" DEFAULT 'Employee'::"text",
    "avatar_url" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_instruments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "quote_service_instrument_id" "uuid",
    "instrument_name" "text" NOT NULL,
    "expected_quantity" numeric DEFAULT 1 NOT NULL,
    "received_quantity" numeric DEFAULT 0 NOT NULL,
    "is_unplanned" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "unplanned_cost" numeric DEFAULT 0,
    "quote_service_id" "uuid",
    "calculation_metadata" "jsonb"
);


ALTER TABLE "public"."project_instruments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_labor" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "quote_service_labor_id" "uuid",
    "role_name" "text" NOT NULL,
    "expected_employees" integer DEFAULT 1 NOT NULL,
    "active_employees" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "is_unplanned" boolean DEFAULT false NOT NULL,
    "linked_machinery_id" "uuid",
    "unplanned_cost" numeric DEFAULT 0,
    "quote_service_id" "uuid",
    "calculation_metadata" "jsonb"
);


ALTER TABLE "public"."project_labor" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_labor_assignments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_labor_id" "uuid",
    "worker_id" "uuid",
    "assigned_at" timestamp with time zone DEFAULT "now"(),
    "start_date" "date",
    "end_date" "date",
    CONSTRAINT "check_assignment_dates" CHECK (("end_date" >= "start_date"))
);


ALTER TABLE "public"."project_labor_assignments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_machinery" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "quote_service_machinery_id" "uuid",
    "machinery_name" "text" NOT NULL,
    "expected_quantity" integer DEFAULT 1 NOT NULL,
    "received_quantity" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "start_date" "date",
    "end_date" "date",
    "is_principal" boolean DEFAULT false NOT NULL,
    "parent_machinery_id" "uuid",
    "is_unplanned" boolean DEFAULT false NOT NULL,
    "unplanned_cost" numeric DEFAULT 0,
    "quote_service_id" "uuid",
    "calculation_metadata" "jsonb",
    CONSTRAINT "check_machinery_scheduling_dates" CHECK (("end_date" >= "start_date"))
);


ALTER TABLE "public"."project_machinery" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_materials" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "quote_service_material_id" "uuid",
    "material_name" "text" NOT NULL,
    "unit_name" "text",
    "expected_quantity" numeric DEFAULT 0 NOT NULL,
    "received_quantity" numeric DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "unplanned_cost" numeric DEFAULT 0,
    "quote_service_id" "uuid",
    "calculation_metadata" "jsonb",
    "is_unplanned" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."project_materials" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "quote_service_id" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "estimated_hours" numeric DEFAULT 0,
    "actual_hours" numeric DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."project_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "quote_id" "uuid",
    "title" "text" NOT NULL,
    "client_name" "text",
    "status" "text" DEFAULT 'active'::"text",
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "project_type" "text" DEFAULT 'standard'::"text" NOT NULL,
    CONSTRAINT "projects_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'completed'::"text", 'on_hold'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."quote_service_estimation_resources" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "estimation_id" "uuid" NOT NULL,
    "machine_id" "uuid" NOT NULL,
    "quantity" numeric DEFAULT 1 NOT NULL,
    "trips_per_day" numeric DEFAULT 60 NOT NULL,
    "capacity_per_trip" numeric DEFAULT 30 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "parent_resource_id" "uuid",
    "is_primary_mover" boolean DEFAULT false NOT NULL,
    "performance_per_day" numeric DEFAULT 0
);


ALTER TABLE "public"."quote_service_estimation_resources" OWNER TO "postgres";


COMMENT ON COLUMN "public"."quote_service_estimation_resources"."performance_per_day" IS 'Machine performance in Units/Day (e.g. SQFT/Day if unit is FT)';



CREATE TABLE IF NOT EXISTS "public"."quote_service_estimations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "quote_service_id" "uuid" NOT NULL,
    "topsoil_volume" numeric DEFAULT 0 NOT NULL,
    "compacted_volume" numeric DEFAULT 0 NOT NULL,
    "swell_factor" numeric DEFAULT 0.15 NOT NULL,
    "total_cy_loose" numeric DEFAULT 0 NOT NULL,
    "start_date" timestamp with time zone DEFAULT "now"() NOT NULL,
    "end_date" timestamp with time zone,
    "total_working_days" numeric,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "thickness_inches" numeric DEFAULT 0,
    "gravel_thickness_inches" numeric DEFAULT 0,
    "trench_width_inches" numeric(10,2) DEFAULT 0,
    "trench_depth_inches" numeric(10,2) DEFAULT 0
);


ALTER TABLE "public"."quote_service_estimations" OWNER TO "postgres";


COMMENT ON COLUMN "public"."quote_service_estimations"."thickness_inches" IS 'Earth layer thickness in inches for SQFT-based calculations';



COMMENT ON COLUMN "public"."quote_service_estimations"."gravel_thickness_inches" IS 'Gravel layer thickness in inches for SQFT-based calculations';



CREATE TABLE IF NOT EXISTS "public"."quote_service_instruments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "quote_service_id" "uuid" NOT NULL,
    "instrument_id" "uuid",
    "instrument_name" "text",
    "quantity" numeric DEFAULT 1 NOT NULL,
    "unit_price" numeric DEFAULT 0 NOT NULL,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "days" numeric DEFAULT 1 NOT NULL,
    "total_cost" numeric GENERATED ALWAYS AS ((("quantity" * "unit_price") * "days")) STORED
);


ALTER TABLE "public"."quote_service_instruments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."quote_service_labors" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "quote_service_id" "uuid" NOT NULL,
    "role_id" "uuid",
    "months_to_work" numeric DEFAULT 0 NOT NULL,
    "employees_quantity" numeric DEFAULT 1 NOT NULL,
    "hourly_rate" numeric DEFAULT 0 NOT NULL,
    "per_diem" numeric DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "role_name" "text"
);


ALTER TABLE "public"."quote_service_labors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."quote_service_machineries" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "quote_service_id" "uuid" NOT NULL,
    "machine_name" "text" DEFAULT ''::"text" NOT NULL,
    "months_to_use" numeric DEFAULT 0 NOT NULL,
    "monthly_rent_cost" numeric DEFAULT 0 NOT NULL,
    "quantity" numeric DEFAULT 1 NOT NULL,
    "gallons_per_hour" numeric DEFAULT 0 NOT NULL,
    "gallon_cost" numeric DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "delivery_cost" numeric DEFAULT 0,
    "parent_machinery_id" "uuid",
    "is_primary" boolean DEFAULT true NOT NULL,
    "is_primary_mover" boolean DEFAULT true,
    "parent_machine_name" character varying
);


ALTER TABLE "public"."quote_service_machineries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."quote_service_materials" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "quote_service_id" "uuid" NOT NULL,
    "material_id" "uuid",
    "material_name" "text",
    "unit_name" "text",
    "quantity" numeric DEFAULT 0 NOT NULL,
    "unit_price" numeric DEFAULT 0 NOT NULL,
    "total_cost" numeric GENERATED ALWAYS AS (("quantity" * "unit_price")) STORED,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "layer_type" "text" DEFAULT 'earth'::"text"
);


ALTER TABLE "public"."quote_service_materials" OWNER TO "postgres";


COMMENT ON COLUMN "public"."quote_service_materials"."layer_type" IS 'Which calculation layer this material belongs to: earth or gravel';



CREATE TABLE IF NOT EXISTS "public"."quote_services" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "quote_id" "uuid" NOT NULL,
    "service_number" "text",
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "unit_of_measure" "text" DEFAULT 'und'::"text" NOT NULL,
    "quantity" numeric DEFAULT 1 NOT NULL,
    "overhead_percentage" numeric DEFAULT 0 NOT NULL,
    "profit_percentage" numeric DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "fuel_price" numeric DEFAULT 0,
    "per_diem_cost" numeric DEFAULT 0,
    "labor_hours_per_month" numeric DEFAULT 0,
    "direct_cost" numeric DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."quote_services" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."quotes" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid",
    "title" "text" DEFAULT 'Nueva Cotización'::"text" NOT NULL,
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "client_name" "text",
    "total_amount" numeric DEFAULT 0,
    "quote_date" "date" DEFAULT CURRENT_DATE,
    "project_name" "text",
    "quote_type" "text" DEFAULT 'standard'::"text" NOT NULL
);


ALTER TABLE "public"."quotes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."services" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "description" "text" NOT NULL,
    "unit" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."services" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."worker_role_history" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "worker_id" "uuid" NOT NULL,
    "previous_role_id" "uuid",
    "new_role_id" "uuid",
    "previous_hourly_rate" numeric,
    "changed_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."worker_role_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."workers" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "id_number" "text",
    "full_name" "text" NOT NULL,
    "hire_date" "date",
    "phone" "text",
    "email" "text",
    "status" "text" DEFAULT 'Active'::"text" NOT NULL,
    "role_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."workers" OWNER TO "postgres";


ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."labor_checkins"
    ADD CONSTRAINT "labor_checkins_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."labor_roles"
    ADD CONSTRAINT "labor_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."logistics_applications"
    ADD CONSTRAINT "logistics_applications_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."logistics_applications"
    ADD CONSTRAINT "logistics_applications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."logistics_equipment"
    ADD CONSTRAINT "logistics_equipment_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."machinery_applications"
    ADD CONSTRAINT "machinery_applications_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."machinery_applications"
    ADD CONSTRAINT "machinery_applications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."machinery_inspections"
    ADD CONSTRAINT "machinery_inspections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."machinery"
    ADD CONSTRAINT "machinery_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."material_receptions"
    ADD CONSTRAINT "material_receptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."materials"
    ADD CONSTRAINT "materials_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_instruments"
    ADD CONSTRAINT "project_instruments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_labor_assignments"
    ADD CONSTRAINT "project_labor_assignments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_labor_assignments"
    ADD CONSTRAINT "project_labor_assignments_project_labor_id_worker_id_key" UNIQUE ("project_labor_id", "worker_id");



ALTER TABLE ONLY "public"."project_labor"
    ADD CONSTRAINT "project_labor_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_machinery"
    ADD CONSTRAINT "project_machinery_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_materials"
    ADD CONSTRAINT "project_materials_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_tasks"
    ADD CONSTRAINT "project_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quote_service_estimation_resources"
    ADD CONSTRAINT "quote_service_estimation_resources_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quote_service_estimations"
    ADD CONSTRAINT "quote_service_estimations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quote_service_instruments"
    ADD CONSTRAINT "quote_service_instruments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quote_service_labors"
    ADD CONSTRAINT "quote_service_labors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quote_service_machineries"
    ADD CONSTRAINT "quote_service_machineries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quote_service_materials"
    ADD CONSTRAINT "quote_service_materials_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quote_services"
    ADD CONSTRAINT "quote_services_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quotes"
    ADD CONSTRAINT "quotes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."worker_role_history"
    ADD CONSTRAINT "worker_role_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."workers"
    ADD CONSTRAINT "workers_id_number_key" UNIQUE ("id_number");



ALTER TABLE ONLY "public"."workers"
    ADD CONSTRAINT "workers_pkey" PRIMARY KEY ("id");



CREATE OR REPLACE TRIGGER "labor_roles_updated_at" BEFORE UPDATE ON "public"."labor_roles" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "machinery_updated_at" BEFORE UPDATE ON "public"."machinery" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "on_checkin_completion" AFTER UPDATE ON "public"."labor_checkins" FOR EACH ROW EXECUTE FUNCTION "public"."handle_checkin_completion"();



CREATE OR REPLACE TRIGGER "on_labor_checkin_change" AFTER INSERT OR DELETE OR UPDATE ON "public"."labor_checkins" FOR EACH ROW EXECUTE FUNCTION "public"."handle_labor_checkin_changes"();



CREATE OR REPLACE TRIGGER "quote_service_estimations_updated_at" BEFORE UPDATE ON "public"."quote_service_estimations" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "services_updated_at" BEFORE UPDATE ON "public"."services" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "track_worker_role_changes" AFTER UPDATE ON "public"."workers" FOR EACH ROW EXECUTE FUNCTION "public"."handle_worker_role_change"();



CREATE OR REPLACE TRIGGER "trigger_machinery_operator_assignment" AFTER INSERT ON "public"."project_machinery" FOR EACH ROW EXECUTE FUNCTION "public"."handle_machinery_operator_assignment"();



CREATE OR REPLACE TRIGGER "update_materials_modtime" BEFORE UPDATE ON "public"."materials" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "update_project_instruments_modtime" BEFORE UPDATE ON "public"."project_instruments" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "update_quote_service_instruments_modtime" BEFORE UPDATE ON "public"."quote_service_instruments" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "update_quote_service_materials_modtime" BEFORE UPDATE ON "public"."quote_service_materials" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "workers_updated_at" BEFORE UPDATE ON "public"."workers" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



ALTER TABLE ONLY "public"."labor_checkins"
    ADD CONSTRAINT "labor_checkins_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."labor_checkins"
    ADD CONSTRAINT "labor_checkins_project_labor_id_fkey" FOREIGN KEY ("project_labor_id") REFERENCES "public"."project_labor"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."labor_checkins"
    ADD CONSTRAINT "labor_checkins_project_task_id_fkey" FOREIGN KEY ("project_task_id") REFERENCES "public"."project_tasks"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."labor_checkins"
    ADD CONSTRAINT "labor_checkins_worker_id_fkey" FOREIGN KEY ("worker_id") REFERENCES "public"."workers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."machinery_inspections"
    ADD CONSTRAINT "machinery_inspections_project_machinery_id_fkey" FOREIGN KEY ("project_machinery_id") REFERENCES "public"."project_machinery"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."machinery_inspections"
    ADD CONSTRAINT "machinery_inspections_received_by_fkey" FOREIGN KEY ("received_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."machinery"
    ADD CONSTRAINT "machinery_operator_role_id_fkey" FOREIGN KEY ("operator_role_id") REFERENCES "public"."labor_roles"("id");



ALTER TABLE ONLY "public"."material_receptions"
    ADD CONSTRAINT "material_receptions_project_material_id_fkey" FOREIGN KEY ("project_material_id") REFERENCES "public"."project_materials"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."material_receptions"
    ADD CONSTRAINT "material_receptions_received_by_fkey" FOREIGN KEY ("received_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."project_instruments"
    ADD CONSTRAINT "project_instruments_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_instruments"
    ADD CONSTRAINT "project_instruments_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id");



ALTER TABLE ONLY "public"."project_instruments"
    ADD CONSTRAINT "project_instruments_quote_service_instrument_id_fkey" FOREIGN KEY ("quote_service_instrument_id") REFERENCES "public"."quote_service_instruments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."project_labor_assignments"
    ADD CONSTRAINT "project_labor_assignments_project_labor_id_fkey" FOREIGN KEY ("project_labor_id") REFERENCES "public"."project_labor"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_labor_assignments"
    ADD CONSTRAINT "project_labor_assignments_worker_id_fkey" FOREIGN KEY ("worker_id") REFERENCES "public"."workers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_labor"
    ADD CONSTRAINT "project_labor_linked_machinery_id_fkey" FOREIGN KEY ("linked_machinery_id") REFERENCES "public"."project_machinery"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_labor"
    ADD CONSTRAINT "project_labor_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_labor"
    ADD CONSTRAINT "project_labor_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id");



ALTER TABLE ONLY "public"."project_labor"
    ADD CONSTRAINT "project_labor_quote_service_labor_id_fkey" FOREIGN KEY ("quote_service_labor_id") REFERENCES "public"."quote_service_labors"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."project_machinery"
    ADD CONSTRAINT "project_machinery_parent_machinery_id_fkey" FOREIGN KEY ("parent_machinery_id") REFERENCES "public"."project_machinery"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_machinery"
    ADD CONSTRAINT "project_machinery_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_machinery"
    ADD CONSTRAINT "project_machinery_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id");



ALTER TABLE ONLY "public"."project_machinery"
    ADD CONSTRAINT "project_machinery_quote_service_machinery_id_fkey" FOREIGN KEY ("quote_service_machinery_id") REFERENCES "public"."quote_service_machineries"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."project_materials"
    ADD CONSTRAINT "project_materials_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_materials"
    ADD CONSTRAINT "project_materials_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id");



ALTER TABLE ONLY "public"."project_materials"
    ADD CONSTRAINT "project_materials_quote_service_material_id_fkey" FOREIGN KEY ("quote_service_material_id") REFERENCES "public"."quote_service_materials"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."project_tasks"
    ADD CONSTRAINT "project_tasks_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_tasks"
    ADD CONSTRAINT "project_tasks_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_quote_id_fkey" FOREIGN KEY ("quote_id") REFERENCES "public"."quotes"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."quote_service_estimation_resources"
    ADD CONSTRAINT "quote_service_estimation_resources_estimation_id_fkey" FOREIGN KEY ("estimation_id") REFERENCES "public"."quote_service_estimations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_service_estimation_resources"
    ADD CONSTRAINT "quote_service_estimation_resources_machine_id_fkey" FOREIGN KEY ("machine_id") REFERENCES "public"."machinery"("id");



ALTER TABLE ONLY "public"."quote_service_estimation_resources"
    ADD CONSTRAINT "quote_service_estimation_resources_parent_resource_id_fkey" FOREIGN KEY ("parent_resource_id") REFERENCES "public"."quote_service_estimation_resources"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_service_estimations"
    ADD CONSTRAINT "quote_service_estimations_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_service_instruments"
    ADD CONSTRAINT "quote_service_instruments_instrument_id_fkey" FOREIGN KEY ("instrument_id") REFERENCES "public"."logistics_equipment"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."quote_service_instruments"
    ADD CONSTRAINT "quote_service_instruments_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_service_labors"
    ADD CONSTRAINT "quote_service_labors_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_service_labors"
    ADD CONSTRAINT "quote_service_labors_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id");



ALTER TABLE ONLY "public"."quote_service_machineries"
    ADD CONSTRAINT "quote_service_machineries_parent_machinery_id_fkey" FOREIGN KEY ("parent_machinery_id") REFERENCES "public"."quote_service_machineries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_service_machineries"
    ADD CONSTRAINT "quote_service_machineries_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_service_materials"
    ADD CONSTRAINT "quote_service_materials_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "public"."materials"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."quote_service_materials"
    ADD CONSTRAINT "quote_service_materials_quote_service_id_fkey" FOREIGN KEY ("quote_service_id") REFERENCES "public"."quote_services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quote_services"
    ADD CONSTRAINT "quote_services_quote_id_fkey" FOREIGN KEY ("quote_id") REFERENCES "public"."quotes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."worker_role_history"
    ADD CONSTRAINT "worker_role_history_new_role_id_fkey" FOREIGN KEY ("new_role_id") REFERENCES "public"."labor_roles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."worker_role_history"
    ADD CONSTRAINT "worker_role_history_previous_role_id_fkey" FOREIGN KEY ("previous_role_id") REFERENCES "public"."labor_roles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."worker_role_history"
    ADD CONSTRAINT "worker_role_history_worker_id_fkey" FOREIGN KEY ("worker_id") REFERENCES "public"."workers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."workers"
    ADD CONSTRAINT "workers_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."labor_roles"("id") ON DELETE SET NULL;



CREATE POLICY "Admins can delete any profile." ON "public"."profiles" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "profiles_1"
  WHERE (("profiles_1"."id" = "auth"."uid"()) AND ("profiles_1"."role" = 'Admin'::"text")))));



CREATE POLICY "Admins can insert any profile." ON "public"."profiles" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "profiles_1"
  WHERE (("profiles_1"."id" = "auth"."uid"()) AND ("profiles_1"."role" = 'Admin'::"text")))));



CREATE POLICY "Admins can update any profile." ON "public"."profiles" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "profiles_1"
  WHERE (("profiles_1"."id" = "auth"."uid"()) AND ("profiles_1"."role" = 'Admin'::"text")))));



CREATE POLICY "Allow all actions for authenticated users on customers" ON "public"."customers" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on labor_checkins" ON "public"."labor_checkins" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on labor_roles" ON "public"."labor_roles" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on logistics_applicat" ON "public"."logistics_applications" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on logistics_equipmen" ON "public"."logistics_equipment" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on machinery" ON "public"."machinery" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on machinery_applicat" ON "public"."machinery_applications" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on project_labor" ON "public"."project_labor" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on project_tasks" ON "public"."project_tasks" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on quote_service_esti" ON "public"."quote_service_estimation_resources" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on quote_service_esti" ON "public"."quote_service_estimations" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on quote_service_labo" ON "public"."quote_service_labors" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on quote_service_mach" ON "public"."quote_service_machineries" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on quote_services" ON "public"."quote_services" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on quotes" ON "public"."quotes" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on services" ON "public"."services" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on worker_role_histor" ON "public"."worker_role_history" TO "authenticated" USING (true);



CREATE POLICY "Allow all actions for authenticated users on workers" ON "public"."workers" TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can delete roles." ON "public"."roles" FOR DELETE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Authenticated users can insert roles." ON "public"."roles" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Authenticated users can update roles." ON "public"."roles" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable all access for authenticated users on machinery_inspecti" ON "public"."machinery_inspections" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable all access for authenticated users on material_reception" ON "public"."material_receptions" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Enable all access for authenticated users on project_machinery" ON "public"."project_machinery" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable all access for authenticated users on project_materials" ON "public"."project_materials" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Enable all access for authenticated users on projects" ON "public"."projects" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable all access for materials" ON "public"."materials" USING (true) WITH CHECK (true);



CREATE POLICY "Enable all access for project_instruments" ON "public"."project_instruments" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable all access for quote_service_instruments" ON "public"."quote_service_instruments" USING (true) WITH CHECK (true);



CREATE POLICY "Enable all access for quote_service_materials" ON "public"."quote_service_materials" USING (true) WITH CHECK (true);



CREATE POLICY "Public profiles are viewable by everyone." ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Roles are viewable by everyone." ON "public"."roles" FOR SELECT USING (true);



CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "allow_all_assignments" ON "public"."project_labor_assignments" TO "authenticated" USING (true);



ALTER TABLE "public"."customers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."labor_checkins" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."labor_roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."logistics_applications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."logistics_equipment" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."machinery" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."machinery_applications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."machinery_inspections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."material_receptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."materials" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."project_instruments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."project_labor" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."project_labor_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."project_machinery" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."project_materials" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."project_tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."projects" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."quote_service_estimation_resources" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."quote_service_estimations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."quote_service_instruments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."quote_service_labors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."quote_service_machineries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."quote_service_materials" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."quote_services" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."quotes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."services" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."worker_role_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."workers" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";































































































































































GRANT ALL ON FUNCTION "public"."handle_checkin_completion"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_checkin_completion"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_checkin_completion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_labor_checkin_changes"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_labor_checkin_changes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_labor_checkin_changes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_machinery_operator_assignment"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_machinery_operator_assignment"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_machinery_operator_assignment"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_worker_role_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_worker_role_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_worker_role_change"() TO "service_role";


















GRANT ALL ON TABLE "public"."customers" TO "anon";
GRANT ALL ON TABLE "public"."customers" TO "authenticated";
GRANT ALL ON TABLE "public"."customers" TO "service_role";



GRANT ALL ON TABLE "public"."labor_checkins" TO "anon";
GRANT ALL ON TABLE "public"."labor_checkins" TO "authenticated";
GRANT ALL ON TABLE "public"."labor_checkins" TO "service_role";



GRANT ALL ON TABLE "public"."labor_roles" TO "anon";
GRANT ALL ON TABLE "public"."labor_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."labor_roles" TO "service_role";



GRANT ALL ON TABLE "public"."logistics_applications" TO "anon";
GRANT ALL ON TABLE "public"."logistics_applications" TO "authenticated";
GRANT ALL ON TABLE "public"."logistics_applications" TO "service_role";



GRANT ALL ON TABLE "public"."logistics_equipment" TO "anon";
GRANT ALL ON TABLE "public"."logistics_equipment" TO "authenticated";
GRANT ALL ON TABLE "public"."logistics_equipment" TO "service_role";



GRANT ALL ON TABLE "public"."machinery" TO "anon";
GRANT ALL ON TABLE "public"."machinery" TO "authenticated";
GRANT ALL ON TABLE "public"."machinery" TO "service_role";



GRANT ALL ON TABLE "public"."machinery_applications" TO "anon";
GRANT ALL ON TABLE "public"."machinery_applications" TO "authenticated";
GRANT ALL ON TABLE "public"."machinery_applications" TO "service_role";



GRANT ALL ON TABLE "public"."machinery_inspections" TO "anon";
GRANT ALL ON TABLE "public"."machinery_inspections" TO "authenticated";
GRANT ALL ON TABLE "public"."machinery_inspections" TO "service_role";



GRANT ALL ON TABLE "public"."material_receptions" TO "anon";
GRANT ALL ON TABLE "public"."material_receptions" TO "authenticated";
GRANT ALL ON TABLE "public"."material_receptions" TO "service_role";



GRANT ALL ON TABLE "public"."materials" TO "anon";
GRANT ALL ON TABLE "public"."materials" TO "authenticated";
GRANT ALL ON TABLE "public"."materials" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."project_instruments" TO "anon";
GRANT ALL ON TABLE "public"."project_instruments" TO "authenticated";
GRANT ALL ON TABLE "public"."project_instruments" TO "service_role";



GRANT ALL ON TABLE "public"."project_labor" TO "anon";
GRANT ALL ON TABLE "public"."project_labor" TO "authenticated";
GRANT ALL ON TABLE "public"."project_labor" TO "service_role";



GRANT ALL ON TABLE "public"."project_labor_assignments" TO "anon";
GRANT ALL ON TABLE "public"."project_labor_assignments" TO "authenticated";
GRANT ALL ON TABLE "public"."project_labor_assignments" TO "service_role";



GRANT ALL ON TABLE "public"."project_machinery" TO "anon";
GRANT ALL ON TABLE "public"."project_machinery" TO "authenticated";
GRANT ALL ON TABLE "public"."project_machinery" TO "service_role";



GRANT ALL ON TABLE "public"."project_materials" TO "anon";
GRANT ALL ON TABLE "public"."project_materials" TO "authenticated";
GRANT ALL ON TABLE "public"."project_materials" TO "service_role";



GRANT ALL ON TABLE "public"."project_tasks" TO "anon";
GRANT ALL ON TABLE "public"."project_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."project_tasks" TO "service_role";



GRANT ALL ON TABLE "public"."projects" TO "anon";
GRANT ALL ON TABLE "public"."projects" TO "authenticated";
GRANT ALL ON TABLE "public"."projects" TO "service_role";



GRANT ALL ON TABLE "public"."quote_service_estimation_resources" TO "anon";
GRANT ALL ON TABLE "public"."quote_service_estimation_resources" TO "authenticated";
GRANT ALL ON TABLE "public"."quote_service_estimation_resources" TO "service_role";



GRANT ALL ON TABLE "public"."quote_service_estimations" TO "anon";
GRANT ALL ON TABLE "public"."quote_service_estimations" TO "authenticated";
GRANT ALL ON TABLE "public"."quote_service_estimations" TO "service_role";



GRANT ALL ON TABLE "public"."quote_service_instruments" TO "anon";
GRANT ALL ON TABLE "public"."quote_service_instruments" TO "authenticated";
GRANT ALL ON TABLE "public"."quote_service_instruments" TO "service_role";



GRANT ALL ON TABLE "public"."quote_service_labors" TO "anon";
GRANT ALL ON TABLE "public"."quote_service_labors" TO "authenticated";
GRANT ALL ON TABLE "public"."quote_service_labors" TO "service_role";



GRANT ALL ON TABLE "public"."quote_service_machineries" TO "anon";
GRANT ALL ON TABLE "public"."quote_service_machineries" TO "authenticated";
GRANT ALL ON TABLE "public"."quote_service_machineries" TO "service_role";



GRANT ALL ON TABLE "public"."quote_service_materials" TO "anon";
GRANT ALL ON TABLE "public"."quote_service_materials" TO "authenticated";
GRANT ALL ON TABLE "public"."quote_service_materials" TO "service_role";



GRANT ALL ON TABLE "public"."quote_services" TO "anon";
GRANT ALL ON TABLE "public"."quote_services" TO "authenticated";
GRANT ALL ON TABLE "public"."quote_services" TO "service_role";



GRANT ALL ON TABLE "public"."quotes" TO "anon";
GRANT ALL ON TABLE "public"."quotes" TO "authenticated";
GRANT ALL ON TABLE "public"."quotes" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON TABLE "public"."services" TO "anon";
GRANT ALL ON TABLE "public"."services" TO "authenticated";
GRANT ALL ON TABLE "public"."services" TO "service_role";



GRANT ALL ON TABLE "public"."worker_role_history" TO "anon";
GRANT ALL ON TABLE "public"."worker_role_history" TO "authenticated";
GRANT ALL ON TABLE "public"."worker_role_history" TO "service_role";



GRANT ALL ON TABLE "public"."workers" TO "anon";
GRANT ALL ON TABLE "public"."workers" TO "authenticated";
GRANT ALL ON TABLE "public"."workers" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































