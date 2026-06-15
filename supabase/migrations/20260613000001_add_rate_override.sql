ALTER TABLE report_machinery_logs ADD COLUMN IF NOT EXISTS rate_override NUMERIC;

COMMENT ON COLUMN report_machinery_logs.rate_override IS 'Hourly rate override when a lower-rate worker operates higher-rate machinery. Used in payroll uplift calculation.';
