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
RETURNS VOID AS $
BEGIN
  UPDATE users 
  SET total_points = total_points + points_to_add,
      last_active_at = NOW()
  WHERE auth_id = user_id;
  
  -- Log the operation for debugging
  RAISE NOTICE 'Added % points to user %', points_to_add, user_id;
END;
$ LANGUAGE plpgsql;

-- Alternative function with correct parameter names for backward compatibility
CREATE OR REPLACE FUNCTION add_points_to_user(user_id UUID, points_to_add INTEGER)
RETURNS VOID AS $
BEGIN
  UPDATE users 
  SET total_points = total_points + points_to_add,
      last_active_at = NOW()
  WHERE auth_id = user_id;
  
  -- Log the operation for debugging
  RAISE NOTICE 'Added % points to user %', points_to_add, user_id;
END;
$ LANGUAGE plpgsql;

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
) AS $
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
$ LANGUAGE plpgsql;

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
) AS $
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
$ LANGUAGE plpgsql;