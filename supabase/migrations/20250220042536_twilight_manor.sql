/*
  # Add part number to ingredients table

  1. Changes
    - Add part_number column to ingredients table
    - Update existing ingredients with part numbers
*/

-- Add part_number column to ingredients table
ALTER TABLE ingredients
ADD COLUMN part_number text;

-- Update existing ingredients with part numbers
UPDATE ingredients
SET part_number = CASE name
  WHEN 'Blue Agave Syrup Organic Light' THEN 'AGV-001'
  WHEN 'Lime Juice Concentrate' THEN 'LJC-001'
  WHEN 'Margarita Flavor' THEN 'MRG-001'
  WHEN 'Salted Lime Flavor' THEN 'SLF-001'
  WHEN 'Orange Zest Flavor Nat Type' THEN 'OZF-001'
  WHEN 'Salt' THEN 'SLT-001'
  WHEN 'Alcohol Burn FL Nat Type' THEN 'ABF-001'
  WHEN 'Lime Essence' THEN 'LME-001'
  ELSE 'PART-' || substring(gen_random_uuid()::text, 1, 8)
END;