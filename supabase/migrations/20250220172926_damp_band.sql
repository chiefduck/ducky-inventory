/*
  # Update Lime Essence pricing tiers

  1. Changes
    - Update pricing tiers for Lime Essence with correct ranges and prices
    - Add tier ranges for Lime Essence specific quantities
*/

-- First, add new tier ranges for Lime Essence
WITH volume_type AS (
  SELECT id FROM pricing_tier_types WHERE name = 'volume'
)
INSERT INTO pricing_tier_ranges (tier_type_id, min_quantity, max_quantity, name)
SELECT 
  volume_type.id,
  min_quantity,
  max_quantity,
  name
FROM volume_type, (VALUES
  (0, 7.99, 'Under 8 lbs'),
  (8, 39.99, '8-39 lbs'),
  (40, 199.99, '40-199 lbs'),
  (200, NULL, '200+ lbs')
) AS ranges(min_quantity, max_quantity, name)
WHERE NOT EXISTS (
  SELECT 1 FROM pricing_tier_ranges 
  WHERE min_quantity IN (0, 8, 40, 200)
  AND name LIKE '%lbs%'
);

-- Update Lime Essence pricing tiers
WITH lime_essence AS (
  SELECT id FROM ingredients WHERE name = 'Lime Essence'
),
volume_type AS (
  SELECT id FROM pricing_tier_types WHERE name = 'volume'
)
DELETE FROM pricing_tiers
WHERE ingredient_id = (SELECT id FROM lime_essence);

WITH lime_essence AS (
  SELECT id FROM ingredients WHERE name = 'Lime Essence'
),
volume_type AS (
  SELECT id FROM pricing_tier_types WHERE name = 'volume'
)
INSERT INTO pricing_tiers (
  ingredient_id,
  min_quantity,
  price_per_unit,
  tier_type_id,
  tier_range_id
)
SELECT 
  lime_essence.id,
  r.min_quantity,
  p.price,
  volume_type.id,
  r.id
FROM lime_essence, volume_type,
LATERAL (
  SELECT * FROM pricing_tier_ranges r
  WHERE r.tier_type_id = volume_type.id
  AND r.min_quantity IN (0, 8, 40, 200)
) r,
LATERAL (
  SELECT 
    CASE r.min_quantity
      WHEN 0 THEN 78.63
      WHEN 8 THEN 62.90
      WHEN 40 THEN 61.33
      WHEN 200 THEN 59.49
    END as price
) p;