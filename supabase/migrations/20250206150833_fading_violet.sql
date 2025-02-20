/*
  # Update batch settings and add price history

  1. Changes
    - Add default values for batch costs and sizes if not exists
    - Add price history tracking
  
  2. Security
    - Ensure RLS is enabled on all tables
    - Update policies if needed
*/

-- Drop existing policies if they exist
DO $$ 
BEGIN
    -- Safely drop policies if they exist
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'batch_costs' 
        AND policyname = 'Users can manage their own batch costs'
    ) THEN
        DROP POLICY IF EXISTS "Users can manage their own batch costs" ON batch_costs;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'freight_costs' 
        AND policyname = 'Users can manage their own freight costs'
    ) THEN
        DROP POLICY IF EXISTS "Users can manage their own freight costs" ON freight_costs;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'batch_sizes' 
        AND policyname = 'Users can manage their own batch sizes'
    ) THEN
        DROP POLICY IF EXISTS "Users can manage their own batch sizes" ON batch_sizes;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'price_history' 
        AND policyname = 'Users can view price history'
    ) THEN
        DROP POLICY IF EXISTS "Users can view price history" ON price_history;
    END IF;
END $$;

-- Create price history table if it doesn't exist
CREATE TABLE IF NOT EXISTS price_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id uuid REFERENCES ingredients(id),
  price_per_unit numeric NOT NULL,
  effective_date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Ensure RLS is enabled
ALTER TABLE batch_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE freight_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE batch_sizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;

-- Recreate policies
CREATE POLICY "Users can manage their own batch costs"
  ON batch_costs
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own freight costs"
  ON freight_costs
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own batch sizes"
  ON batch_sizes
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view price history"
  ON price_history
  FOR SELECT
  TO authenticated
  USING (true);

-- Insert default batch size if none exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM batch_sizes LIMIT 1) THEN
    INSERT INTO batch_sizes (size_gallons, cans_per_batch)
    VALUES (500, 4000);
  END IF;
END $$;

-- Create or replace price history trigger function
CREATE OR REPLACE FUNCTION update_price_history()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO price_history (ingredient_id, price_per_unit)
  VALUES (NEW.ingredient_id, NEW.price_per_unit);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;