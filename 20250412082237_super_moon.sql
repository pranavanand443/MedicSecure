/*
  # Storage Configuration for Medical Records System

  1. Changes
    - Add storage_path column to records table
    - Create storage access policies for authenticated users
    - Configure secure file access controls

  2. Security
    - Policies ensure users can only access their own files
    - Doctors can access shared files
    - Prevent unauthorized access to medical records
*/

-- Add storage path column to records table
ALTER TABLE records
ADD COLUMN IF NOT EXISTS storage_path text;

-- Create storage access policies
DO $$ 
BEGIN
  -- Policy for file uploads
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Users can upload files'
    AND tablename = 'objects'
    AND schemaname = 'storage'
  ) THEN
    CREATE POLICY "Users can upload files"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'medical-records' AND
      auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;

  -- Policy for viewing files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Users can view their own files'
    AND tablename = 'objects'
    AND schemaname = 'storage'
  ) THEN
    CREATE POLICY "Users can view their own files"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
      bucket_id = 'medical-records' AND
      (
        -- User owns the file
        auth.uid()::text = (storage.foldername(name))[1]
        OR
        -- File is shared with the user as a doctor
        EXISTS (
          SELECT 1 
          FROM records r
          JOIN record_shares rs ON r.id = rs.record_id
          WHERE r.storage_path = name
          AND rs.doctor_id = auth.uid()::text
        )
      )
    );
  END IF;

  -- Policy for updating files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Users can update their own files'
    AND tablename = 'objects'
    AND schemaname = 'storage'
  ) THEN
    CREATE POLICY "Users can update their own files"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
      bucket_id = 'medical-records' AND
      auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;

  -- Policy for deleting files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Users can delete their own files'
    AND tablename = 'objects'
    AND schemaname = 'storage'
  ) THEN
    CREATE POLICY "Users can delete their own files"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
      bucket_id = 'medical-records' AND
      auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;

  -- Enable RLS on storage.objects if not already enabled
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'objects' 
    AND schemaname = 'storage' 
    AND rowsecurity = true
  ) THEN
    ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;