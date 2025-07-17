/*
  # Fix profiles table RLS policies

  1. Changes
    - Add INSERT policy for profiles table to allow users to create their own profile
    - Update SELECT policy to allow users to view their own profile
    - Update UPDATE policy to allow users to update their own profile

  2. Security
    - Maintain RLS enabled on profiles table
    - Ensure users can only access their own profile data
    - Allow new users to create their initial profile
*/

-- Allow users to insert their own profile during signup
CREATE POLICY "Users can create their own profile"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Update existing policies to be more explicit
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

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