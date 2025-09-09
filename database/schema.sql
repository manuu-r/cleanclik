-- CleanClik Database Schema
-- This file contains the complete database schema for the CleanClik application

-- Users Table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  avatar_url TEXT,
  total_points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_online BOOLEAN DEFAULT FALSE,
  CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- RLS Policies for Users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth_id = auth.uid());

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth_id = auth.uid());

-- Indexes for Users
CREATE INDEX idx_users_auth_id ON users(auth_id);
CREATE INDEX idx_users_username ON users(username);

-- Inventory Table
CREATE TABLE inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(auth_id) ON DELETE CASCADE,
  tracking_id VARCHAR(100) NOT NULL,
  category VARCHAR(20) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  code_name VARCHAR(100) NOT NULL,
  confidence DECIMAL(3,2) NOT NULL,
  picked_up_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, tracking_id)
);

-- RLS Policies for Inventory
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own inventory" ON inventory
  FOR ALL USING (user_id = auth.uid());

-- Indexes for Inventory
CREATE INDEX idx_inventory_user_id ON inventory(user_id);
CREATE INDEX idx_inventory_category ON inventory(category);
CREATE INDEX idx_inventory_picked_up_at ON inventory(picked_up_at);

-- Achievements Table
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(auth_id) ON DELETE CASCADE,
  achievement_id VARCHAR(50) NOT NULL,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB,
  UNIQUE(user_id, achievement_id)
);

-- RLS Policies for Achievements
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own achievements" ON achievements
  FOR SELECT USING (user_id = auth.uid());

-- Indexes for Achievements
CREATE INDEX idx_achievements_user_id ON achievements(user_id);
CREATE INDEX idx_achievements_achievement_id ON achievements(achievement_id);

-- Category Stats Table
CREATE TABLE category_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(auth_id) ON DELETE CASCADE,
  category VARCHAR(20) NOT NULL,
  item_count INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, category)
);

-- RLS Policies for Category Stats
ALTER TABLE category_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own stats" ON category_stats
  FOR ALL USING (user_id = auth.uid());

-- Indexes for Category Stats
CREATE INDEX idx_category_stats_user_id ON category_stats(user_id);

-- Leaderboard View
CREATE VIEW leaderboard AS
SELECT 
  u.id,
  u.username,
  u.total_points,
  u.level,
  RANK() OVER (ORDER BY u.total_points DESC) as rank
FROM users u
WHERE u.total_points > 0
ORDER BY u.total_points DESC;