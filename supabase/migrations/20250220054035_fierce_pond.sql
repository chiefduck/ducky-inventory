/*
  # Update supplier links and MOQ values

  1. Changes
    - Updates supplier associations for all ingredients
    - Sets correct MOQ (Minimum Order Quantity) values
    - Ensures all ingredients have proper supplier links

  2. Details
    Updated MOQs:
    - Blue Agave Syrup Light: 55 lbs (Bakers Authority)
    - Lime Juice Concentrate: 53 lbs (Greenwood Associates)
    - Margarita Flavor: 40 lbs (Sapphire)
    - Salted Lime Flavor: 40 lbs (Sapphire)
    - Orange Zest Flavor: 40 lbs (Sapphire)
    - Salt: 1 lb (Quantum Source)
    - Alcohol Burn: 40 lbs (Sapphire)
    - Lime Essence: 3.09 lbs (Primal Essence)
*/

-- Update ingredient supplier links and MOQs
DO $$ 
DECLARE 
  v_bakers_authority_id uuid;
  v_greenwood_id uuid;
  v_sapphire_id uuid;
  v_quantum_id uuid;
  v_primal_id uuid;
BEGIN
  -- Get supplier IDs
  SELECT id INTO v_bakers_authority_id FROM suppliers WHERE name = 'Bakers Authority';
  SELECT id INTO v_greenwood_id FROM suppliers WHERE name = 'Greenwood Associates';
  SELECT id INTO v_sapphire_id FROM suppliers WHERE name = 'Sapphire';
  SELECT id INTO v_quantum_id FROM suppliers WHERE name = 'Quantum Source';
  SELECT id INTO v_primal_id FROM suppliers WHERE name = 'Primal Essence';

  -- Update Blue Agave Syrup Light
  UPDATE ingredients 
  SET supplier_id = v_bakers_authority_id,
      moq = 55
  WHERE name = 'Blue Agave Syrup Organic Light';

  -- Update Lime Juice Concentrate
  UPDATE ingredients 
  SET supplier_id = v_greenwood_id,
      moq = 53
  WHERE name = 'Lime Juice Concentrate';

  -- Update Margarita Flavor
  UPDATE ingredients 
  SET supplier_id = v_sapphire_id,
      moq = 40
  WHERE name = 'Margarita Flavor';

  -- Update Salted Lime Flavor
  UPDATE ingredients 
  SET supplier_id = v_sapphire_id,
      moq = 40
  WHERE name = 'Salted Lime Flavor';

  -- Update Orange Zest Flavor
  UPDATE ingredients 
  SET supplier_id = v_sapphire_id,
      moq = 40
  WHERE name = 'Orange Zest Flavor Nat Type';

  -- Update Salt
  UPDATE ingredients 
  SET supplier_id = v_quantum_id,
      moq = 1
  WHERE name = 'Salt';

  -- Update Alcohol Burn
  UPDATE ingredients 
  SET supplier_id = v_sapphire_id,
      moq = 40
  WHERE name = 'Alcohol Burn FL Nat Type';

  -- Update Lime Essence
  UPDATE ingredients 
  SET supplier_id = v_primal_id,
      moq = 3.09
  WHERE name = 'Lime Essence';

  -- Add a constraint to ensure supplier_id is not null
  ALTER TABLE ingredients 
  ALTER COLUMN supplier_id SET NOT NULL;
END $$;