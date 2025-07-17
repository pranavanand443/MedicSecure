/*
  # Simplified Doctor Authentication System

  1. Changes
    - Create doctors_authentication table without RLS
    - Remove foreign key constraints
    - Implement password hashing
    - Add email validation
    - Add last login tracking
    - Fix password verification in handle_doctor_sign_in function
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

  -- Check if doctor exists and verify password
  IF v_doctor_auth.id IS NULL THEN
    RETURN QUERY SELECT 
      false,
      'Invalid email or password'::text,
      NULL::json;
    RETURN;
  END IF;

  -- Use crypt to verify the password against the stored hash
  IF v_doctor_auth.password = crypt(p_password, v_doctor_auth.password) THEN
    -- Update last login
    UPDATE doctors_authentication
    SET last_login = now()
    WHERE id = v_doctor_auth.id;

    -- Return success with doctor data
    RETURN QUERY SELECT 
      true,
      'Successfully authenticated'::text,
      json_build_object(
        'id', v_doctor_auth.id,
        'email', v_doctor_auth.email,
        'last_login', v_doctor_auth.last_login
      );
  ELSE
    -- Return failure if password doesn't match
    RETURN QUERY SELECT 
      false,
      'Invalid email or password'::text,
      NULL::json;
  END IF;
END;
$$;

-- Create function to hash password before insert
CREATE OR REPLACE FUNCTION hash_doctor_password()
RETURNS trigger AS $$
BEGIN
  IF NEW.password IS NOT NULL THEN
    -- Only hash the password if it's not already hashed
    IF position('$2' in NEW.password) != 1 THEN
      NEW.password = crypt(NEW.password, gen_salt('bf'));
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for password hashing
CREATE TRIGGER hash_doctor_password_trigger
  BEFORE INSERT OR UPDATE ON doctors_authentication
  FOR EACH ROW
  EXECUTE FUNCTION hash_doctor_password();