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
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

-- ── tracks / courses ────────────────────────────────────────────────────────
-- foundation, frontend, backend
create table if not exists courses (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  description text,
  sort_order integer not null default 0
);

-- ── lessons ─────────────────────────────────────────────────────────────────
create table if not exists lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses (id) on delete cascade,
  slug text unique not null,
  title text not null,
  content jsonb not null default '[]',   -- step-by-step content blocks
  starter_code jsonb,                    -- { html, css, js } seed for the editor
  difficulty text not null default 'beginner' check (difficulty in ('beginner', 'intermediate', 'advanced')),
  is_free boolean not null default false,
  sort_order integer not null,           -- absolute order within the course; drives unlock logic
  created_at timestamptz not null default now()
);

-- ── quizzes ─────────────────────────────────────────────────────────────────
create table if not exists quiz_questions (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references lessons (id) on delete cascade,
  question text not null,
  choices jsonb not null,               -- ["A) ...", "B) ...", "C) ..."]
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
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);

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
  created_at timestamptz not null default now()
);

-- ── row level security ──────────────────────────────────────────────────────
alter table profiles enable row level security;
alter table lesson_progress enable row level security;
alter table projects enable row level security;
alter table subscriptions enable row level security;
alter table courses enable row level security;
alter table lessons enable row level security;
alter table quiz_questions enable row level security;

-- everyone (including anonymous visitors) can read course/lesson metadata
create policy "courses are publicly readable" on courses for select using (true);
create policy "lessons are publicly readable" on lessons for select using (true);
create policy "quiz questions are publicly readable" on quiz_questions for select using (true);

-- users can only see/edit their own rows
create policy "users read own profile" on profiles for select using (auth.uid() = id);
create policy "users update own profile" on profiles for update using (auth.uid() = id);
create policy "users insert own profile" on profiles for insert with check (auth.uid() = id);

create policy "users manage own progress" on lesson_progress for all using (auth.uid() = user_id);
create policy "users manage own projects" on projects for all using (auth.uid() = user_id);
create policy "users read own subscription" on subscriptions for select using (auth.uid() = user_id);

-- ── admin access ────────────────────────────────────────────────────────────
-- security definer so this can check profiles.is_admin without the calling
-- policy recursing into profiles' own RLS.
create or replace function public.is_admin(uid uuid)
returns boolean as $$
  select coalesce((select is_admin from public.profiles where id = uid), false);
$$ language sql security definer stable;

create policy "admins manage courses" on courses for all using (public.is_admin(auth.uid()));
create policy "admins manage lessons" on lessons for all using (public.is_admin(auth.uid()));
create policy "admins manage quiz questions" on quiz_questions for all using (public.is_admin(auth.uid()));
create policy "admins read all profiles" on profiles for select using (public.is_admin(auth.uid()));
create policy "admins update all profiles" on profiles for update using (public.is_admin(auth.uid()));
create policy "admins read all progress" on lesson_progress for select using (public.is_admin(auth.uid()));
create policy "admins read all subscriptions" on subscriptions for select using (public.is_admin(auth.uid()));

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
