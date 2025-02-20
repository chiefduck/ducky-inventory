/*
  # Update ingredient supplier relationships

  1. Changes
    - Reorganize ingredient-supplier relationships to match specified mapping
    - Ensure all ingredients are linked to correct suppliers
    - Maintain existing MOQs and other data

  2. Security
    - No changes to RLS policies
*/

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

  -- Update ingredient supplier relationships
  UPDATE ingredients 
  SET supplier_id = 
    CASE name
      WHEN 'Blue Agave Syrup Organic Light' THEN v_bakers_authority_id
      WHEN 'Lime Juice Concentrate' THEN v_greenwood_id
      WHEN 'Margarita Flavor' THEN v_sapphire_id
      WHEN 'Salted Lime Flavor' THEN v_sapphire_id
      WHEN 'Orange Zest Flavor Nat Type' THEN v_sapphire_id
      WHEN 'Salt' THEN v_quantum_id
      WHEN 'Alcohol Burn FL Nat Type' THEN v_sapphire_id
      WHEN 'Lime Essence' THEN v_primal_id
    END
  WHERE name IN (
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