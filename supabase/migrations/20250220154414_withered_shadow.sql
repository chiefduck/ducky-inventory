/*
  # Update base requirements for Classic Lime flavor

  Updates the base requirements for the Classic Lime flavor ingredients to match
  the correct proportions for a 500 gallon batch.

  1. Changes
    - Updates batch requirements for all ingredients in the Classic Lime flavor
    - Ensures values match the correct proportions
*/

DO $$ 
DECLARE
  v_classic_lime_id uuid;
BEGIN
  -- Get Classic Lime ID
  SELECT id INTO v_classic_lime_id
  FROM flavors
  WHERE name = 'Classic Lime';

  -- Update the batch requirements for Classic Lime ingredients
  UPDATE flavor_ingredients
  SET batch_requirement = 
    CASE 
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Blue Agave Syrup Organic Light') THEN 253.5
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Lime Juice Concentrate') THEN 105.63
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Margarita Flavor') THEN 25.35
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Salted Lime Flavor') THEN 10.56
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Orange Zest Flavor Nat Type') THEN 6.34
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Salt') THEN 3.38
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Alcohol Burn FL Nat Type') THEN 2.11
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Lime Essence') THEN 0.85
    END
  WHERE flavor_id = v_classic_lime_id
  AND ingredient_id IN (
    SELECT id FROM ingredients WHERE name IN (
      'Blue Agave Syrup Organic Light',
      'Lime Juice Concentrate',
      'Margarita Flavor',
      'Salted Lime Flavor',
      'Orange Zest Flavor Nat Type',
      'Salt',
      'Alcohol Burn FL Nat Type',
      'Lime Essence'
    )
  );
END $$;