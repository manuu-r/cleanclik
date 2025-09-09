---
inclusion: manual
---

# Database Schema Reference

## Complete SQL Schema

### Users Table
```sql
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

-- RLS Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth_id = auth.uid());

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth_id = auth.uid());

-- Indexes
CREATE INDEX idx_users_auth_id ON users(auth_id);
CREATE INDEX idx_users_username ON users(username);
```

### Inventory Table
```sql
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

-- RLS Policies
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own inventory" ON inventory
  FOR ALL USING (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_inventory_user_id ON inventory(user_id);
CREATE INDEX idx_inventory_category ON inventory(category);
CREATE INDEX idx_inventory_picked_up_at ON inventory(picked_up_at);
```

### Achievements Table
```sql
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(auth_id) ON DELETE CASCADE,
  achievement_id VARCHAR(50) NOT NULL,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB,
  UNIQUE(user_id, achievement_id)
);

-- RLS Policies
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own achievements" ON achievements
  FOR SELECT USING (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_achievements_user_id ON achievements(user_id);
CREATE INDEX idx_achievements_achievement_id ON achievements(achievement_id);
```

### Category Stats Table
```sql
CREATE TABLE category_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(auth_id) ON DELETE CASCADE,
  category VARCHAR(20) NOT NULL,
  item_count INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, category)
);

-- RLS Policies
ALTER TABLE category_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own stats" ON category_stats
  FOR ALL USING (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_category_stats_user_id ON category_stats(user_id);
```

### Leaderboard View
```sql
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
```

## Database Functions and Triggers

### Update User Points Function
```sql
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

CREATE TRIGGER trigger_update_user_points
  AFTER INSERT OR UPDATE ON category_stats
  FOR EACH ROW
  EXECUTE FUNCTION update_user_points();
```

### Update Category Stats Function
```sql
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

CREATE TRIGGER trigger_update_category_stats
  AFTER INSERT ON inventory
  FOR EACH ROW
  EXECUTE FUNCTION update_category_stats();
```