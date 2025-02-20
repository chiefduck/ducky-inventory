/*
  # Update ingredient pricing tiers

  1. Changes
    - Updates pricing tiers for all ingredients with new MOQ-based pricing
    - Ensures correct price per lb is stored for each tier
    - Adds new pricing tiers for Lime Juice Concentrate with volume discounts

  2. Details
    - Blue Agave Syrup Light: Fixed price $2.18/lb
    - Lime Juice Concentrate: Tiered pricing based on MOQ
      * $2.08/lb (MOQ 53 lbs)
      * $1.88/lb (MOQ 100+ lbs)
      * $1.78/lb (MOQ 250+ lbs)
      * $1.73/lb (MOQ 500+ lbs)
    - Margarita Flavor: Fixed price $21.50/lb
    - Salted Lime Flavor: Fixed price $28.50/lb
    - Orange Zest Flavor: Fixed price $20.15/lb
    - Alcohol Burn: Fixed price $47.00/lb
    - Lime Essence: Fixed price $78.63/lb
*/

-- First, delete existing pricing tiers
DELETE FROM pricing_tiers;

-- Insert new pricing tiers
DO $$ 
DECLARE 
  ingredient_id uuid;
BEGIN
  -- Blue Agave Syrup Organic Light
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Blue Agave Syrup Organic Light';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (ingredient_id, 0, 2.18);
  END IF;

  -- Lime Juice Concentrate
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Lime Juice Concentrate';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (ingredient_id, 0, 2.08),    -- Base price
      (ingredient_id, 100, 1.88),  -- 100+ lbs
      (ingredient_id, 250, 1.78),  -- 250+ lbs
      (ingredient_id, 500, 1.73);  -- 500+ lbs
  END IF;

  -- Margarita Flavor
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Margarita Flavor';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (ingredient_id, 0, 21.50);
  END IF;

  -- Salted Lime Flavor
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Salted Lime Flavor';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (ingredient_id, 0, 28.50);
  END IF;

  -- Orange Zest Flavor Nat Type
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Orange Zest Flavor Nat Type';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (ingredient_id, 0, 20.15);
  END IF;

  -- Alcohol Burn FL Nat Type
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Alcohol Burn FL Nat Type';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (ingredient_id, 0, 47.00);
  END IF;

  -- Lime Essence
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Lime Essence';
  IF FOUND THEN
    INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
      (ingredient_id, 0, 78.63);
  END IF;
END $$;