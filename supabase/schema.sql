-- ScholarFlux Supabase Schema
-- Run this in the Supabase SQL editor after creating a project.

-- ============================================================
-- Tables
-- ============================================================

CREATE TABLE subjects (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  room TEXT,
  domains JSONB DEFAULT '[]',
  max_grade DOUBLE PRECISION DEFAULT 20,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE items (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  subject_id TEXT NOT NULL REFERENCES subjects(id),
  title TEXT NOT NULL,
  type TEXT NOT NULL,
  description TEXT DEFAULT '',
  due_date TIMESTAMPTZ,
  priority TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'pending',
  grade DOUBLE PRECISION,
  domain_id TEXT,
  origin TEXT,
  weight DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE classes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  subject_id TEXT NOT NULL REFERENCES subjects(id),
  day_of_week INT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  room TEXT,
  floor TEXT,
  teacher TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

-- Clerk JWTs use 'sub' claim for user ID
CREATE POLICY "users_own_subjects" ON subjects
  FOR ALL USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "users_own_items" ON items
  FOR ALL USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "users_own_classes" ON classes
  FOR ALL USING (auth.jwt() ->> 'sub' = user_id);

-- ============================================================
-- Indexes for sync queries
-- ============================================================

CREATE INDEX idx_subjects_user_updated ON subjects(user_id, updated_at);
CREATE INDEX idx_items_user_updated ON items(user_id, updated_at);
CREATE INDEX idx_classes_user_updated ON classes(user_id, updated_at);

-- ============================================================
-- Enable Realtime
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE subjects;
ALTER PUBLICATION supabase_realtime ADD TABLE items;
ALTER PUBLICATION supabase_realtime ADD TABLE classes;
