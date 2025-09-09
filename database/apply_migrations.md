# Apply Database Migrations

To fix the leaderboard issue, you need to apply these database migrations in your Supabase SQL Editor.

## Steps:

1. **Open Supabase Dashboard**
   - Go to your Supabase project dashboard
   - Navigate to the SQL Editor

2. **Apply Migration 001**
   - Copy the contents of `database/migrations/001_fix_leaderboard_view.sql`
   - Paste and execute in SQL Editor
   - This fixes the leaderboard view to include missing columns (`avatar_url` and `last_active_at`)

3. **Apply Migration 002**
   - Copy the contents of `database/migrations/002_fix_leaderboard_rls.sql`
   - Paste and execute in SQL Editor
   - This fixes the Row-Level Security policies to allow leaderboard access

4. **Restart the App**
   - After applying both migrations, restart your Flutter app
   - The leaderboard should now load with your existing demo data

## What These Migrations Fix:

- **Missing Columns**: The leaderboard view was missing `avatar_url` and `last_active_at` columns that the Flutter app expects
- **RLS Policies**: The users table RLS was too restrictive, preventing leaderboard queries from working
- **Query Type Issues**: Fixed PostgrestTransformBuilder vs PostgrestFilterBuilder conflicts in the Flutter code

## Verification:

After applying the migrations, you can verify they worked by running this query in the SQL Editor:

```sql
SELECT * FROM leaderboard LIMIT 10;
```

You should see a list of users with their rankings, including all the demo users you created with the comprehensive seeding script (arjun_eco_warrior, priya_green_queen, etc.).