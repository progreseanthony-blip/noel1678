-- Migration to support linear feet (LF) estimation (e.g. trenching, pipes)
ALTER TABLE quote_service_estimations 
ADD COLUMN IF NOT EXISTS trench_width_inches DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS trench_depth_inches DECIMAL(10,2) DEFAULT 0;
