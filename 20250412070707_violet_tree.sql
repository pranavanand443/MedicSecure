/*
  # Disable RLS for profiles table
  
  1. Changes
    - Disable Row Level Security (RLS) for the profiles table
    
  Note: This will allow all operations on the profiles table without RLS restrictions.
  Make sure this aligns with your security requirements.
*/

ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;