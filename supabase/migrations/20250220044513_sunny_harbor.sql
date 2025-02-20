/*
  # Add batch cost tracking

  1. New Tables
    - `batch_cost_summary` - Stores calculated batch costs
      - Total ingredient costs
      - Total packaging costs
      - Total freight costs
      - Total tolling costs
      - Total cost per batch
      - Cost per can

  2. Security
    - Enable RLS
    - Add policies for authenticated users
*/

-- Create batch cost summary table
CREATE TABLE batch_cost_summary (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) DEFAULT auth.uid(),
  flavor_id uuid REFERENCES flavors(id),
  batch_size_gallons numeric NOT NULL,
  total_ingredient_cost numeric NOT NULL,
  total_packaging_cost numeric NOT NULL,
  total_freight_cost numeric NOT NULL,
  total_tolling_cost numeric NOT NULL,
  total_batch_cost numeric NOT NULL,
  cost_per_can numeric NOT NULL,
  cans_per_batch integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE batch_cost_summary ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can manage their own batch cost summaries"
  ON batch_cost_summary
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);