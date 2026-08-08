-- CodePath Academy — Phase 7: certificates + real-project marketplace
-- New tables only (no changes to existing tables), so this is safe to run
-- on a fresh database or an existing one — every "create table" already
-- uses "if not exists". Run this once in the Supabase SQL editor, after
-- schema.sql. These definitions are also mirrored into schema.sql itself
-- for brand-new installs.

-- ── certificates ────────────────────────────────────────────────────────────
-- One row per (student, course), issued automatically the moment every
-- lesson in that course is marked completed (see finalizeIfReady in
-- src/lib/lesson-server.ts). student_name is a snapshot taken at issuance
-- time — certificates are meant to be shared publicly via /certificate/[id],
-- so they intentionally don't depend on reading the (RLS-protected)
-- profiles table at view time.
create table if not exists certificates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  course_id uuid not null references courses (id) on delete cascade,
  student_name text not null,
  issued_at timestamptz not null default now(),
  unique (user_id, course_id)
);

-- ── real_projects ───────────────────────────────────────────────────────────
-- Admin-curated freelance-style opportunities offered to Pro students
-- ("real project marketplace" in the PRD). title/description are bilingual:
-- {"en": "...", "de": "..."}.
create table if not exists real_projects (
  id uuid primary key default gen_random_uuid(),
  title jsonb not null,
  description jsonb not null,
  skill_track text not null check (skill_track in ('frontend', 'backend', 'fullstack')),
  client_name text,
  status text not null default 'open' check (status in ('open', 'closed')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- ── project_interests ───────────────────────────────────────────────────────
-- A student expressing interest in a real project. No payment/contract flow
-- yet — an admin follows up manually, same as Pro access is granted
-- manually today until a real payment provider is wired up.
create table if not exists project_interests (
  id uuid primary key default gen_random_uuid(),
  real_project_id uuid not null references real_projects (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  message text,
  created_at timestamptz not null default now(),
  unique (real_project_id, user_id)
);

-- ── row level security ──────────────────────────────────────────────────────
alter table certificates enable row level security;
alter table real_projects enable row level security;
alter table project_interests enable row level security;

-- Certificates are meant to be shared with anyone holding the link (an
-- employer, for example), so they're publicly readable like lessons/courses
-- already are. Only the owning user can insert their own certificate row;
-- the actual decision of *whether* to insert one is made server-side in
-- finalizeIfReady, which recomputes completion from the database itself
-- rather than trusting client input — the same defense-in-depth pattern
-- used throughout this codebase.
create policy "certificates are publicly readable" on certificates for select using (true);
create policy "users issue own certificates" on certificates for insert with check (auth.uid() = user_id);

-- Real projects are publicly readable metadata (like lessons); the
-- student-facing /marketplace page itself decides whether to show them
-- based on Pro status, same pattern as the lesson paywall.
create policy "real projects are publicly readable" on real_projects for select using (true);
create policy "admins manage real projects" on real_projects for all using (public.is_admin(auth.uid()));

-- Interests are private: a student manages their own, and admins can see
-- everyone's so they can follow up.
create policy "users manage own interest" on project_interests for all using (auth.uid() = user_id);
create policy "admins read all interests" on project_interests for select using (public.is_admin(auth.uid()));
