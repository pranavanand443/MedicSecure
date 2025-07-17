/*
  # Fix Password Verification for Doctors

  1. Changes
    - Update password verification function to properly handle hashed passwords
    - Add function to get doctor details securely
    - Improve error handling
    
  2. Security
    - Maintain secure password verification using pgcrypto
    - Return minimal required information
    - Add proper error handling
*/

-- Drop existing functions
DROP FUNCTION IF EXISTS verify_doctor_password(text, text);
DROP FUNCTION IF EXISTS is_doctor(text);

-- Create function to verify doctor credentials and return doctor info
CREATE OR REPLACE FUNCTION verify_doctor_credentials(
  p_email TEXT,
  p_password TEXT
)
RETURNS TABLE (
  id TEXT,
  full_name TEXT,
  is_valid BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_doctor doctors%ROWTYPE;
BEGIN
  -- Get the doctor record
  SELECT *
  INTO v_doctor
  FROM doctors
  WHERE contact_email = p_email
  AND is_active = true;
  
  -- Check if doctor exists and verify password
  IF v_doctor.id IS NULL THEN
    RETURN QUERY SELECT 
      NULL::TEXT AS id,
      NULL::TEXT AS full_name,
      FALSE AS is_valid;
    RETURN;
  END IF;
  
  -- Verify password using pgcrypto
  IF v_doctor.password = crypt(p_password, v_doctor.password) THEN
    RETURN QUERY SELECT 
      v_doctor.id,
      v_doctor.full_name,
      TRUE AS is_valid;
  ELSE
    RETURN QUERY SELECT 
      NULL::TEXT AS id,
      NULL::TEXT AS full_name,
      FALSE AS is_valid;
  END IF;
END;
$$;