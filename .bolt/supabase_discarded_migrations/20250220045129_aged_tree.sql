/*
  # Add detailed cost components

  1. Changes
    - Add detailed packaging cost components to batch_costs table
    - Update freight costs structure
    - Add tolling cost per gallon

  2. Security
    - Maintain existing RLS policies
*/

-- Add detailed packaging cost components
ALTER TABLE batch_costs
ADD COLUMN tray_cost_per_unit numeric NOT NULL DEFAULT 0,
ADD COLUMN paktech_cost_per_unit numeric NOT NULL DEFAULT 0,
ADD COLUMN can_end_cost_per_unit numeric NOT NULL DEFAULT 0,
ADD COLUMN storage_cost_per_unit numeric NOT NULL DEFAULT 0,
ADD COLUMN tolling_cost_per_gallon numeric NOT NULL DEFAULT 0;

-- Drop old tolling cost column
ALTER TABLE batch_costs
DROP COLUMN tolling_cost_per_batch;