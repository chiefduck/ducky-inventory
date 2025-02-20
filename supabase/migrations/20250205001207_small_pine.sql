/*
  # Fix inventory levels RLS policy

  1. Changes
    - Drop existing RLS policy for inventory_levels
    - Create new RLS policy that properly handles user_id
    - Add default value for user_id to use authenticated user's ID
*/

-- Drop existing policy
DROP POLICY IF EXISTS "Allow authenticated CRUD access" ON inventory_levels;

-- Add default value for user_id
ALTER TABLE inventory_levels 
  ALTER COLUMN user_id SET DEFAULT auth.uid();

-- Create new policies
CREATE POLICY "Users can read own inventory levels"
  ON inventory_levels
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own inventory levels"
  ON inventory_levels
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own inventory levels"
  ON inventory_levels
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own inventory levels"
  ON inventory_levels
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);