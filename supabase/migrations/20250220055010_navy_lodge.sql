/*
  # Update inventory levels schema and order handling

  1. Changes
    - Add order_required boolean column to inventory_levels table
    - Add order_quantity column to inventory_levels table that can be NULL
    - Add trigger to automatically update order_required based on current_level and batch_requirement
  
  2. Security
    - Maintain existing RLS policies
*/

-- Add new columns to inventory_levels
ALTER TABLE inventory_levels
ADD COLUMN IF NOT EXISTS order_required boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS order_quantity numeric DEFAULT NULL;

-- Create function to calculate if order is required
CREATE OR REPLACE FUNCTION calculate_order_required()
RETURNS TRIGGER AS $$
DECLARE
  v_batch_requirement numeric;
BEGIN
  -- Get the batch requirement for this ingredient
  SELECT batch_requirement INTO v_batch_requirement
  FROM flavor_ingredients
  WHERE ingredient_id = NEW.ingredient_id
  LIMIT 1;

  -- Set order_required based on current level vs batch requirement
  IF v_batch_requirement IS NOT NULL THEN
    NEW.order_required := NEW.current_level < v_batch_requirement;
    
    -- If order is not required, set order_quantity to NULL
    IF NOT NEW.order_required THEN
      NEW.order_quantity := NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update order_required
DROP TRIGGER IF EXISTS update_order_required ON inventory_levels;
CREATE TRIGGER update_order_required
  BEFORE INSERT OR UPDATE OF current_level
  ON inventory_levels
  FOR EACH ROW
  EXECUTE FUNCTION calculate_order_required();

-- Update existing records
UPDATE inventory_levels il
SET 
  order_required = il.current_level < fi.batch_requirement,
  order_quantity = CASE 
    WHEN il.current_level < fi.batch_requirement THEN fi.batch_requirement - il.current_level
    ELSE NULL
  END
FROM flavor_ingredients fi
WHERE il.ingredient_id = fi.ingredient_id;