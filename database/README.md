# Database Setup Instructions

This directory contains the SQL scripts needed to set up the CleanClik database schema in Supabase.

## Files

- `schema.sql` - Complete database schema with tables, indexes, and RLS policies
- `functions.sql` - Database functions and triggers for automated data management

## Setup Instructions

### 1. Create Supabase Project

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Create a new project
3. Wait for the project to be fully provisioned

### 2. Run Database Scripts

1. Open the Supabase SQL Editor in your project dashboard
2. Copy and paste the contents of `schema.sql`
3. Execute the script to create tables, indexes, and RLS policies
4. Copy and paste the contents of `functions.sql`
5. Execute the script to create functions and triggers

### 3. Configure Environment Variables

1. Copy `.env.example` to `.env` in your project root
2. Fill in your Supabase project URL and anon key:
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_PUBLISHABLE_KEY=your-anon-key-here
   ```

### 4. Verify Setup

The database schema includes the following tables:
- `users` - User profiles and authentication data
- `inventory` - User inventory items with waste categorization
- `achievements` - User achievements and unlocks
- `category_stats` - Aggregated statistics per waste category
- `leaderboard` - View for user rankings

All tables have Row-Level Security (RLS) enabled to ensure users can only access their own data.

## Security Features

- **Row-Level Security**: All user data tables have RLS policies
- **Foreign Key Constraints**: Proper referential integrity
- **Input Validation**: Database-level constraints and checks
- **Automated Triggers**: Points and statistics are updated automatically

## Testing the Setup

After running the scripts, you can test the setup by:

1. Creating a test user through Supabase Auth
2. Inserting test data into the inventory table
3. Verifying that category_stats and user points are updated automatically
4. Checking that RLS policies prevent access to other users' data