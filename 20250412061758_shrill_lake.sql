/*
  # Initial Schema Setup for Medical Records System

  1. New Tables
    - `records`
      - `id` (uuid, primary key)
      - `title` (text)
      - `type` (text)
      - `date` (timestamptz)
      - `uploaded_by` (text)
      - `file_path` (text, nullable)
      - `created_at` (timestamptz)
      - `user_id` (uuid, references auth.users)

    - `shared_records`
      - `id` (uuid, primary key)
      - `record_id` (uuid, references records)
      - `shared_with` (text)
      - `permission_level` (text)
      - `expires_at` (timestamptz)
      - `created_at` (timestamptz)
      - `user_id` (uuid, references auth.users)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create records table
CREATE TABLE IF NOT EXISTS records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  type text NOT NULL,
  date timestamptz DEFAULT now(),
  uploaded_by text NOT NULL,
  file_path text,
  created_at timestamptz DEFAULT now(),
  user_id uuid REFERENCES auth.users NOT NULL
);

-- Create shared_records table
CREATE TABLE IF NOT EXISTS shared_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  record_id uuid REFERENCES records NOT NULL,
  shared_with text NOT NULL,
  permission_level text NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  user_id uuid REFERENCES auth.users NOT NULL
);

-- Enable RLS
ALTER TABLE records ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_records ENABLE ROW LEVEL SECURITY;

-- Policies for records
CREATE POLICY "Users can create their own records"
  ON records
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own records"
  ON records
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own records"
  ON records
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policies for shared_records
CREATE POLICY "Users can share their records"
  ON shared_records
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM records WHERE id = record_id
    )
  );

CREATE POLICY "Users can view records shared with them"
  ON shared_records
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT user_id FROM records WHERE id = record_id
    ) OR
    auth.email() = shared_with
  );