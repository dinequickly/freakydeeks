# OneShot Database Setup Guide

## Overview
This directory contains all database migration scripts for the OneShot double dating app using Supabase (PostgreSQL).

## Prerequisites
- Supabase account (free tier works)
- Project created in Supabase dashboard

## Setup Steps

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Fill in project details:
   - Name: OneShot
   - Database Password: (generate strong password)
   - Region: Choose closest to your users
4. Wait for project to be created (~2 minutes)

### 2. Save Your Credentials
After project creation, save these values (you'll need them for iOS app):
- Project URL: Found in Settings → API
- Anon (public) Key: Found in Settings → API
- Service Role Key: Found in Settings → API (keep secret!)

### 3. Run Database Migrations

#### Option A: Using SQL Editor (Recommended)
1. Go to SQL Editor in Supabase dashboard
2. Click "New Query"
3. Copy and paste `Migrations/001_initial_schema.sql`
4. Click "Run" or press Cmd/Ctrl + Enter
5. Verify no errors
6. Repeat for `002_row_level_security.sql`

#### Option B: Using Supabase CLI
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations
supabase db push
```

### 4. Set Up Storage Bucket
1. Go to Storage in Supabase dashboard
2. Click "New bucket"
3. Name: `user-photos`
4. Set to **PUBLIC** (important!)
5. Click Create
6. Go to SQL Editor
7. Run `Migrations/003_storage_policies.sql`

### 5. Configure Authentication

#### Enable Email/Password Auth
1. Go to Authentication → Providers
2. Email provider should be enabled by default
3. Configure email templates (optional):
   - Confirmation email
   - Password reset email
   - Invite email

#### Enable Google OAuth
1. Go to Authentication → Providers
2. Click on "Google"
3. Enable Google provider
4. You'll need to set up Google OAuth:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create new project or select existing
   - Enable Google+ API
   - Create OAuth 2.0 credentials
   - Add authorized redirect URIs:
     - `https://{YOUR_PROJECT_REF}.supabase.co/auth/v1/callback`
   - Copy Client ID and Client Secret
5. Paste credentials into Supabase
6. Save

#### iOS Configuration for Google Sign-In
You'll need to add these to your iOS app:
- Add Google Sign-In SDK
- Configure URL schemes
- Add GoogleService-Info.plist

### 6. Verify Setup

Run this query in SQL Editor to verify tables are created:
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

You should see:
- interests
- matches
- messages
- pair_invites
- pair_profiles
- pairs
- profile_prompts
- swipes
- user_photos
- users

### 7. Test Authentication

1. Go to Authentication → Users
2. Click "Add user"
3. Create test user with email/password
4. Verify user appears in both:
   - Authentication → Users (auth.users)
   - Table Editor → users (public.users)

If user appears in both tables, your `handle_new_user()` trigger is working!

## Database Schema Overview

### Core Tables

**users**
- Primary user profile data
- Links to auth.users via trigger
- Contains basic info: name, birthday, gender, etc.

**user_photos**
- Individual user photos
- Stores Supabase Storage URLs
- Ordered by order_index

**interests**
- User interests with emoji
- Many-to-many via individual records

**profile_prompts**
- User profile prompts and answers
- Flexible prompt types

**pairs**
- Duo partnerships (2 users)
- Core entity for matching

**pair_invites**
- Invitations to form duos
- Status: pending/accepted/declined

**matches**
- Matches between two pairs (4 people total)
- Created when both pairs swipe right

**swipes**
- Individual swipe actions
- Direction: left/right/super

**messages**
- Chat messages between matched pairs
- Supports multiple message types

### Relationships

```
auth.users (Supabase Auth)
    ↓ (trigger creates)
users
    ↓ (one-to-many)
user_photos, interests, profile_prompts
    ↓ (many-to-one)
pairs (user1_id, user2_id)
    ↓ (many-to-many via swipes)
matches (pair1_id, pair2_id)
    ↓ (one-to-many)
messages
```

## Security

### Row Level Security (RLS)
All tables have RLS enabled with policies:
- Users can only access their own data
- Users can view profiles of matched pairs
- Users can only perform actions on their own pairs
- Messages are only visible to match participants

### Storage Security
- Users can only upload to their own folder
- All photos are publicly readable (for discovery)
- Automatic cleanup when photos are deleted

## Indexes

Performance indexes are created on:
- Foreign keys
- Lookup fields (email, status)
- Sort fields (created_at)
- Filter fields (pair_id, match_id)

## Next Steps

After database setup:
1. Copy Project URL and Anon Key
2. Add to iOS app in `SupabaseConfig.swift`
3. Install Supabase Swift SDK
4. Implement authentication flow
5. Connect services to database

## Troubleshooting

### Trigger not working
If users aren't being created in public.users:
```sql
-- Check if trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';

-- Manually test function
SELECT public.handle_new_user();
```

### RLS blocking queries
If legitimate queries are blocked:
```sql
-- Check active policies
SELECT * FROM pg_policies WHERE schemaname = 'public';

-- Temporarily disable RLS for testing (DON'T DO IN PRODUCTION)
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
```

### Storage not working
- Verify bucket is PUBLIC
- Check storage policies are created
- Verify file paths match policy patterns

## Support

- Supabase Docs: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com
- PostgreSQL Docs: https://www.postgresql.org/docs/
