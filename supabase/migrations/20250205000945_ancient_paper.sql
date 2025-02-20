/*
  # Add Classic Lime ingredients data

  1. New Data
    - Add new supplier "Primal Essence"
    - Add ingredients for Classic Lime flavor
    - Add pricing tiers for each ingredient
    - Link ingredients to Classic Lime flavor with batch requirements

  2. Changes
    - Insert new supplier
    - Insert ingredients with their MOQs and units
    - Insert pricing tiers for each ingredient
    - Insert flavor-ingredient relationships with batch requirements
*/

-- Insert new supplier
INSERT INTO suppliers (name, contact_info)
VALUES ('Primal Essence', 'contact@primalessence.com');

-- Insert ingredients
INSERT INTO ingredients (name, supplier_id, moq, unit) VALUES
  ('Blue Agave Syrup Organic Light', (SELECT id FROM suppliers WHERE name = 'Bakers Authority'), 55, 'lbs'),
  ('Lime Juice Concentrate', (SELECT id FROM suppliers WHERE name = 'Greenwood Associates'), 53, 'lbs'),
  ('Margarita Flavor', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 40, 'lbs'),
  ('Salted Lime Flavor', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 40, 'lbs'),
  ('Orange Zest Flavor Nat Type', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 40, 'lbs'),
  ('Salt', (SELECT id FROM suppliers WHERE name = 'Quantum Source'), 1, 'lbs'),
  ('Alcohol Burn FL Nat Type', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 40, 'lbs'),
  ('Lime Essence', (SELECT id FROM suppliers WHERE name = 'Primal Essence'), 3.09, 'lbs');

-- Insert pricing tiers
DO $$ 
DECLARE 
  ingredient_id uuid;
BEGIN
  -- Blue Agave Syrup Organic Light
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Blue Agave Syrup Organic Light';
  INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
    (ingredient_id, 0, 2.18);

  -- Lime Juice Concentrate
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Lime Juice Concentrate';
  INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
    (ingredient_id, 0, 2.08),
    (ingredient_id, 265, 1.88),    -- 5 pails * 53 lbs
    (ingredient_id, 583, 1.78),    -- 11 pails * 53 lbs
    (ingredient_id, 1908, 1.73);   -- 36 pails * 53 lbs

  -- Margarita Flavor
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Margarita Flavor';
  INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
    (ingredient_id, 0, 21.50);

  -- Salted Lime Flavor
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Salted Lime Flavor';
  INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
    (ingredient_id, 0, 28.50);

  -- Orange Zest Flavor Nat Type
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Orange Zest Flavor Nat Type';
  INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
    (ingredient_id, 0, 20.15);

  -- Alcohol Burn FL Nat Type
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Alcohol Burn FL Nat Type';
  INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
    (ingredient_id, 0, 47.00);

  -- Lime Essence
  SELECT id INTO ingredient_id FROM ingredients WHERE name = 'Lime Essence';
  INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit) VALUES
    (ingredient_id, 0, 78.63);
END $$;

-- Link ingredients to Classic Lime flavor with batch requirements
DO $$
DECLARE
  flavor_id uuid;
BEGIN
  SELECT id INTO flavor_id FROM flavors WHERE name = 'Classic Lime';
  
  INSERT INTO flavor_ingredients (flavor_id, ingredient_id, batch_requirement)
  SELECT 
    flavor_id,
    ingredients.id,
    CASE ingredients.name
      WHEN 'Blue Agave Syrup Organic Light' THEN 1014
      WHEN 'Lime Juice Concentrate' THEN 422.52
      WHEN 'Margarita Flavor' THEN 101.4
      WHEN 'Salted Lime Flavor' THEN 42.25
      WHEN 'Orange Zest Flavor Nat Type' THEN 25.35
      WHEN 'Salt' THEN 13.52
      WHEN 'Alcohol Burn FL Nat Type' THEN 8.45
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
END $$;