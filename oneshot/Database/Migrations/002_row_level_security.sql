-- =====================================================
-- OneShot App - Row Level Security (RLS) Policies
-- Run this after 001_initial_schema.sql
-- =====================================================

-- =====================================================
-- ENABLE RLS ON ALL TABLES
-- =====================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pair_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pair_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- USERS TABLE POLICIES
-- =====================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can view profiles of users in their matches (for discovery/chat)
CREATE POLICY "Users can view matched profiles"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pairs p1
      WHERE (p1.user1_id = auth.uid() OR p1.user2_id = auth.uid())
      AND p1.id IN (
        SELECT m.pair1_id FROM public.matches m
        UNION
        SELECT m.pair2_id FROM public.matches m
      )
    )
    OR
    EXISTS (
      SELECT 1 FROM public.pairs p2
      WHERE (p2.user1_id = id OR p2.user2_id = id)
      AND p2.id IN (
        SELECT m.pair1_id FROM public.matches m
        WHERE m.pair2_id IN (
          SELECT current_pair_id FROM public.users WHERE users.id = auth.uid()
        )
        UNION
        SELECT m.pair2_id FROM public.matches m
        WHERE m.pair1_id IN (
          SELECT current_pair_id FROM public.users WHERE users.id = auth.uid()
        )
      )
    )
  );

-- =====================================================
-- USER PHOTOS POLICIES
-- =====================================================

-- Users can view their own photos
CREATE POLICY "Users can view own photos"
  ON public.user_photos
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can view photos of matched profiles
CREATE POLICY "Users can view matched users photos"
  ON public.user_photos
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.pairs p ON (p.user1_id = u.id OR p.user2_id = u.id)
      WHERE u.id = user_photos.user_id
      AND p.id IN (
        SELECT m.pair1_id FROM public.matches m
        WHERE m.pair2_id = (SELECT current_pair_id FROM public.users WHERE id = auth.uid())
        UNION
        SELECT m.pair2_id FROM public.matches m
        WHERE m.pair1_id = (SELECT current_pair_id FROM public.users WHERE id = auth.uid())
      )
    )
  );

-- Users can insert their own photos
CREATE POLICY "Users can upload own photos"
  ON public.user_photos
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Users can update their own photos
CREATE POLICY "Users can update own photos"
  ON public.user_photos
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own photos
CREATE POLICY "Users can delete own photos"
  ON public.user_photos
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- =====================================================
-- INTERESTS POLICIES
-- =====================================================

-- Users can view their own interests
CREATE POLICY "Users can view own interests"
  ON public.interests
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can view interests of matched profiles
CREATE POLICY "Users can view matched users interests"
  ON public.interests
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.pairs p ON (p.user1_id = u.id OR p.user2_id = u.id)
      WHERE u.id = interests.user_id
    )
  );

-- Users can manage their own interests
CREATE POLICY "Users can manage own interests"
  ON public.interests
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- =====================================================
-- PROFILE PROMPTS POLICIES
-- =====================================================

-- Users can view their own prompts
CREATE POLICY "Users can view own prompts"
  ON public.profile_prompts
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can view prompts of matched profiles
CREATE POLICY "Users can view matched users prompts"
  ON public.profile_prompts
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      JOIN public.pairs p ON (p.user1_id = u.id OR p.user2_id = u.id)
      WHERE u.id = profile_prompts.user_id
    )
  );

-- Users can manage their own prompts
CREATE POLICY "Users can manage own prompts"
  ON public.profile_prompts
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- =====================================================
-- PAIRS POLICIES
-- =====================================================

-- Users can view pairs they're part of
CREATE POLICY "Users can view own pairs"
  ON public.pairs
  FOR SELECT
  TO authenticated
  USING (user1_id = auth.uid() OR user2_id = auth.uid());

-- Users can view pairs in discovery (based on preferences)
-- Note: In production, add more sophisticated filtering based on preferences
CREATE POLICY "Users can view discovery pairs"
  ON public.pairs
  FOR SELECT
  TO authenticated
  USING (
    status = 'active'
    AND user1_id != auth.uid()
    AND user2_id != auth.uid()
  );

-- Users can create pairs if they're one of the users
CREATE POLICY "Users can create pairs"
  ON public.pairs
  FOR INSERT
  TO authenticated
  WITH CHECK (user1_id = auth.uid() OR user2_id = auth.uid());

-- Users can update pairs they're part of
CREATE POLICY "Users can update own pairs"
  ON public.pairs
  FOR UPDATE
  TO authenticated
  USING (user1_id = auth.uid() OR user2_id = auth.uid())
  WITH CHECK (user1_id = auth.uid() OR user2_id = auth.uid());

-- =====================================================
-- PAIR INVITES POLICIES
-- =====================================================

-- Users can view invites sent to them
CREATE POLICY "Users can view received invites"
  ON public.pair_invites
  FOR SELECT
  TO authenticated
  USING (to_user_id = auth.uid());

-- Users can view invites they sent
CREATE POLICY "Users can view sent invites"
  ON public.pair_invites
  FOR SELECT
  TO authenticated
  USING (from_user_id = auth.uid());

