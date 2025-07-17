/*
  # Update Doctor Authentication System

  1. Changes
    - Create new doctors_authentication table
    - Add secure password hashing
    - Add email validation
    - Add last login tracking
    
  2. Security
    - Implement secure password storage
    - Add email uniqueness constraint
    - Track authentication attempts
*/

-- Create new doctors_authentication table
CREATE TABLE IF NOT EXISTS doctors_authentication (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  password text NOT NULL,
  created_at timestamptz DEFAULT now(),
  last_login timestamptz,
  CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Enable RLS
ALTER TABLE doctors_authentication ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow doctors to view their own authentication data"
  ON doctors_authentication
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
  v_doctor_auth doctors_authentication%ROWTYPE;
BEGIN
  -- Get doctor auth record
  SELECT *
  INTO v_doctor_auth
  FROM doctors_authentication
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
  IF v_doctor_auth.password = crypt(p_password, v_doctor_auth.password) THEN
    -- Update last login
    UPDATE doctors_authentication
    SET last_login = now()
    WHERE id = v_doctor_auth.id;

    RETURN QUERY SELECT 
      true,
      'Successfully authenticated'::text,
      json_build_object(
        'id', v_doctor_auth.id,
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