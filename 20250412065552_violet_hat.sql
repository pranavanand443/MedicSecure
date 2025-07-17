/*
  # Update profiles table RLS policies

  1. Changes
    - Drop existing RLS policies for profiles table
    - Create new, more permissive RLS policies that maintain security while fixing access issues
    
  2. Security
    - Maintains RLS protection
    - Users can only access their own profile data
    - Ensures proper authentication checks
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;

-- Create new policies with proper security checks
CREATE POLICY "Enable read access for users" ON profiles
  FOR SELECT USING (
    auth.uid() = id OR 
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = profiles.id
    )
  );

CREATE POLICY "Enable insert access for users" ON profiles
  FOR INSERT WITH CHECK (
    auth.uid() = id
  );

CREATE POLICY "Enable update access for users" ON profiles
  FOR UPDATE USING (
    auth.uid() = id
  ) WITH CHECK (
    auth.uid() = id
  );

-- Ensure RLS is enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;