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