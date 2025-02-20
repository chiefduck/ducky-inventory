/*
  # Add ID to pricing tiers

  1. Changes
    - Add ID column to pricing tiers for better state management
    - Update existing pricing tiers with IDs
*/

-- Add ID column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pricing_tiers' AND column_name = 'tier_id'
  ) THEN
    ALTER TABLE pricing_tiers
    ADD COLUMN tier_id uuid DEFAULT gen_random_uuid();
  END IF;
END $$;