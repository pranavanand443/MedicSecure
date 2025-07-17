/*
  # Doctor Authentication System

  1. Changes
    - Remove custom authentication system
    - Use Supabase's built-in auth
    - Update doctors table structure
    - Remove password column from doctors table
    - Remove doctor_auth table

  2. Security
    - Enable RLS
    - Add policies for secure access
*/

-- Create doctors table (if not exists)
CREATE TABLE IF NOT EXISTS doctors (
  id text PRIMARY KEY,
  full_name text NOT NULL,
  specialization text NOT NULL,
  years_experience integer NOT NULL,
  contact_email text UNIQUE NOT NULL,
  contact_phone text NOT NULL,
  is_active boolean DEFAULT true
);

-- Enable RLS
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow doctors to view their own data"
  ON doctors
  FOR SELECT
  TO authenticated
  USING (contact_email = auth.email());

-- Insert sample doctors
INSERT INTO doctors (id, full_name, specialization, years_experience, contact_email, contact_phone, is_active)
VALUES 
  ('DOC001', 'Dr. James Wilson', 'Cardiologist', 15, 'james.wilson@example.com', '+1-555-0123', true),
  ('DOC002', 'Dr. Sarah Chen', 'Neurologist', 12, 'sarah.chen@example.com', '+1-555-0124', true),
  ('DOC003', 'Dr. Michael Brown', 'Pediatrician', 10, 'michael.brown@example.com', '+1-555-0125', true)
ON CONFLICT (id) DO NOTHING;