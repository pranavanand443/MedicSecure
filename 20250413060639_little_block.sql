/*
  # Fix Record Ownership and Visibility

  1. Changes
    - Remove NOT NULL constraint from uploaded_by in records table
    - Add patient_id and doctor_id columns to records table
    - Remove RLS policies since RLS is disabled
    - Add indexes for performance

  2. Notes
    - Since RLS is disabled, we'll rely on application-level filtering
    - Added indexes to optimize queries by doctor_id and patient_id
*/

-- Remove NOT NULL constraint from uploaded_by
ALTER TABLE records ALTER COLUMN uploaded_by DROP NOT NULL;

-- Add patient_id and doctor_id columns
ALTER TABLE records 
  ADD COLUMN IF NOT EXISTS patient_id uuid REFERENCES auth.users,
  ADD COLUMN IF NOT EXISTS doctor_id text REFERENCES doctors;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_records_doctor_id ON records(doctor_id);
CREATE INDEX IF NOT EXISTS idx_records_patient_id ON records(patient_id);

-- Drop existing RLS policies since RLS is disabled
DROP POLICY IF EXISTS "Users can create their own records" ON records;
DROP POLICY IF EXISTS "Users can view their own records" ON records;
DROP POLICY IF EXISTS "Users can update their own records" ON records;
DROP POLICY IF EXISTS "Users can share their records" ON shared_records;
DROP POLICY IF EXISTS "Users can view records shared with them" ON shared_records;