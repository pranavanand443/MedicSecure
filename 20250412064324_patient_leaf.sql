/*
  # Enhanced Schema for Medical Records System

  1. New Tables
    - `doctors`
      - `id` (text, primary key) - Custom format DOCxxx
      - `full_name` (text)
      - `specialization` (text)
      - `years_experience` (integer)
      - `contact_email` (text)
      - `contact_phone` (text)
      - `created_at` (timestamptz)

    - `record_shares`
      - `id` (uuid, primary key)
      - `record_id` (uuid, references records)
      - `doctor_id` (text, references doctors)
      - `created_at` (timestamptz)
      - `user_id` (uuid, references auth.users)

  2. Modifications
    - Add additional fields to auth.users via custom profile table
    - Enhance records table with file metadata

  3. Security
    - Enable RLS on all new tables
    - Add appropriate access policies
*/

-- Create doctors table
CREATE TABLE IF NOT EXISTS doctors (
  id text PRIMARY KEY,
  full_name text NOT NULL,
  specialization text NOT NULL,
  years_experience integer NOT NULL,
  contact_email text NOT NULL,
  contact_phone text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create record_shares table
CREATE TABLE IF NOT EXISTS record_shares (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  record_id uuid REFERENCES records NOT NULL,
  doctor_id text REFERENCES doctors NOT NULL,
  created_at timestamptz DEFAULT now(),
  user_id uuid REFERENCES auth.users NOT NULL,
  UNIQUE(record_id, doctor_id)
);

-- Create profiles table for additional user information
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users,
  full_name text NOT NULL,
  date_of_birth date NOT NULL,
  contact_number text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add file metadata columns to records
ALTER TABLE records ADD COLUMN IF NOT EXISTS file_size bigint;
ALTER TABLE records ADD COLUMN IF NOT EXISTS file_type text;
ALTER TABLE records ADD COLUMN IF NOT EXISTS original_name text;

-- Enable RLS
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE record_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies for doctors
CREATE POLICY "Doctors are viewable by all authenticated users"
  ON doctors
  FOR SELECT
  TO authenticated
  USING (true);

-- Policies for record_shares
CREATE POLICY "Users can share their records with doctors"
  ON record_shares
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their record shares"
  ON record_shares
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their record shares"
  ON record_shares
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Policies for profiles
CREATE POLICY "Users can view their own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Insert sample doctors
INSERT INTO doctors (id, full_name, specialization, years_experience, contact_email, contact_phone)
VALUES 
  ('DOC001', 'Dr. James Miller', 'Cardiologist', 15, 'james.miller@example.com', '+1-555-0123'),
  ('DOC002', 'Dr. Emily Chen', 'General Physician', 8, 'emily.chen@example.com', '+1-555-0124'),
  ('DOC003', 'Dr. Michael Thompson', 'Neurologist', 12, 'michael.thompson@example.com', '+1-555-0125')
ON CONFLICT (id) DO NOTHING;