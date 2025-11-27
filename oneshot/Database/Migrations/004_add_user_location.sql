-- =====================================================
-- Add location field to users table
-- Migration 004 - User Location Preference
-- =====================================================

-- Add location column to users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS location text DEFAULT 'london';

-- Add constraint to ensure valid location values
ALTER TABLE public.users
ADD CONSTRAINT users_location_check
CHECK (location IN ('london', 'chicago'));

-- Create index for location filtering
CREATE INDEX IF NOT EXISTS idx_users_location ON public.users(location);

-- Add comment
COMMENT ON COLUMN public.users.location IS 'User location preference: london or chicago';
