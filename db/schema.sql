-- CodePath Academy — core schema
-- Run this in the Supabase SQL editor (free project) to set up the database.

-- ── profiles ────────────────────────────────────────────────────────────────
-- One row per auth.users row. Holds app-specific fields Supabase auth doesn't.
create table if not exists profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  email text not null,
  account_type text not null default 'free' check (account_type in ('free', 'premium', 'student')),
  student_verified_until timestamptz,
  xp integer not null default 0,
  level integer not null default 1,
  current_streak integer not null default 0,
  longest_streak integer not null default 0,
  last_activity_date date,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

-- "create table if not exists" is a no-op on a database where profiles
-- already existed before these columns were added to this file (true for
-- any live install, since profiles has existed since day one) — it does
-- NOT retroactively add new columns to an existing table. These explicit
-- alters are the safety net that actually makes this file idempotent.
alter table profiles add column if not exists current_streak integer not null default 0;
alter table profiles add column if not exists longest_streak integer not null default 0;
alter table profiles add column if not exists last_activity_date date;
alter table profiles add column if not exists is_admin boolean not null default false;

-- ── tracks / courses ────────────────────────────────────────────────────────
-- foundation, frontend, backend
-- title/description are bilingual: {"en": "...", "de": "..."}
create table if not exists courses (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title jsonb not null,
  description jsonb,
  sort_order integer not null default 0
);

-- ── lessons ─────────────────────────────────────────────────────────────────
-- title is bilingual: {"en": "...", "de": "..."}.
-- content is [{ "step": 1, "text": { "en": "...", "de": "..." } }, ...] —
-- step numbering is language-agnostic, only the "text" is per-locale.
create table if not exists lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  slug text unique not null,
  title jsonb not null,
  content jsonb not null default '[]',
  starter_code jsonb,                    -- { html, css, js } seed for the editor (code isn't translated)
  difficulty text not null default 'beginner' check (difficulty in ('beginner', 'intermediate', 'advanced')),
  is_free boolean not null default false,
  has_assignment boolean not null default false, -- requires a project submission (saved to `projects`) to complete
  sort_order integer not null,           -- absolute order within the course; drives unlock logic
  created_at timestamptz not null default now()
);

alter table lessons add column if not exists has_assignment boolean not null default false;

-- ── quizzes ─────────────────────────────────────────────────────────────────
-- question is bilingual: {"en": "...", "de": "..."}.
-- choices is bilingual too: {"en": ["...", ...], "de": ["...", ...]} — the
-- arrays must stay the same length and order across locales since
-- correct_index refers to a position, not a specific language's array.
create table if not exists quiz_questions (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references lessons (id) on delete cascade,
  question jsonb not null,
  choices jsonb not null,
  correct_index integer not null,
  sort_order integer not null default 0,
  unique (lesson_id, question)
);

-- ── student progress ────────────────────────────────────────────────────────
-- One row per (student, lesson). Presence of a 'completed' row is what unlocks
-- the next lesson — never the subscription tier.
create table if not exists lesson_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  lesson_id uuid not null references lessons (id) on delete cascade,
  status text not null default 'in_progress' check (status in ('in_progress', 'completed')),
  practice_passed boolean not null default false,
  quiz_passed boolean not null default false,
  assignment_passed boolean not null default false,
  content_viewed boolean not null default false,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);
alter table lesson_progress add column if not exists content_viewed boolean not null default false;

-- ── projects / portfolio ────────────────────────────────────────────────────
create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  lesson_id uuid references lessons (id) on delete set null,
  title text not null,
  code jsonb,                            -- { html, css, js } or repo/preview link
  submitted_at timestamptz not null default now()
);

-- ── subscriptions ───────────────────────────────────────────────────────────
create table if not exists subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references profiles (id) on delete cascade,
  plan text not null default 'free' check (plan in ('free', 'premium', 'student')),
  status text not null default 'active' check (status in ('active', 'canceled', 'expired')),
  current_period_end timestamptz,
  stripe_customer_id text,
  stripe_subscription_id text,
  created_at timestamptz not null default now()
);

-- Same "create table if not exists is a no-op on an existing table" gap as
-- profiles above — subscriptions has existed since day one too, so these
-- explicit alters are what actually adds the columns on a live install.
alter table subscriptions add column if not exists stripe_customer_id text;
alter table subscriptions add column if not exists stripe_subscription_id text;

create unique index if not exists subscriptions_stripe_subscription_id_key
  on subscriptions (stripe_subscription_id)
  where stripe_subscription_id is not null;

-- ── certificates ────────────────────────────────────────────────────────────
-- One row per (student, course), issued automatically once every lesson in
-- that course is completed (see finalizeIfReady). student_name is a
-- snapshot taken at issuance time so a public /certificate/[id] page never
-- needs to read the (RLS-protected) profiles table.
create table if not exists certificates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  course_id uuid not null references courses (id) on delete cascade,
  student_name text not null,
  issued_at timestamptz not null default now(),
  unique (user_id, course_id)
);

