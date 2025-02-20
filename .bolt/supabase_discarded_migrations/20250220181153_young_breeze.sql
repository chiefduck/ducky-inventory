/*
  # Add Additional Flavors and Ingredients

  1. New Ingredients
    - Adds ingredients for Strawberry, Passionfruit Guava, Watermelon Jalapeno, and Blueberry Mint flavors
    - Each ingredient includes:
      - Name, MOQ, unit, supplier reference
      - Part number for tracking
      - Default pricing tier

  2. Flavor Ingredients
    - Links ingredients to flavors with:
      - Correct percentages
      - Batch requirements
      - Density values
      
  3. Updates
    - Adds pricing tiers for new ingredients
    - Sets appropriate MOQs and supplier relationships
*/

-- Add new ingredients
INSERT INTO ingredients (name, moq, unit, supplier_id, part_number)
SELECT
  name, moq, unit, supplier_id, part_number
FROM (
  VALUES
    -- Strawberry ingredients
    ('Strawberry Flavor', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'STF-001'),
    ('Natural Strawberry Extract', 25, 'lbs', (SELECT id FROM suppliers WHERE name = 'Primal Essence'), 'NSE-001'),
    ('Berry Blend', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'BBL-001'),
    
    -- Passionfruit Guava ingredients
    ('Passionfruit Flavor', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'PSF-001'),
    ('Guava Flavor', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'GVF-001'),
    ('Tropical Blend', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'TBL-001'),
    
    -- Watermelon Jalapeno ingredients
    ('Watermelon Flavor', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'WMF-001'),
    ('Jalapeno Extract', 20, 'lbs', (SELECT id FROM suppliers WHERE name = 'Primal Essence'), 'JLE-001'),
    ('Green Chili Blend', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'GCB-001'),
    
    -- Blueberry Mint ingredients
    ('Blueberry Flavor', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'BLF-001'),
    ('Natural Mint Extract', 25, 'lbs', (SELECT id FROM suppliers WHERE name = 'Primal Essence'), 'NME-001'),
    ('Berry Mint Blend', 40, 'lbs', (SELECT id FROM suppliers WHERE name = 'Sapphire'), 'BMB-001')
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
    -- Strawberry flavor components
    WHEN 'Strawberry Flavor' THEN 24.50
    WHEN 'Natural Strawberry Extract' THEN 68.75
    WHEN 'Berry Blend' THEN 22.35
    
    -- Passionfruit Guava components
    WHEN 'Passionfruit Flavor' THEN 26.80
    WHEN 'Guava Flavor' THEN 25.40
    WHEN 'Tropical Blend' THEN 23.65
    
    -- Watermelon Jalapeno components
    WHEN 'Watermelon Flavor' THEN 21.90
    WHEN 'Jalapeno Extract' THEN 72.50
    WHEN 'Green Chili Blend' THEN 24.75
    
    -- Blueberry Mint components
    WHEN 'Blueberry Flavor' THEN 23.80
    WHEN 'Natural Mint Extract' THEN 65.90
    WHEN 'Berry Mint Blend' THEN 22.95
  END,
  standard_type.id
FROM ingredients i, standard_type
WHERE i.name IN (
  'Strawberry Flavor', 'Natural Strawberry Extract', 'Berry Blend',
  'Passionfruit Flavor', 'Guava Flavor', 'Tropical Blend',
  'Watermelon Flavor', 'Jalapeno Extract', 'Green Chili Blend',
  'Blueberry Flavor', 'Natural Mint Extract', 'Berry Mint Blend'
)
AND NOT EXISTS (
  SELECT 1 FROM pricing_tiers 
  WHERE ingredient_id = i.id
);

-- Link ingredients to flavors
DO $$
DECLARE
  v_strawberry_id uuid;
  v_passionfruit_guava_id uuid;
  v_watermelon_jalapeno_id uuid;
  v_blueberry_mint_id uuid;
BEGIN
  -- Get flavor IDs
  SELECT id INTO v_strawberry_id FROM flavors WHERE name = 'Strawberry';
  SELECT id INTO v_passionfruit_guava_id FROM flavors WHERE name = 'Passionfruit Guava';
  SELECT id INTO v_watermelon_jalapeno_id FROM flavors WHERE name = 'Watermelon Jalapeno';
  SELECT id INTO v_blueberry_mint_id FROM flavors WHERE name = 'Blueberry Mint';

  -- Add Strawberry ingredients
  IF v_strawberry_id IS NOT NULL THEN
    INSERT INTO flavor_ingredients (flavor_id, ingredient_id, percentage, density, batch_requirement)
    SELECT 
      v_strawberry_id,
      i.id,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 6.00
        WHEN 'Strawberry Flavor' THEN 0.85
        WHEN 'Natural Strawberry Extract' THEN 0.25
        WHEN 'Berry Blend' THEN 0.15
        WHEN 'Salt' THEN 0.08
        WHEN 'Alcohol Burn FL Nat Type' THEN 0.05
      END as percentage,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 8.450
        ELSE 8.450
      END as density
    FROM ingredients i
    WHERE i.name IN (
      'Blue Agave Syrup Organic Light',
      'Strawberry Flavor',
      'Natural Strawberry Extract',
      'Berry Blend',
      'Salt',
      'Alcohol Burn FL Nat Type'
    )
    AND NOT EXISTS (
      SELECT 1 FROM flavor_ingredients 
      WHERE flavor_id = v_strawberry_id AND ingredient_id = i.id
    );
  END IF;

  -- Add Passionfruit Guava ingredients
  IF v_passionfruit_guava_id IS NOT NULL THEN
    INSERT INTO flavor_ingredients (flavor_id, ingredient_id, percentage, density, batch_requirement)
    SELECT 
      v_passionfruit_guava_id,
      i.id,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 6.00
        WHEN 'Passionfruit Flavor' THEN 0.75
        WHEN 'Guava Flavor' THEN 0.45
        WHEN 'Tropical Blend' THEN 0.15
        WHEN 'Salt' THEN 0.08
        WHEN 'Alcohol Burn FL Nat Type' THEN 0.05
      END as percentage,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 8.450
        ELSE 8.450
      END as density
    FROM ingredients i
    WHERE i.name IN (
      'Blue Agave Syrup Organic Light',
      'Passionfruit Flavor',
      'Guava Flavor',
      'Tropical Blend',
      'Salt',
      'Alcohol Burn FL Nat Type'
    )
    AND NOT EXISTS (
      SELECT 1 FROM flavor_ingredients 
      WHERE flavor_id = v_passionfruit_guava_id AND ingredient_id = i.id
    );
  END IF;

  -- Add Watermelon Jalapeno ingredients
  IF v_watermelon_jalapeno_id IS NOT NULL THEN
    INSERT INTO flavor_ingredients (flavor_id, ingredient_id, percentage, density, batch_requirement)
    SELECT 
      v_watermelon_jalapeno_id,
      i.id,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 6.00
        WHEN 'Watermelon Flavor' THEN 0.65
        WHEN 'Jalapeno Extract' THEN 0.35
        WHEN 'Green Chili Blend' THEN 0.15
        WHEN 'Salt' THEN 0.08
        WHEN 'Alcohol Burn FL Nat Type' THEN 0.05
      END as percentage,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 8.450
        ELSE 8.450
      END as density
    FROM ingredients i
    WHERE i.name IN (
      'Blue Agave Syrup Organic Light',
      'Watermelon Flavor',
      'Jalapeno Extract',
      'Green Chili Blend',
      'Salt',
      'Alcohol Burn FL Nat Type'
    )
    AND NOT EXISTS (
      SELECT 1 FROM flavor_ingredients 
      WHERE flavor_id = v_watermelon_jalapeno_id AND ingredient_id = i.id
    );
  END IF;

  -- Add Blueberry Mint ingredients
  IF v_blueberry_mint_id IS NOT NULL THEN
    INSERT INTO flavor_ingredients (flavor_id, ingredient_id, percentage, density, batch_requirement)
    SELECT 
      v_blueberry_mint_id,
      i.id,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 6.00
        WHEN 'Blueberry Flavor' THEN 0.70
        WHEN 'Natural Mint Extract' THEN 0.30
        WHEN 'Berry Mint Blend' THEN 0.15
        WHEN 'Salt' THEN 0.08
        WHEN 'Alcohol Burn FL Nat Type' THEN 0.05
      END as percentage,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 8.450
        ELSE 8.450
      END as density
    FROM ingredients i
    WHERE i.name IN (
      'Blue Agave Syrup Organic Light',
      'Blueberry Flavor',
      'Natural Mint Extract',
      'Berry Mint Blend',
      'Salt',
      'Alcohol Burn FL Nat Type'
    )
    AND NOT EXISTS (
      SELECT 1 FROM flavor_ingredients 
      WHERE flavor_id = v_blueberry_mint_id AND ingredient_id = i.id
    );
  END IF;
END $$;