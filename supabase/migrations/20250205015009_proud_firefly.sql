/*
  # Add cost tracking and batch information
  
  1. New Tables
    - `batch_costs`
      - Stores fixed costs per batch (cans, tolling)
    - `freight_costs`
      - Tracks freight costs per supplier per order
    - `batch_sizes`
      - Tracks standard batch sizes and their can yields
    - `price_history`
      - Tracks historical pricing for ingredients
  
  2. Changes
    - Add new columns to existing tables
    - Update RLS policies
*/

-- Batch costs table
CREATE TABLE IF NOT EXISTS batch_costs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) DEFAULT auth.uid(),
  can_cost_per_unit numeric NOT NULL DEFAULT 0,
  tolling_cost_per_batch numeric NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Freight costs table
CREATE TABLE IF NOT EXISTS freight_costs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) DEFAULT auth.uid(),
  supplier_id uuid REFERENCES suppliers(id),
  cost numeric NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Batch sizes table
CREATE TABLE IF NOT EXISTS batch_sizes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) DEFAULT auth.uid(),
  size_gallons numeric NOT NULL,
  cans_per_batch integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Price history table
CREATE TABLE IF NOT EXISTS price_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id uuid REFERENCES ingredients(id),
  price_per_unit numeric NOT NULL,
  effective_date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE batch_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE freight_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE batch_sizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;

-- Create policies
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

-- Insert default batch size
INSERT INTO batch_sizes (size_gallons, cans_per_batch)
VALUES (500, 4000);

-- Add function to update price history
CREATE OR REPLACE FUNCTION update_price_history()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO price_history (ingredient_id, price_per_unit)
  VALUES (NEW.ingredient_id, NEW.price_per_unit);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;