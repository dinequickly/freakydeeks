-- =====================================================
-- OneShot App - Initial Database Schema Migration
-- For Supabase PostgreSQL
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- USERS TABLE (Extended)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.users (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  email text NOT NULL UNIQUE,
  first_name text,
  birthday date,
  gender text,
  gender_preference text,
  bio text,
  university text,
  major text,
  current_pair_id uuid,
  is_verified boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_email_key UNIQUE (email)
);

-- =====================================================
-- USER PHOTOS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_photos (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  url text NOT NULL,
  storage_path text,
  order_index integer NOT NULL,
  is_main boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT user_photos_pkey PRIMARY KEY (id),
  CONSTRAINT user_photos_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(id) ON DELETE CASCADE
);

-- =====================================================
-- INTERESTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.interests (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  name text NOT NULL,
  emoji text NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT interests_pkey PRIMARY KEY (id),
  CONSTRAINT interests_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(id) ON DELETE CASCADE
);

-- =====================================================
-- PROFILE PROMPTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profile_prompts (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  prompt_type text NOT NULL,
  answer text NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT profile_prompts_pkey PRIMARY KEY (id),
  CONSTRAINT profile_prompts_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(id) ON DELETE CASCADE
);

-- =====================================================
-- PAIRS TABLE (Duos)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.pairs (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user1_id uuid,
  user2_id uuid,
  duo_bio text,
  status text DEFAULT 'active',
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT pairs_pkey PRIMARY KEY (id),
  CONSTRAINT pairs_user1_id_fkey FOREIGN KEY (user1_id)
    REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT pairs_user2_id_fkey FOREIGN KEY (user2_id)
    REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT pairs_different_users CHECK (user1_id != user2_id)
);

-- Add foreign key from users to pairs
ALTER TABLE public.users
  ADD CONSTRAINT users_current_pair_id_fkey
  FOREIGN KEY (current_pair_id) REFERENCES public.pairs(id) ON DELETE SET NULL;

-- =====================================================
-- PAIR PROFILES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.pair_profiles (
  pair_id uuid NOT NULL,
  photos text[], -- Array of photo URLs
  bio text,
  interests text[], -- Array of interest names
  location point,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT pair_profiles_pkey PRIMARY KEY (pair_id),
  CONSTRAINT pair_profiles_pair_id_fkey FOREIGN KEY (pair_id)
    REFERENCES public.pairs(id) ON DELETE CASCADE
);

-- =====================================================
-- PAIR INVITES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.pair_invites (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  from_user_id uuid NOT NULL,
  to_user_id uuid NOT NULL,
  status text DEFAULT 'pending',
  message text,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT pair_invites_pkey PRIMARY KEY (id),
  CONSTRAINT pair_invites_from_user_id_fkey FOREIGN KEY (from_user_id)
    REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT pair_invites_to_user_id_fkey FOREIGN KEY (to_user_id)
    REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT pair_invites_different_users CHECK (from_user_id != to_user_id),
  CONSTRAINT pair_invites_status_check CHECK (status IN ('pending', 'accepted', 'declined'))
);

-- =====================================================
-- MATCHES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.matches (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  pair1_id uuid NOT NULL,
  pair2_id uuid NOT NULL,
  stream_channel_id text,
  status text DEFAULT 'active',
  matched_at timestamp without time zone DEFAULT now(),
  last_message_at timestamp without time zone,
  CONSTRAINT matches_pkey PRIMARY KEY (id),
  CONSTRAINT matches_pair1_id_fkey FOREIGN KEY (pair1_id)
    REFERENCES public.pairs(id) ON DELETE CASCADE,
  CONSTRAINT matches_pair2_id_fkey FOREIGN KEY (pair2_id)
    REFERENCES public.pairs(id) ON DELETE CASCADE,
  CONSTRAINT matches_different_pairs CHECK (pair1_id != pair2_id),
  CONSTRAINT matches_status_check CHECK (status IN ('active', 'archived', 'blocked'))
);

