/*
  # Update inventory levels

  1. Changes
    - Remove duplicate inventory records
    - Add unique constraint for ingredient_id and user_id
    - Update current inventory levels for all ingredients
    
  2. Details
    Updated inventory levels:
    - Blue Agave Syrup Light: 48.28 lbs
    - Lime Juice Concentrate: 10.36 lbs
    - Margarita Flavor: 42.77 lbs
    - Salted Lime Flavor: 30.09 lbs
    - Orange Zest Flavor: 12.79 lbs
    - Salt: 0 lbs
    - Alcohol Burn: 32.96 lbs
    - Lime Essence: 3.09 lbs
*/

-- First, clean up any duplicate inventory records
WITH ranked_records AS (
  SELECT 
    id,
    ingredient_id,
    user_id,
    ROW_NUMBER() OVER (
      PARTITION BY ingredient_id, user_id 
      ORDER BY updated_at DESC
    ) as rn
  FROM inventory_levels
)
DELETE FROM inventory_levels
WHERE id IN (
  SELECT id 
  FROM ranked_records 
  WHERE rn > 1
);

-- Now add the unique constraint
ALTER TABLE inventory_levels
DROP CONSTRAINT IF EXISTS inventory_levels_ingredient_id_user_id_key;

ALTER TABLE inventory_levels
ADD CONSTRAINT inventory_levels_ingredient_id_user_id_key 
UNIQUE (ingredient_id, user_id);

-- Update inventory levels for each ingredient
DO $$ 
DECLARE 
  v_ingredient_id uuid;
  v_user_id uuid;
BEGIN
  -- Get first user ID from auth.users
  SELECT id INTO v_user_id 
  FROM auth.users 
  LIMIT 1;

  -- Only proceed if we have a valid user
  IF v_user_id IS NOT NULL THEN
    -- Delete existing inventory levels for this user
    DELETE FROM inventory_levels 
    WHERE user_id = v_user_id;

    -- Blue Agave Syrup Light
    SELECT id INTO v_ingredient_id 
    FROM ingredients 
    WHERE name = 'Blue Agave Syrup Organic Light';
    
    IF FOUND THEN
      INSERT INTO inventory_levels (ingredient_id, user_id, current_level)
      VALUES (v_ingredient_id, v_user_id, 48.28);
    END IF;

    -- Lime Juice Concentrate
    SELECT id INTO v_ingredient_id 
    FROM ingredients 
    WHERE name = 'Lime Juice Concentrate';
    
    IF FOUND THEN
      INSERT INTO inventory_levels (ingredient_id, user_id, current_level)
      VALUES (v_ingredient_id, v_user_id, 10.36);
    END IF;

    -- Margarita Flavor
    SELECT id INTO v_ingredient_id 
    FROM ingredients 
    WHERE name = 'Margarita Flavor';
    
    IF FOUND THEN
      INSERT INTO inventory_levels (ingredient_id, user_id, current_level)
      VALUES (v_ingredient_id, v_user_id, 42.77);
    END IF;

    -- Salted Lime Flavor
    SELECT id INTO v_ingredient_id 
    FROM ingredients 
    WHERE name = 'Salted Lime Flavor';
    
    IF FOUND THEN
      INSERT INTO inventory_levels (ingredient_id, user_id, current_level)
      VALUES (v_ingredient_id, v_user_id, 30.09);
    END IF;

    -- Orange Zest Flavor
    SELECT id INTO v_ingredient_id 
    FROM ingredients 
    WHERE name = 'Orange Zest Flavor Nat Type';
    
    IF FOUND THEN
      INSERT INTO inventory_levels (ingredient_id, user_id, current_level)
      VALUES (v_ingredient_id, v_user_id, 12.79);
    END IF;

    -- Salt
    SELECT id INTO v_ingredient_id 
    FROM ingredients 
    WHERE name = 'Salt';
    
    IF FOUND THEN
      INSERT INTO inventory_levels (ingredient_id, user_id, current_level)
      VALUES (v_ingredient_id, v_user_id, 0);
    END IF;

    -- Alcohol Burn
    SELECT id INTO v_ingredient_id 
    FROM ingredients 
    WHERE name = 'Alcohol Burn FL Nat Type';
    
    IF FOUND THEN
      INSERT INTO inventory_levels (ingredient_id, user_id, current_level)
      VALUES (v_ingredient_id, v_user_id, 32.96);
    END IF;

    -- Lime Essence
    SELECT id INTO v_ingredient_id 
    FROM ingredients 
    WHERE name = 'Lime Essence';
    
    IF FOUND THEN
      INSERT INTO inventory_levels (ingredient_id, user_id, current_level)
      VALUES (v_ingredient_id, v_user_id, 3.09);
    END IF;
  END IF;
END $$;