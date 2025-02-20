/*
  # Add can sizes and batch calculation support

  1. New Tables
    - `can_sizes`
      - `id` (uuid, primary key)
      - `size_oz` (numeric) - Size in fluid ounces
      - `name` (text) - Display name (e.g., "Standard 12oz")
      - `created_at` (timestamptz)

  2. Changes
    - Add can_size_id to batch_sizes table
    - Add conversion factors for calculations

  3. Security
    - Enable RLS on can_sizes table
    - Add policy for authenticated users to read can sizes
*/

-- Create can sizes table
CREATE TABLE can_sizes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  size_oz numeric NOT NULL,
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Add can size reference to batch_sizes
ALTER TABLE batch_sizes
ADD COLUMN can_size_id uuid REFERENCES can_sizes(id);

-- Enable RLS
ALTER TABLE can_sizes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated read access" ON can_sizes
  FOR SELECT TO authenticated USING (true);

-- Insert standard can sizes
INSERT INTO can_sizes (size_oz, name) VALUES
  (12, 'Standard 12oz'),
  (8.4, 'Slim 8.4oz'),
  (16, 'Tall 16oz'),
  (19.2, 'Stovepipe 19.2oz');

-- Add conversion constants
COMMENT ON TABLE batch_sizes IS 'Conversion factor: 1 gallon = 128 fluid ounces';