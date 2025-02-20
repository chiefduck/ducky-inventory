/*
  # Update ingredient requirements and pricing tiers

  1. Changes
    - Update base requirements for Classic Lime ingredients
    - Update pricing tiers with correct MOQs and prices
    - Update current inventory levels
  
  2. Data Updates
    - Ingredient base requirements for 2000 gallons
    - Multi-tier pricing for ingredients
    - Current stock levels
*/

-- Update base requirements for Classic Lime ingredients
DO $$
DECLARE
  v_classic_lime_id uuid;
BEGIN
  -- Get Classic Lime ID
  SELECT id INTO v_classic_lime_id
  FROM flavors
  WHERE name = 'Classic Lime';

  -- Update the batch requirements
  UPDATE flavor_ingredients
  SET batch_requirement = 
    CASE 
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Blue Agave Syrup Organic Light') THEN 1014.00
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Lime Juice Concentrate') THEN 422.52
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Margarita Flavor') THEN 101.40
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Salted Lime Flavor') THEN 42.25
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Orange Zest Flavor Nat Type') THEN 25.35
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Salt') THEN 13.52
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Alcohol Burn FL Nat Type') THEN 8.45
      WHEN ingredient_id = (SELECT id FROM ingredients WHERE name = 'Lime Essence') THEN 3.38
    END
  WHERE flavor_id = v_classic_lime_id;
END $$;

-- Update MOQs for ingredients
UPDATE ingredients
SET moq = 
  CASE name
    WHEN 'Blue Agave Syrup Organic Light' THEN 55
    WHEN 'Lime Juice Concentrate' THEN 53
    WHEN 'Margarita Flavor' THEN 40
    WHEN 'Salted Lime Flavor' THEN 40
    WHEN 'Orange Zest Flavor Nat Type' THEN 40
    WHEN 'Alcohol Burn FL Nat Type' THEN 40
    WHEN 'Lime Essence' THEN 3.09
    ELSE moq -- Keep existing MOQ for other ingredients
  END;

-- Clear existing pricing tiers and insert new ones
DELETE FROM pricing_tiers;

DO $$ 
DECLARE 
  v_ingredient_id uuid;
BEGIN
  -- Blue Agave Syrup Light
  SELECT id INTO v_ingredient_id FROM ingredients WHERE name = 'Blue Agave Syrup Organic Light';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (v_ingredient_id, 0, 2.18);
  END IF;

  -- Lime Juice Concentrate
  SELECT id INTO v_ingredient_id FROM ingredients WHERE name = 'Lime Juice Concentrate';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (v_ingredient_id, 0, 2.08),    -- 1-4 pails
      (v_ingredient_id, 265, 1.88),   -- 5-10 pails (5 * 53 lbs)
      (v_ingredient_id, 583, 1.78),   -- 11-35 pails (11 * 53 lbs)
      (v_ingredient_id, 1908, 1.73);  -- 36+ pails (36 * 53 lbs)
  END IF;

  -- Margarita Flavor
  SELECT id INTO v_ingredient_id FROM ingredients WHERE name = 'Margarita Flavor';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (v_ingredient_id, 0, 21.50);
  END IF;

  -- Salted Lime Flavor
  SELECT id INTO v_ingredient_id FROM ingredients WHERE name = 'Salted Lime Flavor';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (v_ingredient_id, 0, 28.50);
  END IF;

  -- Orange Zest Flavor
  SELECT id INTO v_ingredient_id FROM ingredients WHERE name = 'Orange Zest Flavor Nat Type';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (v_ingredient_id, 0, 20.15);
  END IF;

  -- Alcohol Burn
  SELECT id INTO v_ingredient_id FROM ingredients WHERE name = 'Alcohol Burn FL Nat Type';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (v_ingredient_id, 0, 47.00);
  END IF;

  -- Lime Essence
  SELECT id INTO v_ingredient_id FROM ingredients WHERE name = 'Lime Essence';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (v_ingredient_id, 0, 78.63);
  END IF;
END $$;

-- Update current inventory levels
DO $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Get the first user (for demo data)
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;

  IF v_user_id IS NOT NULL THEN
    -- Delete existing inventory levels
    DELETE FROM inventory_levels WHERE user_id = v_user_id;

    -- Insert new inventory levels
    INSERT INTO inventory_levels (ingredient_id, user_id, current_level)
    SELECT 
      ingredients.id,
      v_user_id,
      CASE ingredients.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 48.28
        WHEN 'Lime Juice Concentrate' THEN 10.36
        WHEN 'Margarita Flavor' THEN 42.77
        WHEN 'Salted Lime Flavor' THEN 30.09
        WHEN 'Orange Zest Flavor Nat Type' THEN 12.79
        WHEN 'Salt' THEN 0
        WHEN 'Alcohol Burn FL Nat Type' THEN 32.96
        WHEN 'Lime Essence' THEN 3.09
      END
    FROM ingredients
    WHERE ingredients.name IN (
      'Blue Agave Syrup Organic Light',
      'Lime Juice Concentrate',
      'Margarita Flavor',
      'Salted Lime Flavor',
      'Orange Zest Flavor Nat Type',
      'Salt',
      'Alcohol Burn FL Nat Type',
      'Lime Essence'
    );
  END IF;
END $$;