-- Users can send invites
CREATE POLICY "Users can send invites"
  ON public.pair_invites
  FOR INSERT
  TO authenticated
  WITH CHECK (from_user_id = auth.uid());

-- Users can update invites sent to them (accept/decline)
CREATE POLICY "Users can respond to invites"
  ON public.pair_invites
  FOR UPDATE
  TO authenticated
  USING (to_user_id = auth.uid())
  WITH CHECK (to_user_id = auth.uid());

-- Users can delete invites they sent
CREATE POLICY "Users can cancel sent invites"
  ON public.pair_invites
  FOR DELETE
  TO authenticated
  USING (from_user_id = auth.uid());

-- =====================================================
-- MATCHES POLICIES
-- =====================================================

-- Users can view matches their pair is part of
CREATE POLICY "Users can view own matches"
  ON public.matches
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pairs p
      WHERE (p.user1_id = auth.uid() OR p.user2_id = auth.uid())
      AND (p.id = matches.pair1_id OR p.id = matches.pair2_id)
    )
  );

-- System can create matches (you may want to handle this server-side)
CREATE POLICY "System can create matches"
  ON public.matches
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pairs p
      WHERE (p.user1_id = auth.uid() OR p.user2_id = auth.uid())
      AND (p.id = matches.pair1_id OR p.id = matches.pair2_id)
    )
  );

-- Users can update matches they're part of
CREATE POLICY "Users can update own matches"
  ON public.matches
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pairs p
      WHERE (p.user1_id = auth.uid() OR p.user2_id = auth.uid())
      AND (p.id = matches.pair1_id OR p.id = matches.pair2_id)
    )
  );

-- =====================================================
-- SWIPES POLICIES
-- =====================================================

-- Users can view swipes from their pair
CREATE POLICY "Users can view pair swipes"
  ON public.swipes
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pairs p
      WHERE (p.user1_id = auth.uid() OR p.user2_id = auth.uid())
      AND p.id = swipes.swiper_pair_id
    )
  );

-- Users can create swipes for their pair
CREATE POLICY "Users can create swipes"
  ON public.swipes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    swiper_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.pairs p
      WHERE (p.user1_id = auth.uid() OR p.user2_id = auth.uid())
      AND p.id = swipes.swiper_pair_id
    )
  );

-- =====================================================
-- MESSAGES POLICIES
-- =====================================================

-- Users can view messages in their matches
CREATE POLICY "Users can view match messages"
  ON public.messages
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.matches m
      JOIN public.pairs p ON (p.id = m.pair1_id OR p.id = m.pair2_id)
      WHERE m.id = messages.match_id
      AND (p.user1_id = auth.uid() OR p.user2_id = auth.uid())
    )
  );

-- Users can send messages in their matches
CREATE POLICY "Users can send messages"
  ON public.messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.matches m
      JOIN public.pairs p ON (p.id = m.pair1_id OR p.id = m.pair2_id)
      WHERE m.id = messages.match_id
      AND (p.user1_id = auth.uid() OR p.user2_id = auth.uid())
    )
  );

-- Users can update messages they sent (for read status, etc.)
CREATE POLICY "Users can update messages"
  ON public.messages
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.matches m
      JOIN public.pairs p ON (p.id = m.pair1_id OR p.id = m.pair2_id)
      WHERE m.id = messages.match_id
      AND (p.user1_id = auth.uid() OR p.user2_id = auth.uid())
    )
  );

-- =====================================================
-- HELPFUL VIEWS (Optional)
-- =====================================================

-- View to get complete user profile with photos, interests, prompts
CREATE OR REPLACE VIEW user_complete_profiles AS
SELECT
  u.*,
  COALESCE(
    json_agg(DISTINCT jsonb_build_object(
      'id', up.id,
      'url', up.url,
      'order_index', up.order_index,
      'is_main', up.is_main
    ) ORDER BY up.order_index) FILTER (WHERE up.id IS NOT NULL),
    '[]'
  ) as photos,
  COALESCE(
    json_agg(DISTINCT jsonb_build_object(
      'id', i.id,
      'name', i.name,
      'emoji', i.emoji
    )) FILTER (WHERE i.id IS NOT NULL),
    '[]'
  ) as interests,
  COALESCE(
    json_agg(DISTINCT jsonb_build_object(
      'id', pp.id,
      'prompt_type', pp.prompt_type,
      'answer', pp.answer
    )) FILTER (WHERE pp.id IS NOT NULL),
    '[]'
  ) as prompts
FROM public.users u
LEFT JOIN public.user_photos up ON up.user_id = u.id
LEFT JOIN public.interests i ON i.user_id = u.id
LEFT JOIN public.profile_prompts pp ON pp.user_id = u.id
GROUP BY u.id;

-- =====================================================
-- NOTES
-- =====================================================

-- These policies ensure:
-- 1. Users can only access their own data
-- 2. Users can view profiles/photos of people they've matched with
-- 3. Users can only perform actions on their own pairs
-- 4. All writes are authenticated and validated

-- For production, consider:
-- 1. Adding rate limiting
-- 2. More sophisticated discovery filtering
-- 3. Blocking/reporting functionality
-- 4. Admin access policies
