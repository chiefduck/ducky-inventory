/*
  # Update pricing tiers and MOQ handling

  1. Changes
    - Update Lime Essence pricing tiers with new structure
    - Add minimum order value and surcharge fields to suppliers
    - Update existing pricing tiers

  2. Security
    - Maintain existing RLS policies
*/

-- Add minimum order value and surcharge fields to suppliers
ALTER TABLE suppliers
ADD COLUMN min_order_value numeric DEFAULT NULL,
ADD COLUMN surcharge_amount numeric DEFAULT NULL;

-- Update Primal Essence supplier with minimum order requirements
UPDATE suppliers
SET 
  min_order_value = 200,
  surcharge_amount = 50
WHERE name = 'Primal Essence';

-- Clear existing Lime Essence pricing tiers
DELETE FROM pricing_tiers
WHERE ingredient_id = (
  SELECT id FROM ingredients WHERE name = 'Lime Essence'
);

-- Insert new Lime Essence pricing tiers
INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit)
SELECT 
  id,
  min_quantity,
  price_per_unit
FROM ingredients
CROSS JOIN (VALUES
  (0, 78.63),
  (8, 62.90),
  (40, 61.33),
  (200, 59.49)
) AS tiers(min_quantity, price_per_unit)
WHERE name = 'Lime Essence';