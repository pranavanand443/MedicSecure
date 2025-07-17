/*
  # Fix Trigger Creation for Doctor Authentication

  1. Changes
    - Add safety checks for existing trigger
    - Recreate trigger only if it doesn't exist
    - Maintain existing functionality
*/

-- Drop trigger if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'hash_doctor_password_trigger'
  ) THEN
    DROP TRIGGER hash_doctor_password_trigger ON doctors_authentication;
  END IF;
END $$;

-- Create trigger for password hashing
CREATE TRIGGER hash_doctor_password_trigger
  BEFORE INSERT OR UPDATE ON doctors_authentication
  FOR EACH ROW
  EXECUTE FUNCTION hash_doctor_password();