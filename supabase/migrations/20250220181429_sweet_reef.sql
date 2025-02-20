/*
  # Add New Flavor Ingredients and Update Proportions

  1. New Ingredients
    - Adds all required ingredients for:
      - Watermelon Jalapeno
      - Passionfruit Guava
      - Blueberry Mint
      - Strawberry
    - Each ingredient includes:
      - Correct proportions and densities
      - MOQ and supplier relationships
      - Part numbers for tracking

  2. Updates
    - Sets proper batch requirements
    - Configures pricing tiers
    - Links ingredients to flavors
*/

-- Add new ingredients
INSERT INTO ingredients (name, moq, unit, supplier_id, part_number)
SELECT
  name, moq, unit, supplier_id, part_number
FROM (
  VALUES
    -- Watermelon Jalapeno ingredients
    ('Watermelon Juice Concentrate 65 Brix', 53, 'lbs', (SELECT id FROM suppliers WHERE name = 'Greenwood Associates'), 'WJC-001'),
    ('Watermelon Flavor Natural WONF', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'WFN-001'),
    ('Jalapeno No Heat Flavor Natural Type', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'JNH-001'),
    ('Capsicum Extract Natural WONF', 20, 'lbs', (SELECT id FROM suppliers WHERE name = 'Primal Essence'), 'CEX-001'),
    
    -- Passionfruit Guava ingredients
    ('Guava Juice Concentrate Clarified 65 Brix', 53, 'lbs', (SELECT id FROM suppliers WHERE name = 'Greenwood Associates'), 'GJC-001'),
    ('Passionfruit Flavor Natural WONF', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'PFN-001'),
    
    -- Blueberry Mint ingredients
    ('Blueberry Juice Concentrate 65 Brix', 53, 'lbs', (SELECT id FROM suppliers WHERE name = 'Greenwood Associates'), 'BJC-001'),
    ('Blueberry Flavor Natural WONF', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'BFN-001'),
    ('Spearmint Flavor Extract Natural', 20, 'lbs', (SELECT id FROM suppliers WHERE name = 'Primal Essence'), 'SFE-001'),
    
    -- Strawberry ingredients
    ('Strawberry Juice Concentrate 65 Brix', 53, 'lbs', (SELECT id FROM suppliers WHERE name = 'Greenwood Associates'), 'SJC-001'),
    ('Natural Strawberry Flavor WONF', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'NSF-001')
) AS new_ingredients(name, moq, unit, supplier_id, part_number)
WHERE NOT EXISTS (
  SELECT 1 FROM ingredients WHERE name = new_ingredients.name
);

-- Add pricing tiers for new ingredients
WITH standard_type AS (
  SELECT id FROM pricing_tier_types WHERE name = 'standard'
)
INSERT INTO pricing_tiers (ingredient_id, min_quantity, price_per_unit, tier_type_id)
SELECT 
  i.id,
  0,
  CASE i.name
    -- Watermelon Jalapeno components
    WHEN 'Watermelon Juice Concentrate 65 Brix' THEN 2.15
    WHEN 'Watermelon Flavor Natural WONF' THEN 28.50
    WHEN 'Jalapeno No Heat Flavor Natural Type' THEN 32.75
    WHEN 'Capsicum Extract Natural WONF' THEN 85.50
    
    -- Passionfruit Guava components
    WHEN 'Guava Juice Concentrate Clarified 65 Brix' THEN 2.35
    WHEN 'Passionfruit Flavor Natural WONF' THEN 31.25
    
    -- Blueberry Mint components
    WHEN 'Blueberry Juice Concentrate 65 Brix' THEN 2.45
    WHEN 'Blueberry Flavor Natural WONF' THEN 29.75
    WHEN 'Spearmint Flavor Extract Natural' THEN 72.50
    
    -- Strawberry components
    WHEN 'Strawberry Juice Concentrate 65 Brix' THEN 2.25
    WHEN 'Natural Strawberry Flavor WONF' THEN 27.85
  END,
  standard_type.id
FROM ingredients i, standard_type
WHERE i.name IN (
  'Watermelon Juice Concentrate 65 Brix',
  'Watermelon Flavor Natural WONF',
  'Jalapeno No Heat Flavor Natural Type',
  'Capsicum Extract Natural WONF',
  'Guava Juice Concentrate Clarified 65 Brix',
  'Passionfruit Flavor Natural WONF',
  'Blueberry Juice Concentrate 65 Brix',
  'Blueberry Flavor Natural WONF',
  'Spearmint Flavor Extract Natural',
  'Strawberry Juice Concentrate 65 Brix',
  'Natural Strawberry Flavor WONF'
)
AND NOT EXISTS (
  SELECT 1 FROM pricing_tiers 
  WHERE ingredient_id = i.id
);

