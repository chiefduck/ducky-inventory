/*
  # Add ingredient validation and Classic Lime data

  1. Functions and Triggers
    - Add function to check if flavor has ingredients
    - Add trigger to validate new flavors
  
  2. Constraints
    - Add check constraint for positive batch requirements
  
  3. Data
    - Ensure Classic Lime ingredients exist
*/

-- First drop existing function if it exists
DROP FUNCTION IF EXISTS check_flavor_ingredients(uuid);

-- Create function to check if flavor has ingredients
CREATE OR REPLACE FUNCTION check_flavor_ingredients(flavor_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM flavor_ingredients 
    WHERE flavor_id = flavor_id
  );
END;
$$ LANGUAGE plpgsql;

-- Add check constraint for positive batch requirements if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.constraint_column_usage 
    WHERE constraint_name = 'positive_batch_requirement'
  ) THEN
    ALTER TABLE flavor_ingredients
    ADD CONSTRAINT positive_batch_requirement 
    CHECK (batch_requirement > 0);
  END IF;
END $$;

-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS flavor_ingredients_check ON flavors;
DROP FUNCTION IF EXISTS validate_flavor_ingredients();

-- Create trigger to validate flavor ingredients
CREATE OR REPLACE FUNCTION validate_flavor_ingredients()
RETURNS trigger AS $$
BEGIN
  IF NOT check_flavor_ingredients(NEW.id) THEN
    RAISE NOTICE 'Flavor % has no ingredients defined', NEW.name;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER flavor_ingredients_check
AFTER INSERT ON flavors
FOR EACH ROW
EXECUTE FUNCTION validate_flavor_ingredients();

-- Ensure Classic Lime ingredients exist
DO $$
DECLARE
  v_classic_lime_id uuid;
BEGIN
  -- Get Classic Lime ID
  SELECT id INTO v_classic_lime_id
  FROM flavors
  WHERE name = 'Classic Lime';

  -- Only insert if ingredients don't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM flavor_ingredients 
    WHERE flavor_id = v_classic_lime_id
  ) THEN
    INSERT INTO flavor_ingredients (flavor_id, ingredient_id, batch_requirement)
    SELECT 
      v_classic_lime_id,
      i.id,
      CASE i.name
        WHEN 'Blue Agave Syrup Organic Light' THEN 1014
        WHEN 'Lime Juice Concentrate' THEN 422.52
        WHEN 'Margarita Flavor' THEN 101.4
        WHEN 'Salted Lime Flavor' THEN 42.25
        WHEN 'Orange Zest Flavor Nat Type' THEN 25.35
        WHEN 'Salt' THEN 13.52
        WHEN 'Alcohol Burn FL Nat Type' THEN 8.45
        WHEN 'Lime Essence' THEN 3.09
      END
    FROM ingredients i
    WHERE i.name IN (
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