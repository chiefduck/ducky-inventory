/*
  # Fix freight costs RLS policies and add defaults

  1. Changes
    - Drop existing RLS policies for freight_costs table
    - Create new policies that allow authenticated users to:
      - Read all freight costs
      - Manage their own freight costs
    - Add default user_id value from auth.uid()
    - Add default freight costs for testing

  2. Security
    - Enable RLS on freight_costs table
    - Add policies for CRUD operations
*/

-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "Users can manage their own freight costs" ON freight_costs;
DROP POLICY IF EXISTS "Users can read all freight costs" ON freight_costs;
DROP POLICY IF EXISTS "Users can insert their own freight costs" ON freight_costs;
DROP POLICY IF EXISTS "Users can update their own freight costs" ON freight_costs;
DROP POLICY IF EXISTS "Users can delete their own freight costs" ON freight_costs;

-- Ensure RLS is enabled
ALTER TABLE freight_costs ENABLE ROW LEVEL SECURITY;

-- Set default value for user_id
ALTER TABLE freight_costs 
ALTER COLUMN user_id SET DEFAULT auth.uid();

-- Create new policies
CREATE POLICY "Users can read all freight costs"
  ON freight_costs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own freight costs"
  ON freight_costs
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own freight costs"
  ON freight_costs
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own freight costs"
  ON freight_costs
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Add default freight costs for testing
DO $$
DECLARE
  v_user_id uuid;
  v_bakers_authority_id uuid;
  v_greenwood_id uuid;
  v_sapphire_id uuid;
  v_quantum_id uuid;
  v_primal_id uuid;
BEGIN
  -- Get the first user (for demo data)
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;

  -- Get supplier IDs
  SELECT id INTO v_bakers_authority_id FROM suppliers WHERE name = 'Bakers Authority';
  SELECT id INTO v_greenwood_id FROM suppliers WHERE name = 'Greenwood Associates';
  SELECT id INTO v_sapphire_id FROM suppliers WHERE name = 'Sapphire';
  SELECT id INTO v_quantum_id FROM suppliers WHERE name = 'Quantum Source';
  SELECT id INTO v_primal_id FROM suppliers WHERE name = 'Primal Essence';

  IF v_user_id IS NOT NULL THEN
    -- Delete existing freight costs for this user
    DELETE FROM freight_costs WHERE user_id = v_user_id;

    -- Insert default freight costs
    INSERT INTO freight_costs (user_id, supplier_id, cost)
    VALUES
      (v_user_id, v_bakers_authority_id, 200),
      (v_user_id, v_greenwood_id, 150),
      (v_user_id, v_sapphire_id, 175),
      (v_user_id, v_quantum_id, 100),
      (v_user_id, v_primal_id, 125);
  END IF;
END $$;