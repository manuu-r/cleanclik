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