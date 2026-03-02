/*
  # FineWash Backend Database Schema

  ## Overview
  Complete database schema for FineWash car wash subscription service.
  
  ## 1. New Tables
  
  ### `profiles`
  User profile information extending auth.users
  - `id` (uuid, primary key, references auth.users)
  - `name` (text, user's full name)
  - `phone` (text, contact number)
  - `avatar_url` (text, profile image URL, nullable)
  - `location` (text, user location - defaults to Accra)
  - `loyalty_status` (text, loyalty tier: bronze, silver, gold, platinum)
  - `loyalty_points` (integer, accumulated points)
  - `created_at` (timestamptz, record creation time)
  - `updated_at` (timestamptz, last update time)
  
  ### `subscription_plans`
  Available subscription plans for car washing services
  - `id` (uuid, primary key)
  - `name` (text, plan name)
  - `category` (text, plan category: single, weekly, biweekly, monthly)
  - `description` (text, plan description)
  - `price` (numeric, price in GHS)
  - `washes_count` (integer, number of washes included)
  - `wash_frequency` (text, frequency description)
  - `savings_percentage` (integer, discount percentage)
  - `features` (jsonb, array of features)
  - `badge` (text, optional badge text, nullable)
  - `is_active` (boolean, whether plan is currently offered)
  - `created_at` (timestamptz)
  
  ### `service_types`
  Types of wash services available (Basic, Premium, Deluxe)
  - `id` (uuid, primary key)
  - `name` (text, service name)
  - `description` (text, service description)
  - `base_price_modifier` (numeric, price multiplier)
  - `features` (jsonb, service features)
  - `created_at` (timestamptz)
  
  ### `user_subscriptions`
  User's active and historical subscriptions
  - `id` (uuid, primary key)
  - `user_id` (uuid, references profiles)
  - `plan_id` (uuid, references subscription_plans)
  - `service_type_id` (uuid, references service_types)
  - `status` (text, subscription status: active, pending, completed, cancelled)
  - `start_date` (timestamptz, subscription start)
  - `end_date` (timestamptz, subscription end, nullable)
  - `next_wash_date` (timestamptz, next scheduled wash, nullable)
  - `total_washes_used` (integer, washes completed)
  - `payment_status` (text, payment status: pending, completed, failed)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)
  
  ### `car_details`
  User vehicle information
  - `id` (uuid, primary key)
  - `user_id` (uuid, references profiles)
  - `make` (text, car manufacturer)
  - `model` (text, car model)
  - `year` (integer, manufacturing year)
  - `color` (text, car color)
  - `plate_number` (text, registration plate)
  - `is_primary` (boolean, primary vehicle flag)
  - `created_at` (timestamptz)
  
  ### `notifications`
  User notifications system
  - `id` (uuid, primary key)
  - `user_id` (uuid, references profiles)
  - `title` (text, notification title)
  - `message` (text, notification content)
  - `type` (text, notification type: subscription, payment, reminder, offer)
  - `read` (boolean, read status)
  - `created_at` (timestamptz)
  
  ### `payments`
  Payment transaction records
  - `id` (uuid, primary key)
  - `user_id` (uuid, references profiles)
  - `subscription_id` (uuid, references user_subscriptions)
  - `amount` (numeric, payment amount in GHS)
  - `payment_method` (text, payment type: mobile_money, card, bank)
  - `status` (text, payment status: pending, completed, failed)
  - `transaction_id` (text, unique transaction identifier)
  - `provider_reference` (text, payment provider reference, nullable)
  - `created_at` (timestamptz)
  
  ## 2. Security
  - Enable RLS on all tables
  - Users can only access their own data
  - Public read access for plans and service types
  - Authenticated users can create subscriptions and payments
  
  ## 3. Indexes
  - Performance indexes on frequently queried columns
  - Foreign key indexes for joins
  
  ## 4. Functions
  - Automatic profile creation on user signup
  - Loyalty points calculation
  - Next wash date calculator
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text,
  avatar_url text,
  location text DEFAULT 'Accra',
  loyalty_status text DEFAULT 'bronze' CHECK (loyalty_status IN ('bronze', 'silver', 'gold', 'platinum')),
  loyalty_points integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create subscription_plans table
CREATE TABLE IF NOT EXISTS subscription_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text NOT NULL CHECK (category IN ('single', 'weekly', 'biweekly', 'monthly')),
  description text NOT NULL,
  price numeric(10,2) NOT NULL,
  washes_count integer NOT NULL,
  wash_frequency text NOT NULL,
  savings_percentage integer DEFAULT 0,
  features jsonb DEFAULT '[]'::jsonb,
  badge text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Create service_types table
CREATE TABLE IF NOT EXISTS service_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text NOT NULL,
  base_price_modifier numeric(3,2) DEFAULT 1.0,
  features jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now()
);

-- Create user_subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  plan_id uuid NOT NULL REFERENCES subscription_plans(id) ON DELETE RESTRICT,
  service_type_id uuid NOT NULL REFERENCES service_types(id) ON DELETE RESTRICT,
  status text DEFAULT 'pending' CHECK (status IN ('active', 'pending', 'completed', 'cancelled')),
  start_date timestamptz NOT NULL,
  end_date timestamptz,
  next_wash_date timestamptz,
  total_washes_used integer DEFAULT 0,
  payment_status text DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create car_details table
CREATE TABLE IF NOT EXISTS car_details (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  make text NOT NULL,
  model text NOT NULL,
  year integer,
  color text,
  plate_number text,
  is_primary boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL CHECK (type IN ('subscription', 'payment', 'reminder', 'offer')),
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  subscription_id uuid REFERENCES user_subscriptions(id) ON DELETE SET NULL,
  amount numeric(10,2) NOT NULL,
  payment_method text NOT NULL CHECK (payment_method IN ('mobile_money', 'card', 'bank')),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  transaction_id text UNIQUE NOT NULL,
  provider_reference text,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE car_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- RLS Policies for subscription_plans (public read)
CREATE POLICY "Anyone can view active plans"
  ON subscription_plans FOR SELECT
  TO authenticated
  USING (is_active = true);

-- RLS Policies for service_types (public read)
CREATE POLICY "Anyone can view service types"
  ON service_types FOR SELECT
  TO authenticated
  USING (true);

-- RLS Policies for user_subscriptions
CREATE POLICY "Users can view own subscriptions"
  ON user_subscriptions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own subscriptions"
  ON user_subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions"
  ON user_subscriptions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own subscriptions"
  ON user_subscriptions FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- RLS Policies for car_details
CREATE POLICY "Users can view own cars"
  ON car_details FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own car details"
  ON car_details FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own car details"
  ON car_details FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own car details"
  ON car_details FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- RLS Policies for notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- RLS Policies for payments
CREATE POLICY "Users can view own payments"
  ON payments FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own payments"
  ON payments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_loyalty_status ON profiles(loyalty_status);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_category ON subscription_plans(category);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON subscription_plans(is_active);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_next_wash ON user_subscriptions(next_wash_date);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_subscription_id ON payments(subscription_id);
CREATE INDEX IF NOT EXISTS idx_car_details_user_id ON car_details(user_id);

-- Function to automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name, phone, avatar_url, location)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', ''),
    COALESCE(new.raw_user_meta_data->>'phone', ''),
    COALESCE(new.raw_user_meta_data->>'avatar_url', ''),
    COALESCE(new.raw_user_meta_data->>'location', 'Accra')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS set_updated_at_profiles ON profiles;
CREATE TRIGGER set_updated_at_profiles
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_user_subscriptions ON user_subscriptions;
CREATE TRIGGER set_updated_at_user_subscriptions
  BEFORE UPDATE ON user_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Function to calculate loyalty points based on spending
CREATE OR REPLACE FUNCTION public.update_loyalty_points()
RETURNS trigger AS $$
DECLARE
  points_earned integer;
  total_points integer;
  new_status text;
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    -- Award 1 point per GHS spent
    SELECT amount INTO points_earned
    FROM payments
    WHERE subscription_id = NEW.id AND status = 'completed'
    LIMIT 1;
    
    IF points_earned IS NOT NULL THEN
      -- Update loyalty points
      UPDATE profiles
      SET loyalty_points = loyalty_points + points_earned
      WHERE id = NEW.user_id
      RETURNING loyalty_points INTO total_points;
      
      -- Update loyalty status based on points
      IF total_points >= 5000 THEN
        new_status := 'platinum';
      ELSIF total_points >= 2000 THEN
        new_status := 'gold';
      ELSIF total_points >= 500 THEN
        new_status := 'silver';
      ELSE
        new_status := 'bronze';
      END IF;
      
      UPDATE profiles
      SET loyalty_status = new_status
      WHERE id = NEW.user_id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for loyalty points
DROP TRIGGER IF EXISTS calculate_loyalty_points ON user_subscriptions;
CREATE TRIGGER calculate_loyalty_points
  AFTER UPDATE ON user_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_loyalty_points();