-- Link ingredients to flavors with correct proportions
DO $$
DECLARE
  v_watermelon_jalapeno_id uuid;
  v_passionfruit_guava_id uuid;
  v_blueberry_mint_id uuid;
  v_strawberry_id uuid;
BEGIN
  -- Get flavor IDs
  SELECT id INTO v_watermelon_jalapeno_id FROM flavors WHERE name = 'Watermelon Jalapeno';
  SELECT id INTO v_passionfruit_guava_id FROM flavors WHERE name = 'Passionfruit Guava';
  SELECT id INTO v_blueberry_mint_id FROM flavors WHERE name = 'Blueberry Mint';
  SELECT id INTO v_strawberry_id FROM flavors WHERE name = 'Strawberry';

  -- Add Watermelon Jalapeno ingredients
  IF v_watermelon_jalapeno_id IS NOT NULL THEN
    INSERT INTO flavor_ingredients (flavor_id, ingredient_id, percentage, density, batch_requirement)
    SELECT 
      v_watermelon_jalapeno_id,
      i.id,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 5.39
        WHEN 'Watermelon Juice Concentrate 65 Brix' THEN 2.50
        WHEN 'Lime Juice Concentrate' THEN 2.24
        WHEN 'Margarita Flavor' THEN 0.54
        WHEN 'Watermelon Flavor Natural WONF' THEN 0.30
        WHEN 'Jalapeno No Heat Flavor Natural Type' THEN 0.12
        WHEN 'Salted Lime Flavor' THEN 0.22
        WHEN 'Salt' THEN 0.07
        WHEN 'Alcohol Burn FL Nat Type' THEN 0.05
        WHEN 'Lime Essence' THEN 0.02
        WHEN 'Capsicum Extract Natural WONF' THEN 0.02
      END as percentage,
      8.450 as density,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 228.01
        WHEN 'Watermelon Juice Concentrate 65 Brix' THEN 105.76
        WHEN 'Lime Juice Concentrate' THEN 94.76
        WHEN 'Margarita Flavor' THEN 22.84
        WHEN 'Watermelon Flavor Natural WONF' THEN 12.69
        WHEN 'Jalapeno No Heat Flavor Natural Type' THEN 5.08
        WHEN 'Salted Lime Flavor' THEN 9.31
        WHEN 'Salt' THEN 2.96
        WHEN 'Alcohol Burn FL Nat Type' THEN 2.12
        WHEN 'Lime Essence' THEN 0.85
        WHEN 'Capsicum Extract Natural WONF' THEN 0.85
      END as batch_requirement
    FROM ingredients i
    WHERE i.name IN (
      'Blue Agave Syrup Organic Light',
      'Watermelon Juice Concentrate 65 Brix',
      'Lime Juice Concentrate',
      'Margarita Flavor',
      'Watermelon Flavor Natural WONF',
      'Jalapeno No Heat Flavor Natural Type',
      'Salted Lime Flavor',
      'Salt',
      'Alcohol Burn FL Nat Type',
      'Lime Essence',
      'Capsicum Extract Natural WONF'
    )
    AND NOT EXISTS (
      SELECT 1 FROM flavor_ingredients 
      WHERE flavor_id = v_watermelon_jalapeno_id AND ingredient_id = i.id
    );
  END IF;

  -- Add Passionfruit Guava ingredients
  IF v_passionfruit_guava_id IS NOT NULL THEN
    INSERT INTO flavor_ingredients (flavor_id, ingredient_id, percentage, density, batch_requirement)
    SELECT 
      v_passionfruit_guava_id,
      i.id,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 5.39
        WHEN 'Guava Juice Concentrate Clarified 65 Brix' THEN 3.00
        WHEN 'Lime Juice Concentrate' THEN 2.24
        WHEN 'Margarita Flavor' THEN 0.54
        WHEN 'Passionfruit Flavor Natural WONF' THEN 0.30
        WHEN 'Salted Lime Flavor' THEN 0.22
        WHEN 'Salt' THEN 0.07
        WHEN 'Alcohol Burn FL Nat Type' THEN 0.05
        WHEN 'Lime Essence' THEN 0.02
      END as percentage,
      8.450 as density,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 230.16
        WHEN 'Guava Juice Concentrate Clarified 65 Brix' THEN 128.11
        WHEN 'Lime Juice Concentrate' THEN 95.65
        WHEN 'Margarita Flavor' THEN 23.06
        WHEN 'Passionfruit Flavor Natural WONF' THEN 12.81
        WHEN 'Salted Lime Flavor' THEN 9.39
        WHEN 'Salt' THEN 2.99
        WHEN 'Alcohol Burn FL Nat Type' THEN 2.14
        WHEN 'Lime Essence' THEN 0.85
      END as batch_requirement
    FROM ingredients i
    WHERE i.name IN (
      'Blue Agave Syrup Organic Light',
      'Guava Juice Concentrate Clarified 65 Brix',
      'Lime Juice Concentrate',
      'Margarita Flavor',
      'Passionfruit Flavor Natural WONF',
      'Salted Lime Flavor',
      'Salt',
      'Alcohol Burn FL Nat Type',
      'Lime Essence'
    )
    AND NOT EXISTS (
      SELECT 1 FROM flavor_ingredients 
      WHERE flavor_id = v_passionfruit_guava_id AND ingredient_id = i.id
    );
  END IF;

  -- Add Blueberry Mint ingredients
  IF v_blueberry_mint_id IS NOT NULL THEN
    INSERT INTO flavor_ingredients (flavor_id, ingredient_id, percentage, density, batch_requirement)
    SELECT 
      v_blueberry_mint_id,
      i.id,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 5.12
        WHEN 'Blueberry Juice Concentrate 65 Brix' THEN 2.51
        WHEN 'Lime Juice Concentrate' THEN 2.14
        WHEN 'Blueberry Flavor Natural WONF' THEN 0.80
        WHEN 'Margarita Flavor' THEN 0.51
        WHEN 'Salted Lime Flavor' THEN 0.21
        WHEN 'Spearmint Flavor Extract Natural' THEN 0.16
        WHEN 'Salt' THEN 0.07
        WHEN 'Alcohol Burn FL Nat Type' THEN 0.04
        WHEN 'Lime Essence' THEN 0.02
      END as percentage,
      8.450 as density,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 216.33
        WHEN 'Blueberry Juice Concentrate 65 Brix' THEN 106.05
        WHEN 'Lime Juice Concentrate' THEN 90.42
        WHEN 'Blueberry Flavor Natural WONF' THEN 33.80
        WHEN 'Margarita Flavor' THEN 21.55
        WHEN 'Salted Lime Flavor' THEN 8.87
        WHEN 'Spearmint Flavor Extract Natural' THEN 6.76
        WHEN 'Salt' THEN 2.96
        WHEN 'Alcohol Burn FL Nat Type' THEN 1.69
        WHEN 'Lime Essence' THEN 0.85
      END as batch_requirement
    FROM ingredients i
    WHERE i.name IN (
      'Blue Agave Syrup Organic Light',
      'Blueberry Juice Concentrate 65 Brix',
      'Lime Juice Concentrate',
      'Blueberry Flavor Natural WONF',
      'Margarita Flavor',
      'Salted Lime Flavor',
      'Spearmint Flavor Extract Natural',
      'Salt',
      'Alcohol Burn FL Nat Type',
      'Lime Essence'
    )
    AND NOT EXISTS (
      SELECT 1 FROM flavor_ingredients 
      WHERE flavor_id = v_blueberry_mint_id AND ingredient_id = i.id
    );
  END IF;

  -- Add Strawberry ingredients
  IF v_strawberry_id IS NOT NULL THEN
    INSERT INTO flavor_ingredients (flavor_id, ingredient_id, percentage, density, batch_requirement)
    SELECT 
      v_strawberry_id,
      i.id,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 5.39
        WHEN 'Strawberry Juice Concentrate 65 Brix' THEN 2.50
        WHEN 'Lime Juice Concentrate' THEN 2.24
        WHEN 'Margarita Flavor' THEN 0.54
        WHEN 'Natural Strawberry Flavor WONF' THEN 0.40
        WHEN 'Salted Lime Flavor' THEN 0.22
        WHEN 'Salt' THEN 0.07
        WHEN 'Alcohol Burn FL Nat Type' THEN 0.05
        WHEN 'Lime Essence' THEN 0.02
      END as percentage,
      8.450 as density,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 229.63
        WHEN 'Strawberry Juice Concentrate 65 Brix' THEN 106.51
        WHEN 'Lime Juice Concentrate' THEN 95.43
        WHEN 'Margarita Flavor' THEN 23.01
        WHEN 'Natural Strawberry Flavor WONF' THEN 17.04
        WHEN 'Salted Lime Flavor' THEN 9.37
        WHEN 'Salt' THEN 2.98
        WHEN 'Alcohol Burn FL Nat Type' THEN 2.13
        WHEN 'Lime Essence' THEN 0.85
      END as batch_requirement
    FROM ingredients i
    WHERE i.name IN (
      'Blue Agave Syrup Organic Light',
      'Strawberry Juice Concentrate 65 Brix',
      'Lime Juice Concentrate',
      'Margarita Flavor',
      'Natural Strawberry Flavor WONF',
      'Salted Lime Flavor',
      'Salt',
      'Alcohol Burn FL Nat Type',
      'Lime Essence'
    )
    AND NOT EXISTS (
      SELECT 1 FROM flavor_ingredients 
      WHERE flavor_id = v_strawberry_id AND ingredient_id = i.id
    );
  END IF;
END $$;