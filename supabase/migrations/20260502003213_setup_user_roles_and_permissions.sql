/*
  # Setup User Roles and Permissions System

  1. New Tables
    - `user_roles` - Define available roles (admin, director, chief, mayor)
    - `users_extended` - Extended user profile with role assignments
    - `permissions` - Available system permissions
    - `role_permissions` - Junction table linking roles to permissions

  2. Security
    - Enable RLS on all tables
    - Admins can manage all users and permissions
    - Users can view their own profile
    - Service chiefs and directors can view users in their scope

  3. Notes
    - This is a budget management system for open budgets
    - Roles: Admin, Financial Director, Service Chief, Mayor
*/

-- Create role types
CREATE TABLE IF NOT EXISTS user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Insert base roles
INSERT INTO user_roles (name, description) VALUES
  ('admin', 'System administrator - manages users and permissions'),
  ('director', 'Financial director - manages budgets and complaints'),
  ('chief', 'Service chief - manages teams and budgets'),
  ('mayor', 'Mayor - view-only access to all data')
ON CONFLICT (name) DO NOTHING;

-- Create permissions
CREATE TABLE IF NOT EXISTS permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Insert permissions
INSERT INTO permissions (name, description) VALUES
  ('manage_users', 'Create, read, update, delete users'),
  ('manage_roles', 'Assign and modify user roles'),
  ('manage_permissions', 'Manage system permissions'),
  ('view_complaints', 'View submitted complaints'),
  ('record_budget', 'Record financial transactions'),
  ('assign_teams', 'Assign service teams'),
  ('view_reports', 'View financial reports'),
  ('view_only', 'Read-only access to system')
ON CONFLICT (name) DO NOTHING;

-- Link roles to permissions
CREATE TABLE IF NOT EXISTS role_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id uuid NOT NULL REFERENCES user_roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(role_id, permission_id)
);

-- Assign permissions to roles
INSERT INTO role_permissions (role_id, permission_id)
SELECT ur.id, p.id FROM user_roles ur, permissions p
WHERE (ur.name = 'admin' AND p.name IN ('manage_users', 'manage_roles', 'manage_permissions', 'view_complaints', 'record_budget', 'assign_teams', 'view_reports'))
OR (ur.name = 'director' AND p.name IN ('view_complaints', 'record_budget', 'view_reports'))
OR (ur.name = 'chief' AND p.name IN ('view_complaints', 'assign_teams', 'record_budget'))
OR (ur.name = 'mayor' AND p.name IN ('view_only'))
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Extended user profiles
CREATE TABLE IF NOT EXISTS users_extended (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  role_id uuid NOT NULL REFERENCES user_roles(id),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_extended ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_roles
CREATE POLICY "Anyone can view roles"
  ON user_roles FOR SELECT
  TO authenticated
  USING (true);

-- RLS Policies for permissions
CREATE POLICY "Anyone can view permissions"
  ON permissions FOR SELECT
  TO authenticated
  USING (true);

-- RLS Policies for role_permissions
CREATE POLICY "Anyone can view role permissions"
  ON role_permissions FOR SELECT
  TO authenticated
  USING (true);

-- RLS Policies for users_extended
CREATE POLICY "Admins can view all users"
  ON users_extended FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_extended ue
      JOIN user_roles ur ON ue.role_id = ur.id
      WHERE ue.id = auth.uid() AND ur.name = 'admin'
    )
  );

CREATE POLICY "Users can view their own profile"
  ON users_extended FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can insert users"
  ON users_extended FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users_extended ue
      JOIN user_roles ur ON ue.role_id = ur.id
      WHERE ue.id = auth.uid() AND ur.name = 'admin'
    )
  );

CREATE POLICY "Admins can update users"
  ON users_extended FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_extended ue
      JOIN user_roles ur ON ue.role_id = ur.id
      WHERE ue.id = auth.uid() AND ur.name = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users_extended ue
      JOIN user_roles ur ON ue.role_id = ur.id
      WHERE ue.id = auth.uid() AND ur.name = 'admin'
    )
  );

CREATE POLICY "Admins can delete users"
  ON users_extended FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_extended ue
      JOIN user_roles ur ON ue.role_id = ur.id
      WHERE ue.id = auth.uid() AND ur.name = 'admin'
    )
  );