-- =====================================================
-- SWIPES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.swipes (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  swiper_pair_id uuid NOT NULL,
  swiped_pair_id uuid NOT NULL,
  swiper_user_id uuid NOT NULL,
  direction text NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT swipes_pkey PRIMARY KEY (id),
  CONSTRAINT swipes_swiper_pair_id_fkey FOREIGN KEY (swiper_pair_id)
    REFERENCES public.pairs(id) ON DELETE CASCADE,
  CONSTRAINT swipes_swiped_pair_id_fkey FOREIGN KEY (swiped_pair_id)
    REFERENCES public.pairs(id) ON DELETE CASCADE,
  CONSTRAINT swipes_swiper_user_id_fkey FOREIGN KEY (swiper_user_id)
    REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT swipes_direction_check CHECK (direction IN ('left', 'right', 'super'))
);

-- =====================================================
-- MESSAGES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  match_id uuid NOT NULL,
  sender_user_id uuid NOT NULL,
  content text NOT NULL,
  message_type text DEFAULT 'text',
  is_read boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_match_id_fkey FOREIGN KEY (match_id)
    REFERENCES public.matches(id) ON DELETE CASCADE,
  CONSTRAINT messages_sender_user_id_fkey FOREIGN KEY (sender_user_id)
    REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT messages_type_check CHECK (message_type IN ('text', 'dateSuggestion', 'icebreaker', 'image'))
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Users
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_current_pair_id ON public.users(current_pair_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at DESC);

-- User Photos
CREATE INDEX IF NOT EXISTS idx_user_photos_user_id ON public.user_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_user_photos_order ON public.user_photos(user_id, order_index);

-- Interests
CREATE INDEX IF NOT EXISTS idx_interests_user_id ON public.interests(user_id);

-- Profile Prompts
CREATE INDEX IF NOT EXISTS idx_profile_prompts_user_id ON public.profile_prompts(user_id);

-- Pairs
CREATE INDEX IF NOT EXISTS idx_pairs_user1_id ON public.pairs(user1_id);
CREATE INDEX IF NOT EXISTS idx_pairs_user2_id ON public.pairs(user2_id);
CREATE INDEX IF NOT EXISTS idx_pairs_status ON public.pairs(status);

-- Pair Invites
CREATE INDEX IF NOT EXISTS idx_pair_invites_from_user ON public.pair_invites(from_user_id);
CREATE INDEX IF NOT EXISTS idx_pair_invites_to_user ON public.pair_invites(to_user_id);
CREATE INDEX IF NOT EXISTS idx_pair_invites_status ON public.pair_invites(status);

-- Matches
CREATE INDEX IF NOT EXISTS idx_matches_pair1_id ON public.matches(pair1_id);
CREATE INDEX IF NOT EXISTS idx_matches_pair2_id ON public.matches(pair2_id);
CREATE INDEX IF NOT EXISTS idx_matches_matched_at ON public.matches(matched_at DESC);

-- Swipes
CREATE INDEX IF NOT EXISTS idx_swipes_swiper_pair ON public.swipes(swiper_pair_id);
CREATE INDEX IF NOT EXISTS idx_swipes_swiped_pair ON public.swipes(swiped_pair_id);
CREATE INDEX IF NOT EXISTS idx_swipes_created_at ON public.swipes(created_at DESC);

-- Messages
CREATE INDEX IF NOT EXISTS idx_messages_match_id ON public.messages(match_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_user_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(match_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON public.messages(match_id, is_read);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pairs_updated_at BEFORE UPDATE ON public.pairs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pair_invites_updated_at BEFORE UPDATE ON public.pair_invites
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create user on signup (called by Supabase Auth)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, created_at)
  VALUES (NEW.id, NEW.email, NEW.created_at);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user record when auth.users entry is created
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- COMMENTS (Documentation)
-- =====================================================

COMMENT ON TABLE public.users IS 'Core user profiles with authentication';
COMMENT ON TABLE public.pairs IS 'Duo partnerships between two users';
COMMENT ON TABLE public.matches IS 'Matches between two pairs/duos';
COMMENT ON TABLE public.swipes IS 'Swipe actions performed by users on pairs';
COMMENT ON TABLE public.messages IS 'Chat messages between matched pairs';
COMMENT ON TABLE public.pair_invites IS 'Invitations to form a duo partnership';

-- =====================================================
-- NOTES FOR SUPABASE SETUP
-- =====================================================

-- After running this migration:
-- 1. Go to Storage → Create bucket named "user-photos"
-- 2. Set bucket to PUBLIC
-- 3. Run the RLS policies from 002_row_level_security.sql
-- 4. Run the storage policies from 003_storage_policies.sql
-- 5. Configure Authentication providers (Email, Google)
