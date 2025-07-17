/*
  # Update Doctor Authentication System

  1. Changes
    - Drop existing doctor_auth table if exists
    - Create new doctors_authentication table
    - Add RLS policies for secure access
    - Update sample data

  2. Security
    - Enable RLS
    - Add policies for secure access and insert operations
    - Use Supabase auth for authentication
*/

-- Drop existing doctor_auth table if it exists
DROP TABLE IF EXISTS doctor_auth;

-- Create doctors_authentication table
CREATE TABLE IF NOT EXISTS doctors_authentication (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id text REFERENCES doctors(id) NOT NULL,
  auth_id uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(doctor_id),
  UNIQUE(auth_id)
);

-- Enable RLS
ALTER TABLE doctors_authentication ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow doctors to view their own authentication data"
  ON doctors_authentication
  FOR SELECT
  TO authenticated
  USING (auth_id = auth.uid());

-- Add policy to allow inserting new doctor authentication records
CREATE POLICY "Allow inserting new doctor authentication records"
  ON doctors_authentication
  FOR INSERT
  TO authenticated
  WITH CHECK (auth_id = auth.uid());

-- Create function to handle doctor authentication
CREATE OR REPLACE FUNCTION check_doctor_auth()
RETURNS trigger AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM doctors_authentication
    WHERE auth_id = auth.uid()
  ) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'Access denied: User is not authorized as a doctor';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;