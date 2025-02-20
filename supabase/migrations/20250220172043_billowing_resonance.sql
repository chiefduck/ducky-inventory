/*
  # Add tiered pricing support

  1. New Tables
    - `pricing_tier_types` - Defines different types of pricing tiers (e.g., standard, volume)
    - `pricing_tier_ranges` - Defines the quantity ranges for each tier

  2. Changes
    - Add tier type and range references to existing pricing_tiers table
    - Add constraints to ensure valid tier ranges

  3. Security
    - Enable RLS on new tables
    - Add policies for authenticated users
*/

-- Create pricing tier types table
CREATE TABLE pricing_tier_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Create pricing tier ranges table
CREATE TABLE pricing_tier_ranges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_type_id uuid REFERENCES pricing_tier_types(id),
  min_quantity numeric NOT NULL,
  max_quantity numeric,
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT valid_range CHECK (
    (max_quantity IS NULL OR max_quantity > min_quantity) AND
    min_quantity >= 0
  )
);

-- Add tier references to pricing_tiers
ALTER TABLE pricing_tiers
ADD COLUMN tier_type_id uuid REFERENCES pricing_tier_types(id),
ADD COLUMN tier_range_id uuid REFERENCES pricing_tier_ranges(id);

-- Enable RLS
ALTER TABLE pricing_tier_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing_tier_ranges ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated read access" ON pricing_tier_types
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read access" ON pricing_tier_ranges
  FOR SELECT TO authenticated USING (true);

-- Insert standard tier types
INSERT INTO pricing_tier_types (name, description) VALUES
  ('standard', 'Standard fixed pricing'),
  ('volume', 'Volume-based tiered pricing');

-- Insert tier ranges for volume pricing
WITH volume_type AS (
  SELECT id FROM pricing_tier_types WHERE name = 'volume'
)
INSERT INTO pricing_tier_ranges (tier_type_id, min_quantity, max_quantity, name)
SELECT 
  volume_type.id,
  min_quantity,
  max_quantity,
  name
FROM volume_type, (VALUES
  (0, 264, '1-4 Pails'),
  (265, 582, '5-10 Pails'),
  (583, 1907, '11-35 Pails'),
  (1908, NULL, '36+ Pails')
) AS ranges(min_quantity, max_quantity, name);

-- Update existing pricing tiers with tier types and ranges
WITH 
  standard_type AS (SELECT id FROM pricing_tier_types WHERE name = 'standard'),
  volume_type AS (SELECT id FROM pricing_tier_types WHERE name = 'volume')
UPDATE pricing_tiers pt
SET 
  tier_type_id = CASE
    WHEN i.name IN ('Lime Juice Concentrate', 'Blue Agave Syrup Organic Light') THEN (SELECT id FROM volume_type)
    ELSE (SELECT id FROM standard_type)
  END,
  tier_range_id = CASE
    WHEN i.name IN ('Lime Juice Concentrate', 'Blue Agave Syrup Organic Light') THEN
      (SELECT id FROM pricing_tier_ranges pr WHERE pt.min_quantity >= pr.min_quantity 
       AND (pr.max_quantity IS NULL OR pt.min_quantity < pr.max_quantity))
    ELSE NULL
  END
FROM ingredients i
WHERE pt.ingredient_id = i.id;