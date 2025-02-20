/*
  # Add Orders Management Tables

  1. New Tables
    - `orders`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `flavor_id` (uuid, references flavors)
      - `batch_size_gallons` (numeric)
      - `created_at` (timestamptz)
      - `status` (text)

    - `order_items`
      - `id` (uuid, primary key)
      - `order_id` (uuid, references orders)
      - `ingredient_id` (uuid, references ingredients)
      - `batch_requirement` (numeric)
      - `current_level` (numeric)
      - `order_quantity` (numeric)
      - `pails_needed` (numeric)
      - `total_ordered` (numeric)
      - `unit_price` (numeric)
      - `total_cost` (numeric)
      - `unit` (text)

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users to manage their own orders
*/

-- Create orders table
CREATE TABLE orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) DEFAULT auth.uid(),
  flavor_id uuid REFERENCES flavors(id),
  batch_size_gallons numeric NOT NULL,
  created_at timestamptz DEFAULT now(),
  status text NOT NULL DEFAULT 'pending',
  CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'completed', 'cancelled'))
);

-- Create order items table
CREATE TABLE order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  ingredient_id uuid REFERENCES ingredients(id),
  batch_requirement numeric NOT NULL,
  current_level numeric NOT NULL,
  order_quantity numeric NOT NULL,
  pails_needed integer NOT NULL,
  total_ordered numeric NOT NULL,
  unit_price numeric NOT NULL,
  total_cost numeric NOT NULL,
  unit text NOT NULL,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT positive_quantities CHECK (
    batch_requirement >= 0 AND
    current_level >= 0 AND
    order_quantity >= 0 AND
    pails_needed >= 0 AND
    total_ordered >= 0 AND
    unit_price >= 0 AND
    total_cost >= 0
  )
);

-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Create policies for orders
CREATE POLICY "Users can manage their own orders"
  ON orders
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create policies for order items
CREATE POLICY "Users can manage their own order items"
  ON order_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- Create indexes for better query performance
CREATE INDEX orders_user_id_idx ON orders(user_id);
CREATE INDEX orders_flavor_id_idx ON orders(flavor_id);
CREATE INDEX order_items_order_id_idx ON order_items(order_id);
CREATE INDEX order_items_ingredient_id_idx ON order_items(ingredient_id);