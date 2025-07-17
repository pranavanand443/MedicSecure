/*
  # Doctor Authentication System

  1. New Tables
    - `doctor_auth`
      - `id` (uuid, primary key)
      - `doctor_id` (text, references doctors)
      - `email` (text, unique)
      - `hashed_password` (text)
      - `last_sign_in` (timestamptz)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS
    - Add policies for secure authentication
    - Add sample doctors with secure passwords
*/

-- Create doctor_auth table
CREATE TABLE IF NOT EXISTS doctor_auth (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id text REFERENCES doctors(id) NOT NULL,
  email text UNIQUE NOT NULL,
  hashed_password text NOT NULL,
  last_sign_in timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE doctor_auth ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow doctors to view their own auth data"
  ON doctor_auth
  FOR SELECT
  TO authenticated
  USING (email = auth.email());

-- Create function to handle doctor sign in
CREATE OR REPLACE FUNCTION handle_doctor_sign_in(
  p_email TEXT,
  p_password TEXT
)
RETURNS TABLE (
  success boolean,
  message text,
  doctor_data json
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_doctor_auth doctor_auth%ROWTYPE;
  v_doctor doctors%ROWTYPE;
BEGIN
  -- Get doctor auth record
  SELECT *
  INTO v_doctor_auth
  FROM doctor_auth
  WHERE email = p_email;

  -- Check if doctor exists
  IF v_doctor_auth.id IS NULL THEN
    RETURN QUERY SELECT 
      false,
      'Invalid email or password'::text,
      NULL::json;
    RETURN;
  END IF;

  -- Verify password
  IF v_doctor_auth.hashed_password = crypt(p_password, v_doctor_auth.hashed_password) THEN
    -- Get doctor details
    SELECT *
    INTO v_doctor
    FROM doctors
    WHERE id = v_doctor_auth.doctor_id;

    -- Update last sign in
    UPDATE doctor_auth
    SET last_sign_in = now(),
        updated_at = now()
    WHERE id = v_doctor_auth.id;

    RETURN QUERY SELECT 
      true,
      'Successfully authenticated'::text,
      json_build_object(
        'id', v_doctor.id,
        'full_name', v_doctor.full_name,
        'specialization', v_doctor.specialization,
        'email', v_doctor_auth.email
      );
  ELSE
    RETURN QUERY SELECT 
      false,
      'Invalid email or password'::text,
      NULL::json;
  END IF;
END;
$$;

-- Insert sample doctors with authentication
DO $$
DECLARE
  v_doctor_id text;
  v_temp_password text;
BEGIN
  -- Doctor 1
  v_temp_password := crypt('DoctorPass123!', gen_salt('bf'));
  INSERT INTO doctors (id, full_name, specialization, years_experience, contact_email, contact_phone, is_active, password)
  VALUES ('DOC001', 'Dr. James Wilson', 'Cardiologist', 15, 'james.wilson@example.com', '+1-555-0123', true, v_temp_password)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_doctor_id;

  IF v_doctor_id IS NOT NULL THEN
    INSERT INTO doctor_auth (doctor_id, email, hashed_password)
    VALUES (v_doctor_id, 'james.wilson@example.com', v_temp_password);
  END IF;

  -- Doctor 2
  v_temp_password := crypt('DoctorPass123!', gen_salt('bf'));
  INSERT INTO doctors (id, full_name, specialization, years_experience, contact_email, contact_phone, is_active, password)
  VALUES ('DOC002', 'Dr. Sarah Chen', 'Neurologist', 12, 'sarah.chen@example.com', '+1-555-0124', true, v_temp_password)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_doctor_id;

  IF v_doctor_id IS NOT NULL THEN
    INSERT INTO doctor_auth (doctor_id, email, hashed_password)
    VALUES (v_doctor_id, 'sarah.chen@example.com', v_temp_password);
  END IF;

  -- Doctor 3
  v_temp_password := crypt('DoctorPass123!', gen_salt('bf'));
  INSERT INTO doctors (id, full_name, specialization, years_experience, contact_email, contact_phone, is_active, password)
  VALUES ('DOC003', 'Dr. Michael Brown', 'Pediatrician', 10, 'michael.brown@example.com', '+1-555-0125', true, v_temp_password)
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO v_doctor_id;

  IF v_doctor_id IS NOT NULL THEN
    INSERT INTO doctor_auth (doctor_id, email, hashed_password)
    VALUES (v_doctor_id, 'michael.brown@example.com', v_temp_password);
  END IF;
END $$;