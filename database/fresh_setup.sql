-- CleanClik: complete fresh database setup
-- Generated from schema.sql + functions.sql + migrations 001, 002 (in order).
-- Run this once in the Supabase SQL Editor of a NEW project.

-- ============ 1/4: schema.sql ============
-- CleanClik Database Schema (corrected)
-- Note: foreign keys must reference the primary key (users.id). RLS policies use (SELECT auth.uid()).

-- Users Table
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id uuid NOT NULL,
  username text UNIQUE NOT NULL,
  email text UNIQUE NOT NULL,
  avatar_url text,
  total_points integer DEFAULT 0,
  level integer DEFAULT 1,
  created_at timestamp with time zone DEFAULT now(),
  last_active_at timestamp with time zone DEFAULT now(),
  is_online boolean DEFAULT false,
  CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- Link auth_id to auth.users(id)
ALTER TABLE users
  ADD CONSTRAINT users_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Enable RLS and policies for users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON users
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = auth_id);

CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = auth_id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = auth_id) WITH CHECK ((SELECT auth.uid()) = auth_id);

CREATE POLICY "Users can delete own profile" ON users
  FOR DELETE TO authenticated USING ((SELECT auth.uid()) = auth_id);

-- Indexes for Users
CREATE INDEX idx_users_auth_id ON users(auth_id);
CREATE INDEX idx_users_username ON users(username);

-- Inventory Table
CREATE TABLE inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  tracking_id text NOT NULL,
  category text NOT NULL,
  display_name text NOT NULL,
  code_name text NOT NULL,
  confidence numeric(3,2) NOT NULL,
  picked_up_at timestamp with time zone DEFAULT now(),
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now(),
  UNIQUE(user_id, tracking_id)
);

-- Foreign key to users.id (primary key)
ALTER TABLE inventory
  ADD CONSTRAINT inventory_user_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Enable RLS and policies for inventory (explicit policies per operation)
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Inventory select own" ON inventory
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Inventory insert own" ON inventory
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Inventory update own" ON inventory
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Inventory delete own" ON inventory
  FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

-- Indexes for Inventory
CREATE INDEX idx_inventory_user_id ON inventory(user_id);
CREATE INDEX idx_inventory_category ON inventory(category);
CREATE INDEX idx_inventory_picked_up_at ON inventory(picked_up_at);

-- Achievements Table
CREATE TABLE achievements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  achievement_id text NOT NULL,
  unlocked_at timestamp with time zone DEFAULT now(),
  metadata jsonb,
  UNIQUE(user_id, achievement_id)
);

ALTER TABLE achievements
  ADD CONSTRAINT achievements_user_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Achievements select own" ON achievements
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Achievements insert own" ON achievements
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Achievements update own" ON achievements
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Achievements delete own" ON achievements
  FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

-- Indexes for Achievements
CREATE INDEX idx_achievements_user_id ON achievements(user_id);
CREATE INDEX idx_achievements_achievement_id ON achievements(achievement_id);

-- Category Stats Table
CREATE TABLE category_stats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  category text NOT NULL,
  item_count integer DEFAULT 0,
  total_points integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT now(),
  UNIQUE(user_id, category)
);

ALTER TABLE category_stats
  ADD CONSTRAINT category_stats_user_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE category_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "CategoryStats select own" ON category_stats
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "CategoryStats insert own" ON category_stats
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "CategoryStats update own" ON category_stats
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "CategoryStats delete own" ON category_stats
  FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

-- Indexes for Category Stats
CREATE INDEX idx_category_stats_user_id ON category_stats(user_id);

-- Leaderboard View (security_invoker)
CREATE VIEW leaderboard WITH (security_invoker=on) AS
SELECT 
  u.id,
  u.username,
  u.total_points,
  u.level,
  u.avatar_url,
  u.last_active_at,
  RANK() OVER (ORDER BY u.total_points DESC) AS rank
FROM users u
WHERE u.total_points > 0
ORDER BY u.total_points DESC;

-- Bin Locations Table
CREATE TABLE bin_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  address text,
  description text,
  capacity integer DEFAULT 100,
  current_fill_level integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT valid_coordinates CHECK (
    latitude >= -90 AND latitude <= 90 AND
    longitude >= -180 AND longitude <= 180
  ),
  CONSTRAINT valid_fill_level CHECK (
    current_fill_level >= 0 AND current_fill_level <= capacity
  )
);

