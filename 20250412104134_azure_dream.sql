/*
  # Fix Doctor Authentication Flow

  1. Changes
    - Drop and recreate doctor verification function with better error handling
    - Add proper password comparison using pgcrypto
    - Return more detailed error messages
    
  2. Security
    - Maintain secure password verification
    - Proper error handling
    - Safe error messages
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS verify_doctor_credentials(text, text);

-- Create improved verification function
CREATE OR REPLACE FUNCTION verify_doctor_credentials(
  p_email TEXT,
  p_password TEXT
)
RETURNS TABLE (
  id TEXT,
  full_name TEXT,
  is_valid BOOLEAN,
  error_message TEXT
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
  WHERE contact_email = p_email;
  
  -- Check if doctor exists
  IF v_doctor.id IS NULL THEN
    RETURN QUERY SELECT 
      NULL::TEXT AS id,
      NULL::TEXT AS full_name,
      FALSE AS is_valid,
      'Doctor not found'::TEXT AS error_message;
    RETURN;
  END IF;

  -- Check if doctor is active
  IF NOT v_doctor.is_active THEN
    RETURN QUERY SELECT 
      NULL::TEXT AS id,
      NULL::TEXT AS full_name,
      FALSE AS is_valid,
      'Account is inactive'::TEXT AS error_message;
    RETURN;
  END IF;
  
  -- Verify password using pgcrypto
  IF v_doctor.password = crypt(p_password, v_doctor.password) THEN
    RETURN QUERY SELECT 
      v_doctor.id,
      v_doctor.full_name,
      TRUE AS is_valid,
      NULL::TEXT AS error_message;
  ELSE
    RETURN QUERY SELECT 
      NULL::TEXT AS id,
      NULL::TEXT AS full_name,
      FALSE AS is_valid,
      'Invalid password'::TEXT AS error_message;
  END IF;
END;
$$;