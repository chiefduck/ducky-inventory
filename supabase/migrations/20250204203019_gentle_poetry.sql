/*
  # Initial Schema for Drink Ingredient Ordering System

  1. New Tables
    - `flavors`
      - `id` (uuid, primary key)
      - `name` (text)
      - `created_at` (timestamp)
    
    - `suppliers`
      - `id` (uuid, primary key)
      - `name` (text)
      - `contact_info` (text)
      - `created_at` (timestamp)
    
    - `ingredients`
      - `id` (uuid, primary key)
      - `name` (text)
      - `supplier_id` (uuid, foreign key)
      - `moq` (numeric) - Minimum Order Quantity
      - `unit` (text) - e.g., 'lbs', 'oz'
      - `created_at` (timestamp)
    
    - `pricing_tiers`
      - `id` (uuid, primary key)
      - `ingredient_id` (uuid, foreign key)
      - `min_quantity` (numeric)
      - `price_per_unit` (numeric)
      - `created_at` (timestamp)
    
    - `flavor_ingredients`
      - `id` (uuid, primary key)
      - `flavor_id` (uuid, foreign key)
      - `ingredient_id` (uuid, foreign key)
      - `batch_requirement` (numeric)
      - `created_at` (timestamp)
    
    - `inventory_levels`
      - `id` (uuid, primary key)
      - `ingredient_id` (uuid, foreign key)
      - `user_id` (uuid, foreign key)
      - `current_level` (numeric)
      - `updated_at` (timestamp)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create tables
CREATE TABLE flavors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  contact_info text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE ingredients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  supplier_id uuid REFERENCES suppliers(id),
  moq numeric NOT NULL,
  unit text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE pricing_tiers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id uuid REFERENCES ingredients(id),
  min_quantity numeric NOT NULL,
  price_per_unit numeric NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE flavor_ingredients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  flavor_id uuid REFERENCES flavors(id),
  ingredient_id uuid REFERENCES ingredients(id),
  batch_requirement numeric NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(flavor_id, ingredient_id)
);

CREATE TABLE inventory_levels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id uuid REFERENCES ingredients(id),
  user_id uuid REFERENCES auth.users(id),
  current_level numeric NOT NULL,
  updated_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE flavors ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE flavor_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_levels ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated read access" ON flavors
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read access" ON suppliers
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read access" ON ingredients
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read access" ON pricing_tiers
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read access" ON flavor_ingredients
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated CRUD access" ON inventory_levels
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Insert sample data
INSERT INTO flavors (name) VALUES
  ('Classic Lime'),
  ('Strawberry'),
  ('Passionfruit Guava'),
  ('Watermelon Jalapeno'),
  ('Blueberry Mint');

INSERT INTO suppliers (name, contact_info) VALUES
  ('Greenwood Associates', 'contact@greenwood.com'),
  ('Bakers Authority', 'sales@bakersauthority.com'),
  ('Sapphire', 'orders@sapphire.com'),
  ('Quantum Source', 'support@quantumsource.com');