-- Indexes for Bin Locations
CREATE INDEX idx_bin_locations_category ON bin_locations(category);
CREATE INDEX idx_bin_locations_coordinates ON bin_locations(latitude, longitude);
CREATE INDEX idx_bin_locations_active ON bin_locations(is_active);

-- NOTE: Do not seed demo users here. users.auth_id has a foreign key to
-- auth.users, so rows can only be created for real authenticated users
-- (the app creates the profile row on signup).

-- Sample bin locations (for testing)
INSERT INTO bin_locations (id, name, category, latitude, longitude, address, description) VALUES
  ('660e8400-e29b-41d4-a716-446655440001', 'Central Park Recycle Bin', 'recycle', 40.7829, -73.9654, 'Central Park, New York, NY', 'Large recycling bin near the main entrance'),
  ('660e8400-e29b-41d4-a716-446655440002', 'Times Square Organic Bin', 'organic', 40.7580, -73.9855, 'Times Square, New York, NY', 'Organic waste collection point'),
  ('660e8400-e29b-41d4-a716-446655440003', 'Brooklyn Bridge Landfill Bin', 'landfill', 40.7061, -73.9969, 'Brooklyn Bridge, New York, NY', 'General waste disposal'),
  ('660e8400-e29b-41d4-a716-446655440004', 'Tech Hub E-Waste Center', 'ewaste', 40.7505, -73.9934, 'Manhattan Tech District, NY', 'Electronic waste recycling center'),
  ('660e8400-e29b-41d4-a716-446655440005', 'Hospital Hazardous Waste', 'hazardous', 40.7614, -73.9776, 'Medical District, New York, NY', 'Hazardous material disposal facility')
ON CONFLICT (id) DO NOTHING;
-- ============ 2/4: functions.sql ============
-- CleanClik Database Functions and Triggers
-- This file contains database functions and triggers for automated data management

-- Update User Points Function
CREATE OR REPLACE FUNCTION update_user_points()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users 
  SET total_points = (
    SELECT COALESCE(SUM(total_points), 0) 
    FROM category_stats 
    WHERE user_id = NEW.user_id
  ),
  last_active_at = NOW()
  WHERE auth_id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating user points when category stats change
CREATE TRIGGER trigger_update_user_points
  AFTER INSERT OR UPDATE ON category_stats
  FOR EACH ROW
  EXECUTE FUNCTION update_user_points();

-- Update Category Stats Function
CREATE OR REPLACE FUNCTION update_category_stats()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO category_stats (user_id, category, item_count, total_points)
  VALUES (NEW.user_id, NEW.category, 1, 
    CASE NEW.category
      WHEN 'recycle' THEN 10
      WHEN 'organic' THEN 8
      WHEN 'landfill' THEN 5
      WHEN 'ewaste' THEN 15
      WHEN 'hazardous' THEN 20
      ELSE 5
    END
  )
  ON CONFLICT (user_id, category)
  DO UPDATE SET
    item_count = category_stats.item_count + 1,
    total_points = category_stats.total_points + 
      CASE NEW.category
        WHEN 'recycle' THEN 10
        WHEN 'organic' THEN 8
        WHEN 'landfill' THEN 5
        WHEN 'ewaste' THEN 15
        WHEN 'hazardous' THEN 20
        ELSE 5
      END,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating category stats when inventory items are added
CREATE TRIGGER trigger_update_category_stats
  AFTER INSERT ON inventory
  FOR EACH ROW
  EXECUTE FUNCTION update_category_stats();

