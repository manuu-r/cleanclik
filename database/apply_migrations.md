# Database Migration Instructions

## Apply Function Fix

To fix the missing `add_user_points` function issue, run the following SQL commands in your Supabase SQL editor:

```sql
-- Fix the add_user_points function with correct parameter order
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
```

## Verification

After applying the migration, you can verify the function exists by running:

```sql
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name LIKE '%add%points%' 
AND routine_schema = 'public';
```

This should show both functions are available.