-- ── real_projects / project_interests ───────────────────────────────────────
-- Admin-curated freelance-style opportunities offered to Pro students (the
-- PRD's "real project marketplace"). No payment/contract flow yet — an
-- admin follows up manually with anyone who expresses interest.
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

create table if not exists project_interests (
  id uuid primary key default gen_random_uuid(),
  real_project_id uuid not null references real_projects (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  message text,
  created_at timestamptz not null default now(),
  unique (real_project_id, user_id)
);

-- ── row level security ──────────────────────────────────────────────────────
alter table profiles enable row level security;
alter table lesson_progress enable row level security;
alter table projects enable row level security;
alter table subscriptions enable row level security;
alter table courses enable row level security;
alter table lessons enable row level security;
alter table quiz_questions enable row level security;
alter table certificates enable row level security;
alter table real_projects enable row level security;
alter table project_interests enable row level security;

-- Postgres has no "CREATE POLICY IF NOT EXISTS", so every policy below is
-- preceded by "DROP POLICY IF EXISTS" — that IS idempotent (no error if the
-- policy is missing), which makes the pair effectively "create or replace".
-- Necessary because profiles/courses/lessons/etc. have existed since day
-- one, so a live database already has every one of these from the original
-- run of this file — without the drop, re-running this file at all (not
-- just after adding new tables) errors with "policy ... already exists".

-- everyone (including anonymous visitors) can read course/lesson metadata
drop policy if exists "courses are publicly readable" on courses;
create policy "courses are publicly readable" on courses for select using (true);
drop policy if exists "lessons are publicly readable" on lessons;
create policy "lessons are publicly readable" on lessons for select using (true);
drop policy if exists "quiz questions are publicly readable" on quiz_questions;
create policy "quiz questions are publicly readable" on quiz_questions for select using (true);

-- users can only see/edit their own rows
drop policy if exists "users read own profile" on profiles;
create policy "users read own profile" on profiles for select using (auth.uid() = id);
drop policy if exists "users update own profile" on profiles;
create policy "users update own profile" on profiles for update using (auth.uid() = id);
drop policy if exists "users insert own profile" on profiles;
create policy "users insert own profile" on profiles for insert with check (auth.uid() = id);

drop policy if exists "users manage own progress" on lesson_progress;
create policy "users manage own progress" on lesson_progress for all using (auth.uid() = user_id);
drop policy if exists "users manage own projects" on projects;
create policy "users manage own projects" on projects for all using (auth.uid() = user_id);
drop policy if exists "users read own subscription" on subscriptions;
create policy "users read own subscription" on subscriptions for select using (auth.uid() = user_id);

-- certificates are shareable by design (an employer might click the link),
-- so read access is public like lessons/courses; only the owning user can
-- issue their own (finalizeIfReady decides *whether* to, server-side)
drop policy if exists "certificates are publicly readable" on certificates;
create policy "certificates are publicly readable" on certificates for select using (true);
drop policy if exists "users issue own certificates" on certificates;
create policy "users issue own certificates" on certificates for insert with check (auth.uid() = user_id);

-- real projects are public metadata; the /marketplace page itself decides
-- what to show based on Pro status, same pattern as the lesson paywall
drop policy if exists "real projects are publicly readable" on real_projects;
create policy "real projects are publicly readable" on real_projects for select using (true);

drop policy if exists "users manage own interest" on project_interests;
create policy "users manage own interest" on project_interests for all using (auth.uid() = user_id);

-- ── admin access ────────────────────────────────────────────────────────────
-- security definer so this can check profiles.is_admin without the calling
-- policy recursing into profiles' own RLS.
create or replace function public.is_admin(uid uuid)
returns boolean as $$
  select coalesce((select is_admin from public.profiles where id = uid), false);
$$ language sql security definer stable;

drop policy if exists "admins manage courses" on courses;
create policy "admins manage courses" on courses for all using (public.is_admin(auth.uid()));
drop policy if exists "admins manage lessons" on lessons;
create policy "admins manage lessons" on lessons for all using (public.is_admin(auth.uid()));
drop policy if exists "admins manage quiz questions" on quiz_questions;
create policy "admins manage quiz questions" on quiz_questions for all using (public.is_admin(auth.uid()));
drop policy if exists "admins read all profiles" on profiles;
create policy "admins read all profiles" on profiles for select using (public.is_admin(auth.uid()));
drop policy if exists "admins update all profiles" on profiles;
create policy "admins update all profiles" on profiles for update using (public.is_admin(auth.uid()));
drop policy if exists "admins read all progress" on lesson_progress;
create policy "admins read all progress" on lesson_progress for select using (public.is_admin(auth.uid()));
drop policy if exists "admins read all subscriptions" on subscriptions;
create policy "admins read all subscriptions" on subscriptions for select using (public.is_admin(auth.uid()));
drop policy if exists "admins manage real projects" on real_projects;
create policy "admins manage real projects" on real_projects for all using (public.is_admin(auth.uid()));
drop policy if exists "admins read all interests" on project_interests;
create policy "admins read all interests" on project_interests for select using (public.is_admin(auth.uid()));

-- ── leaderboard ─────────────────────────────────────────────────────────────
-- Exposes only id/name/xp/level — never email, account_type, or anything
-- else in profiles — so any signed-in student can call this without
-- loosening profiles' own SELECT policy.
create or replace function public.get_leaderboard(result_limit integer default 20)
returns table(id uuid, name text, xp integer, level integer)
as $$
  select id, name, xp, level
  from public.profiles
  order by xp desc, level desc
  limit result_limit;
$$ language sql security definer stable;

grant execute on function public.get_leaderboard(integer) to authenticated;

-- auto-create a profile row whenever a new auth user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', 'Student'), new.email);

  insert into public.subscriptions (user_id, plan)
  values (new.id, 'free');

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