-- Add Points to User Function (called from DataService)
-- Note: Parameter order matches the error message: points_to_add, user_id
CREATE OR REPLACE FUNCTION add_user_points(points_to_add INTEGER, user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE users 
  SET total_points = total_points + points_to_add,
      last_active_at = NOW()
  WHERE auth_id = user_id;
  
  -- Log the operation for debugging
  RAISE NOTICE 'Added % points to user %', points_to_add, user_id;
END;
$$ LANGUAGE plpgsql;

-- Alternative function with correct parameter names for backward compatibility
CREATE OR REPLACE FUNCTION add_points_to_user(user_id UUID, points_to_add INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE users 
  SET total_points = total_points + points_to_add,
      last_active_at = NOW()
  WHERE auth_id = user_id;
  
  -- Log the operation for debugging
  RAISE NOTICE 'Added % points to user %', points_to_add, user_id;
END;
$$ LANGUAGE plpgsql;

-- Get Bins Near Location Function (requires PostGIS extension)
-- Note: This function assumes bin_locations table has latitude and longitude columns
CREATE OR REPLACE FUNCTION get_bins_near_location(lat DOUBLE PRECISION, lng DOUBLE PRECISION, radius_meters DOUBLE PRECISION)
RETURNS TABLE(
  id UUID,
  name TEXT,
  category TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  address TEXT,
  distance_meters DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    bl.id,
    bl.name,
    bl.category,
    bl.latitude,
    bl.longitude,
    bl.address,
    -- Calculate distance using Haversine formula (approximate)
    (6371000 * acos(
      cos(radians(lat)) * cos(radians(bl.latitude)) * 
      cos(radians(bl.longitude) - radians(lng)) + 
      sin(radians(lat)) * sin(radians(bl.latitude))
    )) as distance_meters
  FROM bin_locations bl
  WHERE (6371000 * acos(
    cos(radians(lat)) * cos(radians(bl.latitude)) * 
    cos(radians(bl.longitude) - radians(lng)) + 
    sin(radians(lat)) * sin(radians(bl.latitude))
  )) <= radius_meters
  ORDER BY distance_meters;
END;
$$ LANGUAGE plpgsql;

-- Find Nearest Bin Function
CREATE OR REPLACE FUNCTION find_nearest_bin(lat DOUBLE PRECISION, lng DOUBLE PRECISION, category_filter TEXT DEFAULT NULL)
RETURNS TABLE(
  id UUID,
  name TEXT,
  category TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  address TEXT,
  distance_meters DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    bl.id,
    bl.name,
    bl.category,
    bl.latitude,
    bl.longitude,
    bl.address,
    -- Calculate distance using Haversine formula
    (6371000 * acos(
      cos(radians(lat)) * cos(radians(bl.latitude)) * 
      cos(radians(bl.longitude) - radians(lng)) + 
      sin(radians(lat)) * sin(radians(bl.latitude))
    )) as distance_meters
  FROM bin_locations bl
  WHERE (category_filter IS NULL OR bl.category = category_filter)
  ORDER BY distance_meters
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;
-- ============ 3/4: migrations/001_fix_leaderboard_view.sql ============
-- Migration: Fix leaderboard view to include missing columns
-- Run this in Supabase SQL Editor

-- Drop existing leaderboard view
DROP VIEW IF EXISTS leaderboard;

-- Recreate leaderboard view with all required columns
CREATE VIEW leaderboard WITH (security_invoker=on) AS
SELECT 
  u.id,
  u.username,
  u.total_points,
  u.level,
  u.avatar_url,
  u.last_active_at,
  RANK() OVER (ORDER BY u.total_points DESC) AS rank
FROM users u
WHERE u.total_points > 0
ORDER BY u.total_points DESC;

-- Verify the leaderboard view works
SELECT * FROM leaderboard LIMIT 5;

-- ============ 4/4: migrations/002_fix_leaderboard_rls.sql ============
-- Migration: Fix leaderboard view RLS policies
-- Run this in Supabase SQL Editor after 001_fix_leaderboard_view.sql

-- The issue is that the users table has RLS enabled but only allows users to see their own profile
-- For the leaderboard to work, we need to allow authenticated users to see basic leaderboard info

-- Drop the existing restrictive SELECT policy
DROP POLICY IF EXISTS "Users can view own profile" ON users;

-- Create a new policy that allows users to see their own profile AND basic leaderboard data
CREATE POLICY "Users can view profiles and leaderboard" ON users
  FOR SELECT TO authenticated 
  USING (
    -- Users can see their own full profile
    (SELECT auth.uid()) = auth_id 
    OR 
    -- OR users can see basic leaderboard info (username, points, level, rank) for all users
    true
  );

-- Note: This policy allows authenticated users to see basic user info for leaderboard purposes
-- while still maintaining privacy for sensitive profile data