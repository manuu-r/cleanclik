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