-- =====================================================
-- OneShot App - Storage Bucket Policies
-- For Supabase Storage
-- =====================================================

-- IMPORTANT: Before running this, create the storage bucket:
-- 1. Go to Supabase Dashboard → Storage
-- 2. Click "New bucket"
-- 3. Name: "user-photos"
-- 4. Set to PUBLIC (so photos can be accessed via URL)
-- 5. Then run these policies

-- =====================================================
-- STORAGE POLICIES FOR USER-PHOTOS BUCKET
-- =====================================================

-- Allow authenticated users to upload photos to their own folder
-- Folder structure: user-photos/{user_id}/{filename}
CREATE POLICY "Users can upload own photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to update/replace their own photos
CREATE POLICY "Users can update own photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'user-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own photos
CREATE POLICY "Users can delete own photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public read access to all photos (needed for discovery/viewing)
-- NOTE: This makes all photos publicly accessible. For more privacy,
-- you can restrict this to authenticated users only
CREATE POLICY "Public can view photos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'user-photos');

-- Alternative: Only authenticated users can view photos
-- Uncomment this and comment out the policy above if you want more privacy
/*
CREATE POLICY "Authenticated users can view photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'user-photos');
*/

-- =====================================================
-- HELPER FUNCTIONS FOR STORAGE
-- =====================================================

-- Function to clean up storage when user photos are deleted from database
CREATE OR REPLACE FUNCTION delete_storage_object(bucket text, object text)
RETURNS void AS $$
BEGIN
  PERFORM storage.delete_object(bucket, object);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to delete storage file when database record is deleted
CREATE OR REPLACE FUNCTION handle_photo_deletion()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.storage_path IS NOT NULL THEN
    PERFORM delete_storage_object('user-photos', OLD.storage_path);
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add trigger to user_photos table
DROP TRIGGER IF EXISTS on_photo_deleted ON public.user_photos;
CREATE TRIGGER on_photo_deleted
  BEFORE DELETE ON public.user_photos
  FOR EACH ROW
  EXECUTE FUNCTION handle_photo_deletion();

-- =====================================================
-- STORAGE CONFIGURATION NOTES
-- =====================================================

-- File Upload Limits:
-- - Max file size: 50MB (default Supabase limit)
-- - Recommended image formats: JPEG, PNG, WebP
-- - Recommended max dimensions: 2048x2048 (resize before upload)

-- File Naming Convention:
-- - Path: user-photos/{user_id}/{photo_id}.{extension}
-- - Example: user-photos/550e8400-e29b-41d4-a716-446655440000/abc123.jpg

-- Access URLs:
-- - Public URL format: {SUPABASE_URL}/storage/v1/object/public/user-photos/{path}
-- - Signed URL format (for private access): Use createSignedUrl() in client

-- Best Practices:
-- 1. Always compress images before upload (use iOS image compression)
-- 2. Generate thumbnails for list views (can use Supabase Image Transformation)
-- 3. Limit users to reasonable number of photos (e.g., 6 photos max)
-- 4. Validate file types and sizes on client AND server
-- 5. Use unique filenames to avoid collisions (UUID recommended)

-- Image Transformation (Supabase Pro feature):
-- You can transform images on-the-fly by adding query params:
-- - Resize: ?width=400&height=600
-- - Quality: ?quality=80
-- - Format: &format=webp
-- Example: {URL}/storage/v1/object/public/user-photos/{path}?width=400&quality=80
