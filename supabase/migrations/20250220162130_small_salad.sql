/*
  # Fix freight costs RLS policies

  1. Changes
    - Drop existing RLS policies for freight_costs table
    - Create new policies that allow authenticated users to:
      - Read all freight costs
      - Manage their own freight costs
    - Add default user_id value from auth.uid()

  2. Security
    - Enable RLS on freight_costs table
    - Add policies for CRUD operations
*/

-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "Users can manage their own freight costs" ON freight_costs;

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