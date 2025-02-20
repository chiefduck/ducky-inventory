/*
  # Add missing cost columns to batch_costs table

  1. Changes
    - Add new columns to batch_costs table:
      - can_end_cost_per_unit (NUMERIC DEFAULT 0)
      - tray_cost_per_unit (NUMERIC DEFAULT 0)
      - paktech_cost_per_unit (NUMERIC DEFAULT 0)
      - storage_cost_per_unit (NUMERIC DEFAULT 0)
      - tolling_cost_per_gallon (NUMERIC DEFAULT 0)
    - Rename tolling_cost_per_batch to tolling_cost_per_gallon
*/

-- Add new columns with default values
ALTER TABLE batch_costs
ADD COLUMN IF NOT EXISTS can_end_cost_per_unit NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS tray_cost_per_unit NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS paktech_cost_per_unit NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS storage_cost_per_unit NUMERIC DEFAULT 0;

-- Rename tolling_cost_per_batch to tolling_cost_per_gallon
DO $$
BEGIN
  -- First check if the old column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'batch_costs' 
    AND column_name = 'tolling_cost_per_batch'
  ) THEN
    -- Add new column
    ALTER TABLE batch_costs ADD COLUMN tolling_cost_per_gallon NUMERIC DEFAULT 0;
    
    -- Copy data from old column to new column, converting per batch to per gallon
    UPDATE batch_costs 
    SET tolling_cost_per_gallon = tolling_cost_per_batch / NULLIF(
      (SELECT size_gallons FROM batch_sizes WHERE user_id = batch_costs.user_id LIMIT 1),
      0
    );
    
    -- Drop old column
    ALTER TABLE batch_costs DROP COLUMN tolling_cost_per_batch;
  ELSE
    -- If old column doesn't exist, just add the new one
    ALTER TABLE batch_costs ADD COLUMN IF NOT EXISTS tolling_cost_per_gallon NUMERIC DEFAULT 0;
  END IF;
END $$;