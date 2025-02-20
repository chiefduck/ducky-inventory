/*
  # Fix salt pricing and update pricing tiers

  1. Changes
    - Update salt pricing to correct value
    - Add pricing tier for salt
    - Clean up any invalid pricing tiers
*/

-- First, clean up any invalid pricing tiers
DELETE FROM pricing_tiers
WHERE price_per_unit <= 0;

-- Update salt pricing
WITH salt_ingredient AS (
  SELECT id FROM ingredients WHERE name = 'Salt'
),
standard_type AS (
  SELECT id FROM pricing_tier_types WHERE name = 'standard'
)
INSERT INTO pricing_tiers (
  ingredient_id,
  min_quantity,
  price_per_unit,
  tier_type_id
)
SELECT 
  salt_ingredient.id,
  0,
  0.85, -- Set correct salt price per pound
  standard_type.id
FROM salt_ingredient, standard_type
WHERE NOT EXISTS (
  SELECT 1 FROM pricing_tiers 
  WHERE ingredient_id = salt_ingredient.id
);