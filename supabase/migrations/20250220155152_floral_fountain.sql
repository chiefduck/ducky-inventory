/*
  # Add ingredient percentages and densities

  1. Changes
    - Add percentage and density columns to flavor_ingredients table
    - Update Classic Lime ingredient percentages and densities
    - Add check constraints for valid percentages and densities

  2. Data Updates
    - Set percentages for Classic Lime ingredients
    - Set default densities for ingredients
*/

-- Add new columns to flavor_ingredients
ALTER TABLE flavor_ingredients
ADD COLUMN percentage numeric NOT NULL DEFAULT 0,
ADD COLUMN density numeric DEFAULT NULL;

-- Add check constraints
ALTER TABLE flavor_ingredients
ADD CONSTRAINT valid_percentage CHECK (percentage >= 0 AND percentage <= 100),
ADD CONSTRAINT valid_density CHECK (density > 0 OR density IS NULL);

-- Update Classic Lime ingredient percentages and densities
DO $$
DECLARE
  v_classic_lime_id uuid;
BEGIN
  -- Get Classic Lime ID
  SELECT id INTO v_classic_lime_id
  FROM flavors
  WHERE name = 'Classic Lime';

  -- Update percentages and densities
  UPDATE flavor_ingredients
  SET 
    percentage = 
      CASE 
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Filtered Water') THEN 90.35
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Blue Agave Syrup Organic Light') THEN 6.00
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Lime Juice Concentrate') THEN 2.50
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Margarita Flavor') THEN 0.60
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Salted Lime Flavor') THEN 0.25
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Orange Zest Flavor Nat Type') THEN 0.15
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Salt') THEN 0.08
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Alcohol Burn FL Nat Type') THEN 0.05
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Lime Essence') THEN 0.02
      END,
    density = 
      CASE 
        WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Filtered Water') THEN 8.345
        ELSE 8.450  -- Default density for other ingredients
      END
  WHERE flavor_id = v_classic_lime_id;
END $$;