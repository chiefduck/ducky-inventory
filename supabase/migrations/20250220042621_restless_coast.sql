/*
  # Fix batch settings tables uniqueness

  1. Changes
    - Add unique constraint on user_id for batch_costs
    - Add unique constraint on user_id for batch_sizes
    - Clean up any duplicate records
*/

-- Clean up duplicate batch_costs records
WITH latest_costs AS (
  SELECT DISTINCT ON (user_id)
    id,
    user_id,
    can_cost_per_unit,
    tolling_cost_per_batch,
    created_at,
    updated_at
  FROM batch_costs
  ORDER BY user_id, updated_at DESC
)
DELETE FROM batch_costs
WHERE id NOT IN (SELECT id FROM latest_costs);

-- Clean up duplicate batch_sizes records
WITH latest_sizes AS (
  SELECT DISTINCT ON (user_id)
    id,
    user_id,
    size_gallons,
    cans_per_batch,
    created_at
  FROM batch_sizes
  ORDER BY user_id, created_at DESC
)
DELETE FROM batch_sizes
WHERE id NOT IN (SELECT id FROM latest_sizes);

-- Add unique constraints
ALTER TABLE batch_costs
ADD CONSTRAINT batch_costs_user_id_key UNIQUE (user_id);

ALTER TABLE batch_sizes
ADD CONSTRAINT batch_sizes_user_id_key UNIQUE (user_id);