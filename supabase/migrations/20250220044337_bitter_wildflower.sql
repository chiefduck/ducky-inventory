/*
  # Add batch calculation support

  1. Changes
    - Add base_batch_size column to flavors table to store reference batch size
    - Add function to calculate scaled ingredient quantities
    - Update flavor_ingredients to reference base quantities

  2. Security
    - Maintain existing RLS policies
*/

-- Add base batch size to flavors
ALTER TABLE flavors
ADD COLUMN base_batch_size_gallons numeric NOT NULL DEFAULT 500;

-- Create function to calculate scaled quantities
CREATE OR REPLACE FUNCTION calculate_scaled_quantity(
  base_quantity numeric,
  base_batch_size numeric,
  target_batch_size numeric
) RETURNS numeric AS $$
BEGIN
  RETURN ROUND((base_quantity * target_batch_size / base_batch_size)::numeric, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;