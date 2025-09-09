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

-- Demo Data (for testing - remove in production)
-- Note: These are sample users with fake auth_ids for testing
INSERT INTO users (id, auth_id, username, email, total_points, level, avatar_url, last_active_at) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'EcoWarrior', 'eco@example.com', 2500, 5, null, now() - interval '1 hour'),
  ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'GreenThumb', 'green@example.com', 1800, 4, null, now() - interval '2 hours'),
  ('550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', 'RecycleKing', 'recycle@example.com', 1200, 3, null, now() - interval '3 hours'),
  ('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', 'CleanQueen', 'clean@example.com', 950, 2, null, now() - interval '4 hours'),
  ('550e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', 'EarthSaver', 'earth@example.com', 750, 2, null, now() - interval '5 hours')
ON CONFLICT (id) DO NOTHING;