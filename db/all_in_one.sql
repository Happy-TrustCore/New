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
-- CodePath Academy — initial course content
-- Run this after db/schema.sql. This is the real (if early) curriculum, fully
-- bilingual (English + German): Foundation (2 lessons), the first 16 free
-- Frontend lessons, and the first 8 free Backend lessons — enough to take a
-- student from zero through a complete HTML/CSS site and a working mental
-- model of how servers work. More lessons can be added later through the
-- admin panel at /admin. This file is generated — see the project's dev
-- history for the generator script if you need to regenerate it.

insert into courses (slug, title, description, sort_order) values
  ('foundation', '{"en":"Foundation","de":"Foundation"}'::jsonb, '{"en":"Understand how code and the web work.","de":"Verstehe, wie Code und das Web funktionieren."}'::jsonb, 1),
  ('frontend', '{"en":"Frontend Development","de":"Frontend-Entwicklung"}'::jsonb, '{"en":"HTML, CSS, JavaScript and React — one growing project.","de":"HTML, CSS, JavaScript und React — ein wachsendes Projekt."}'::jsonb, 2),
  ('backend', '{"en":"Backend Development","de":"Backend-Entwicklung"}'::jsonb, '{"en":"Servers, Node.js, databases and authentication.","de":"Server, Node.js, Datenbanken und Authentifizierung."}'::jsonb, 3)
on conflict (slug) do nothing;

-- ── Foundation ────────────────────────────────────────────────────

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
values
  (
    (select id from courses where slug = 'foundation'),
    'how-programming-works',
    '{"en":"How Programming Works","de":"Wie Programmieren funktioniert"}'::jsonb,
    '[{"step":1,"text":{"en":"A computer only follows exact instructions. Programming is the act of writing those instructions in a language it understands.","de":"Ein Computer folgt nur exakten Anweisungen. Programmieren bedeutet, diese Anweisungen in einer Sprache zu schreiben, die er versteht."}},{"step":2,"text":{"en":"Every app you use — a website, a game, a banking app — is just instructions, run one after another.","de":"Jede App, die du nutzt — eine Website, ein Spiel, eine Banking-App — besteht nur aus Anweisungen, die nacheinander ausgeführt werden."}},{"step":3,"text":{"en":"In this course you will write real instructions yourself, starting with the language browsers understand: HTML.","de":"In diesem Kurs schreibst du selbst echte Anweisungen — angefangen mit der Sprache, die Browser verstehen: HTML."}}]'::jsonb,
    null,
    'beginner', true, false, 1
  ),
  (
    (select id from courses where slug = 'foundation'),
    'how-websites-work',
    '{"en":"How Websites Work","de":"Wie Websites funktionieren"}'::jsonb,
    '[{"step":1,"text":{"en":"When you open a website, your browser sends a request out to a server somewhere else in the world.","de":"Wenn du eine Website öffnest, sendet dein Browser eine Anfrage an einen Server irgendwo auf der Welt."}},{"step":2,"text":{"en":"The server sends back files — HTML, CSS, JavaScript — and your browser turns them into the page you see.","de":"Der Server sendet Dateien zurück — HTML, CSS, JavaScript — und dein Browser macht daraus die Seite, die du siehst."}},{"step":3,"text":{"en":"Frontend is everything the browser shows you. Backend is everything happening on that server. You will build both.","de":"Frontend ist alles, was dir der Browser zeigt. Backend ist alles, was auf diesem Server passiert. Du wirst beides bauen."}}]'::jsonb,
    null,
    'beginner', true, false, 2
  )
on conflict (slug) do nothing;

-- ── Frontend: 16 free lessons ────────────────────────────────────────────────────

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
values
  (
    (select id from courses where slug = 'frontend'),
    'html-hello-world',
    '{"en":"HTML: Your First Website","de":"HTML: Deine erste Website"}'::jsonb,
    '[{"step":1,"text":{"en":"HTML creates the structure and content of a website. There is no design yet — just content.","de":"HTML erstellt die Struktur und den Inhalt einer Website. Design gibt es noch nicht — nur Inhalt."}},{"step":2,"text":{"en":"<h1> creates a big heading. <p> creates a paragraph of text.","de":"<h1> erzeugt eine große Überschrift. <p> erzeugt einen Textabsatz."}},{"step":3,"text":{"en":"Try changing the name in the heading below, then press Run to see your website update.","de":"Ändere den Namen in der Überschrift unten und klicke auf Ausführen, um deine Website zu aktualisieren."}}]'::jsonb,
    '{"html":"<h1>Hello, my name is Ahmed</h1>\n<h2>I am learning coding</h2>\n<p>This is my first website.</p>"}'::jsonb,
    'beginner', true, false, 1
  ),
  (
    (select id from courses where slug = 'frontend'),
    'css-styling-basics',
    '{"en":"CSS: Styling Your Website","de":"CSS: Deine Website gestalten"}'::jsonb,
    '[{"step":1,"text":{"en":"CSS starts here — but your HTML does not restart. You are improving the same website from the last lesson.","de":"CSS beginnt hier — aber dein HTML startet nicht neu. Du verbesserst dieselbe Website aus der letzten Lektion."}},{"step":2,"text":{"en":"HTML creates the elements. CSS changes how they look: color, size, spacing.","de":"HTML erstellt die Elemente. CSS verändert, wie sie aussehen: Farbe, Größe, Abstand."}},{"step":3,"text":{"en":"Try changing the color or font-size values below, then press Run.","de":"Ändere die Werte für color oder font-size unten und klicke auf Ausführen."}}]'::jsonb,
    '{"html":"<h1>Hello, my name is Ahmed</h1>\n<p>This is my first website.</p>","css":"h1 {\n  color: #34d399;\n}\n\np {\n  font-size: 20px;\n}"}'::jsonb,
    'beginner', true, false, 2
  ),
  (
    (select id from courses where slug = 'frontend'),
    'html-css-div-profile-card',
    '{"en":"Building a Profile Card","de":"Eine Profilkarte bauen"}'::jsonb,
    '[{"step":1,"text":{"en":"New HTML: <div> groups content together, and <img> shows a picture. Think of a <div> as a box you can style.","de":"Neu in HTML: <div> gruppiert Inhalte, und <img> zeigt ein Bild. Stell dir ein <div> als Box vor, die du gestalten kannst."}},{"step":2,"text":{"en":"New CSS: background-color fills a box with color. border adds an outline. padding adds space inside the box.","de":"Neu in CSS: background-color füllt eine Box mit Farbe. border fügt einen Rahmen hinzu. padding fügt Abstand innerhalb der Box hinzu."}},{"step":3,"text":{"en":"Turn your name and role into a profile card: a box with a background, some padding, and rounded corners.","de":"Verwandle deinen Namen und deine Rolle in eine Profilkarte: eine Box mit Hintergrund, etwas Innenabstand und abgerundeten Ecken."}}]'::jsonb,
    '{"html":"<div class=\"card\">\n  <img src=\"https://placehold.co/80\" alt=\"Profile photo\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>","css":".card {\n  background-color: #111827;\n  color: white;\n  border: 1px solid #333;\n  border-radius: 12px;\n  padding: 20px;\n  width: 220px;\n  text-align: center;\n}"}'::jsonb,
    'beginner', true, false, 3
  ),
  (
    (select id from courses where slug = 'frontend'),
    'website-structure-nav-footer',
    '{"en":"Real Website Structure: Header, Nav, Footer","de":"Echte Website-Struktur: Header, Nav, Footer"}'::jsonb,
    '[{"step":1,"text":{"en":"New HTML: <nav> holds your navigation links. <footer> holds content at the bottom of the page, like copyright text.","de":"Neu in HTML: <nav> enthält deine Navigationslinks. <footer> enthält Inhalte am unteren Seitenrand, wie Copyright-Text."}},{"step":2,"text":{"en":"New CSS: display: flex arranges elements in a row instead of stacking them.","de":"Neu in CSS: display: flex ordnet Elemente in einer Reihe an, statt sie zu stapeln."}},{"step":3,"text":{"en":"Add a navigation bar with links, and a footer, to the profile card page you started.","de":"Füge der Profilkarten-Seite, die du begonnen hast, eine Navigationsleiste mit Links und einen Footer hinzu."}}]'::jsonb,
    '{"html":"<header>\n  <nav>\n    <a href=\"#\">Home</a>\n    <a href=\"#\">About</a>\n    <a href=\"#\">Contact</a>\n  </nav>\n</header>\n\n<div class=\"card\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>\n\n<footer>\n  <p>&copy; 2026 Ahmed</p>\n</footer>","css":"nav {\n  display: flex;\n  gap: 16px;\n}\n\nnav a {\n  color: #34d399;\n  text-decoration: none;\n}\n\nfooter {\n  margin-top: 40px;\n  color: #888;\n  font-size: 14px;\n}"}'::jsonb,
    'beginner', true, false, 4
  ),
  (
    (select id from courses where slug = 'frontend'),
    'flexbox-layout-basics',
    '{"en":"Flexbox: Arranging Elements","de":"Flexbox: Elemente anordnen"}'::jsonb,
    '[{"step":1,"text":{"en":"Flexbox controls how elements line up. justify-content controls horizontal spacing. align-items controls vertical alignment.","de":"Flexbox steuert, wie Elemente ausgerichtet werden. justify-content steuert den horizontalen Abstand. align-items steuert die vertikale Ausrichtung."}},{"step":2,"text":{"en":"gap adds space between flex items without needing margin on each one.","de":"gap fügt Abstand zwischen Flex-Elementen hinzu, ohne dass du für jedes einzeln margin brauchst."}},{"step":3,"text":{"en":"Arrange your nav links with space between them, and center your profile card on the page.","de":"Ordne deine Nav-Links mit Abstand zueinander an und zentriere deine Profilkarte auf der Seite."}}]'::jsonb,
    '{"html":"<nav>\n  <a href=\"#\">Home</a>\n  <a href=\"#\">About</a>\n  <a href=\"#\">Contact</a>\n</nav>\n\n<div class=\"card\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>","css":"nav {\n  display: flex;\n  justify-content: space-between;\n  gap: 16px;\n}\n\nbody {\n  display: flex;\n  flex-direction: column;\n  align-items: center;\n}"}'::jsonb,
    'beginner', true, false, 5
  ),
  (
    (select id from courses where slug = 'frontend'),
    'semantic-html-sections',
    '{"en":"Semantic HTML: main, section, article","de":"Semantisches HTML: main, section, article"}'::jsonb,
    '[{"step":1,"text":{"en":"<main> marks the primary content of the page. <section> groups a themed chunk of content. <article> is a self-contained piece of content.","de":"<main> markiert den Hauptinhalt der Seite. <section> gruppiert einen thematischen Inhaltsabschnitt. <article> ist ein eigenständiger Inhaltsblock."}},{"step":2,"text":{"en":"Using the right tag (instead of always <div>) helps browsers, search engines, and screen readers understand your page.","de":"Das richtige Tag zu verwenden (statt immer <div>) hilft Browsern, Suchmaschinen und Screenreadern, deine Seite zu verstehen."}},{"step":3,"text":{"en":"Wrap your profile card in a <main>, and add a new <section> introducing your skills.","de":"Umschließe deine Profilkarte mit einem <main> und füge eine neue <section> hinzu, die deine Fähigkeiten vorstellt."}}]'::jsonb,
    '{"html":"<main>\n  <div class=\"card\">\n    <h2>Ahmed</h2>\n    <p>Developer</p>\n  </div>\n\n  <section>\n    <h3>Skills</h3>\n    <p>HTML, CSS, JavaScript</p>\n  </section>\n</main>","css":"section {\n  margin-top: 24px;\n  text-align: center;\n}"}'::jsonb,
    'beginner', true, false, 6
  ),
  (
    (select id from courses where slug = 'frontend'),
    'typography-basics',
    '{"en":"Typography: Fonts That Feel Professional","de":"Typografie: Schriften, die professionell wirken"}'::jsonb,
    '[{"step":1,"text":{"en":"font-family sets the typeface. font-weight controls boldness. line-height controls space between lines of text.","de":"font-family legt die Schriftart fest. font-weight steuert die Fettung. line-height steuert den Zeilenabstand."}},{"step":2,"text":{"en":"Good typography is one of the fastest ways to make a website look professional.","de":"Gute Typografie ist einer der schnellsten Wege, eine Website professionell wirken zu lassen."}},{"step":3,"text":{"en":"Update your page fonts: a bold heading, and a comfortable line-height for paragraphs.","de":"Aktualisiere die Schriften deiner Seite: eine fette Überschrift und einen angenehmen Zeilenabstand für Absätze."}}]'::jsonb,
    '{"html":"<h2>Ahmed</h2>\n<p>I build websites that work well and look great. Learning to code, one project at a time.</p>","css":"h2 {\n  font-family: Georgia, serif;\n  font-weight: 700;\n}\n\np {\n  font-family: Arial, sans-serif;\n  line-height: 1.6;\n}"}'::jsonb,
    'beginner', true, false, 7
  ),
  (
    (select id from courses where slug = 'frontend'),
    'box-model-deep-dive',
    '{"en":"The Box Model: Margin vs Padding","de":"Das Box-Modell: Margin vs. Padding"}'::jsonb,
    '[{"step":1,"text":{"en":"Every HTML element is a box. padding is space INSIDE the border. margin is space OUTSIDE the border, between elements.","de":"Jedes HTML-Element ist eine Box. padding ist der Abstand INNERHALB des Rahmens. margin ist der Abstand AUSSERHALB des Rahmens, zwischen Elementen."}},{"step":2,"text":{"en":"box-sizing: border-box makes width and height include padding and border, which avoids surprises.","de":"box-sizing: border-box sorgt dafür, dass width und height padding und border mit einschließen — das verhindert Überraschungen."}},{"step":3,"text":{"en":"Adjust the spacing on this card using margin and padding correctly.","de":"Passe den Abstand dieser Karte mit margin und padding richtig an."}}]'::jsonb,
    '{"html":"<div class=\"card\">\n  <h2>Ahmed</h2>\n  <p>Developer</p>\n</div>","css":"* {\n  box-sizing: border-box;\n}\n\n.card {\n  margin: 20px;\n  padding: 20px;\n  border: 1px solid #333;\n  width: 240px;\n}"}'::jsonb,
    'beginner', true, false, 8
  ),
  (
    (select id from courses where slug = 'frontend'),
    'hero-section',
    '{"en":"Building a Hero Section","de":"Eine Hero-Section bauen"}'::jsonb,
    '[{"step":1,"text":{"en":"A hero section is the big, eye-catching area at the top of a landing page: a large heading, short text, and a button.","de":"Eine Hero-Section ist der große, auffällige Bereich oben auf einer Landingpage: eine große Überschrift, kurzer Text und ein Button."}},{"step":2,"text":{"en":"A large font-size on the heading and a call-to-action button draw the visitor''s attention immediately.","de":"Eine große font-size bei der Überschrift und ein Call-to-Action-Button ziehen die Aufmerksamkeit der Besucher sofort auf sich."}},{"step":3,"text":{"en":"Build a hero section for your own site: your name, a one-line pitch, and a button.","de":"Baue eine Hero-Section für deine eigene Seite: deinen Namen, einen kurzen Pitch und einen Button."}}]'::jsonb,
    '{"html":"<section class=\"hero\">\n  <h1>Hi, I''m Ahmed</h1>\n  <p>I build websites that work.</p>\n  <button>Contact Me</button>\n</section>","css":".hero {\n  text-align: center;\n  padding: 60px 20px;\n}\n\n.hero h1 {\n  font-size: 48px;\n}\n\n.hero button {\n  margin-top: 16px;\n  padding: 12px 24px;\n  background: #34d399;\n  border: none;\n  border-radius: 8px;\n  font-weight: 600;\n  cursor: pointer;\n}"}'::jsonb,
    'beginner', true, false, 9
  ),
  (
    (select id from courses where slug = 'frontend'),
    'landing-page-assembly',
    '{"en":"Assembling a Landing Page","de":"Eine Landingpage zusammensetzen"}'::jsonb,
    '[{"step":1,"text":{"en":"A landing page combines everything so far: header + nav, a hero section, a features/about section, and a footer.","de":"Eine Landingpage kombiniert alles bisher Gelernte: Header + Nav, eine Hero-Section, eine Features-/Über-mich-Section und einen Footer."}},{"step":2,"text":{"en":"This is where your project stops being ''a page with stuff on it'' and starts being a real website.","de":"Ab hier hört dein Projekt auf, „eine Seite mit irgendwas drauf“ zu sein, und wird zu einer echten Website."}},{"step":3,"text":{"en":"Combine your hero, an about section, and a footer into one flowing page.","de":"Kombiniere deine Hero-Section, eine Über-mich-Section und einen Footer zu einer durchgängigen Seite."}}]'::jsonb,
    '{"html":"<header>\n  <nav><a href=\"#\">Home</a> <a href=\"#\">About</a></nav>\n</header>\n\n<section class=\"hero\">\n  <h1>Hi, I''m Ahmed</h1>\n  <p>I build websites that work.</p>\n</section>\n\n<section>\n  <h2>About Me</h2>\n  <p>I''m learning to code with CodePath Academy.</p>\n</section>\n\n<footer>\n  <p>&copy; 2026 Ahmed</p>\n</footer>","css":".hero {\n  text-align: center;\n  padding: 60px 20px;\n}"}'::jsonb,
    'beginner', true, false, 10
  ),
  (
    (select id from courses where slug = 'frontend'),
    'responsive-images',
    '{"en":"Responsive Images","de":"Responsive Bilder"}'::jsonb,
    '[{"step":1,"text":{"en":"max-width: 100% stops an image from overflowing its container on small screens.","de":"max-width: 100% verhindert, dass ein Bild auf kleinen Bildschirmen über seinen Container hinausragt."}},{"step":2,"text":{"en":"object-fit: cover crops an image neatly to fill a fixed-size box without stretching it.","de":"object-fit: cover schneidet ein Bild sauber zu, damit es eine Box mit fester Größe füllt, ohne es zu verzerren."}},{"step":3,"text":{"en":"Make the image in your card responsive.","de":"Mache das Bild in deiner Karte responsive."}}]'::jsonb,
    '{"html":"<div class=\"card\">\n  <img src=\"https://placehold.co/400x200\" alt=\"Cover\">\n</div>","css":".card img {\n  max-width: 100%;\n  height: 160px;\n  object-fit: cover;\n  border-radius: 8px;\n}"}'::jsonb,
    'beginner', true, false, 11
  ),
  (
    (select id from courses where slug = 'frontend'),
    'css-grid-basics',
    '{"en":"CSS Grid: Multi-Column Layouts","de":"CSS Grid: Mehrspaltige Layouts"}'::jsonb,
    '[{"step":1,"text":{"en":"display: grid turns an element into a grid container. grid-template-columns defines how many columns and their widths.","de":"display: grid macht aus einem Element einen Grid-Container. grid-template-columns legt fest, wie viele Spalten es gibt und wie breit sie sind."}},{"step":2,"text":{"en":"Grid is perfect for laying out cards side by side — like a row of features or products.","de":"Grid eignet sich perfekt, um Karten nebeneinander anzuordnen — etwa eine Reihe von Features oder Produkten."}},{"step":3,"text":{"en":"Lay out three feature cards side by side using CSS Grid.","de":"Ordne drei Feature-Karten mit CSS Grid nebeneinander an."}}]'::jsonb,
    '{"html":"<div class=\"features\">\n  <div class=\"feature\">Fast</div>\n  <div class=\"feature\">Simple</div>\n  <div class=\"feature\">Free</div>\n</div>","css":".features {\n  display: grid;\n  grid-template-columns: repeat(3, 1fr);\n  gap: 20px;\n}\n\n.feature {\n  background: #111827;\n  color: white;\n  padding: 20px;\n  text-align: center;\n  border-radius: 8px;\n}"}'::jsonb,
    'beginner', true, false, 12
  ),
  (
    (select id from courses where slug = 'frontend'),
    'html-forms-basics',
    '{"en":"Forms: Collecting Input","de":"Formulare: Eingaben sammeln"}'::jsonb,
    '[{"step":1,"text":{"en":"<input> collects text from a visitor. <label> describes what an input is for — important for accessibility.","de":"<input> sammelt Text von einem Besucher. <label> beschreibt, wofür ein Eingabefeld da ist — wichtig für Barrierefreiheit."}},{"step":2,"text":{"en":"<button> submits the form.","de":"<button> sendet das Formular ab."}},{"step":3,"text":{"en":"Build a simple contact form with a name field, an email field, and a submit button.","de":"Baue ein einfaches Kontaktformular mit einem Namensfeld, einem E-Mail-Feld und einem Absenden-Button."}}]'::jsonb,
    '{"html":"<form>\n  <label for=\"name\">Name</label>\n  <input id=\"name\" type=\"text\">\n\n  <label for=\"email\">Email</label>\n  <input id=\"email\" type=\"email\">\n\n  <button type=\"submit\">Send</button>\n</form>","css":"form {\n  display: flex;\n  flex-direction: column;\n  gap: 8px;\n  max-width: 240px;\n}\n\ninput, button {\n  padding: 8px;\n}"}'::jsonb,
    'beginner', true, false, 13
  ),
  (
    (select id from courses where slug = 'frontend'),
    'buttons-hover-transitions',
    '{"en":"Interactive Buttons: Hover & Transitions","de":"Interaktive Buttons: Hover & Übergänge"}'::jsonb,
    '[{"step":1,"text":{"en":":hover applies styles only while the mouse is over an element.","de":":hover wendet Styles nur an, solange sich die Maus über einem Element befindet."}},{"step":2,"text":{"en":"transition makes style changes (like color or size) happen smoothly instead of instantly.","de":"transition lässt Style-Änderungen (wie Farbe oder Größe) sanft statt sofort ablaufen."}},{"step":3,"text":{"en":"Give this button a hover effect with a smooth transition.","de":"Gib diesem Button einen Hover-Effekt mit einem sanften Übergang."}}]'::jsonb,
    '{"html":"<button>Contact Me</button>","css":"button {\n  padding: 12px 24px;\n  background: #34d399;\n  border: none;\n  border-radius: 8px;\n  cursor: pointer;\n  transition: background 0.2s ease;\n}\n\nbutton:hover {\n  background: #22c55e;\n}"}'::jsonb,
    'beginner', true, false, 14
  ),
  (
    (select id from courses where slug = 'frontend'),
    'complete-webpage-project',
    '{"en":"Putting It All Together","de":"Alles zusammenfügen"}'::jsonb,
    '[{"step":1,"text":{"en":"You now know structure (HTML), layout (Flexbox/Grid), and styling (CSS) — everything a real webpage needs.","de":"Du kennst jetzt Struktur (HTML), Layout (Flexbox/Grid) und Gestaltung (CSS) — alles, was eine echte Webseite braucht."}},{"step":2,"text":{"en":"A complete page usually has: header/nav, a hero, 2-3 content sections, and a footer.","de":"Eine vollständige Seite hat meist: Header/Nav, eine Hero-Section, 2-3 Inhaltsabschnitte und einen Footer."}},{"step":3,"text":{"en":"Combine everything you''ve built so far into one complete, styled webpage.","de":"Kombiniere alles, was du bisher gebaut hast, zu einer vollständigen, gestalteten Webseite."}}]'::jsonb,
    '{"html":"<header>\n  <nav><a href=\"#\">Home</a> <a href=\"#\">About</a> <a href=\"#\">Contact</a></nav>\n</header>\n\n<section class=\"hero\">\n  <h1>Hi, I''m Ahmed</h1>\n  <p>I build websites that work.</p>\n</section>\n\n<section>\n  <h2>Skills</h2>\n  <p>HTML, CSS, JavaScript</p>\n</section>\n\n<footer>\n  <p>&copy; 2026 Ahmed</p>\n</footer>","css":".hero {\n  text-align: center;\n  padding: 60px 20px;\n}\n\nfooter {\n  text-align: center;\n  color: #888;\n  margin-top: 40px;\n}"}'::jsonb,
    'beginner', true, false, 15
  ),
  (
    (select id from courses where slug = 'frontend'),
    'frontend-free-exam',
    '{"en":"Exam: Build a Complete Website","de":"Prüfung: Baue eine vollständige Website"}'::jsonb,
    '[{"step":1,"text":{"en":"This is your Frontend exam. Build a complete website using only HTML and CSS — no JavaScript yet.","de":"Das ist deine Frontend-Prüfung. Baue eine vollständige Website nur mit HTML und CSS — noch kein JavaScript."}},{"step":2,"text":{"en":"Requirements: a header with navigation, a hero section, at least two content sections, an image, and a footer.","de":"Anforderungen: ein Header mit Navigation, eine Hero-Section, mindestens zwei Inhaltsabschnitte, ein Bild und ein Footer."}},{"step":3,"text":{"en":"Make it responsive: it should still look good on a narrow screen. When you''re happy with it, mark your practice complete, submit the quiz, and submit your finished site to your portfolio below.","de":"Mach sie responsive: Sie sollte auch auf einem schmalen Bildschirm gut aussehen. Wenn du zufrieden bist, markiere die Übung als erledigt, sende das Quiz ab und reiche deine fertige Website unten in dein Portfolio ein."}}]'::jsonb,
    '{"html":"<!-- Build your complete website here -->\n<header>\n  <nav></nav>\n</header>","css":"/* Style your complete website here */"}'::jsonb,
    'intermediate', true, true, 16
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-introduction',
    '{"en":"JavaScript: Making Your Website Do Things","de":"JavaScript: Deine Website zum Handeln bringen"}'::jsonb,
    '[{"step":1,"text":{"en":"HTML builds structure. CSS makes it look good. JavaScript makes it DO something — react to clicks, update text, and more.","de":"HTML baut die Struktur. CSS lässt sie gut aussehen. JavaScript bringt sie dazu, etwas zu TUN — auf Klicks reagieren, Text aktualisieren und mehr."}},{"step":2,"text":{"en":"addEventListener lets you run code when something happens, like a button being clicked.","de":"addEventListener lässt dich Code ausführen, wenn etwas passiert, zum Beispiel wenn ein Button geklickt wird."}},{"step":3,"text":{"en":"Click the button below to see JavaScript in action, then change the message it shows.","de":"Klicke unten auf den Button, um JavaScript in Aktion zu sehen, und ändere dann die angezeigte Nachricht."}}]'::jsonb,
    '{"html":"<button id=\"welcome-btn\">Click Me</button>","css":"#welcome-btn {\n  padding: 12px 24px;\n  background: #34d399;\n  border: none;\n  border-radius: 8px;\n  cursor: pointer;\n  font-weight: 600;\n}","js":"document.getElementById(\"welcome-btn\").addEventListener(\"click\", function () {\n  alert(\"Welcome!\");\n});"}'::jsonb,
    'beginner', false, false, 17
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-variables',
    '{"en":"Variables: Storing Information","de":"Variablen: Informationen speichern"}'::jsonb,
    '[{"step":1,"text":{"en":"A variable stores a piece of information so you can use it later. let creates a variable that can change.","de":"Eine Variable speichert eine Information, damit du sie später verwenden kannst. let erstellt eine Variable, die sich ändern kann."}},{"step":2,"text":{"en":"You can combine text and variables using + to build a sentence.","de":"Du kannst Text und Variablen mit + kombinieren, um einen Satz zu bilden."}},{"step":3,"text":{"en":"Change the username value and run the code again.","de":"Ändere den Wert von username und führe den Code erneut aus."}}]'::jsonb,
    '{"js":"let username = \"Ahmed\";\nconsole.log(\"Hello, \" + username);"}'::jsonb,
    'beginner', false, false, 18
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-conditions',
    '{"en":"Conditions: Making Decisions","de":"Bedingungen: Entscheidungen treffen"}'::jsonb,
    '[{"step":1,"text":{"en":"if checks whether something is true. else runs when it isn''t.","de":"if prüft, ob etwas wahr ist. else läuft, wenn es das nicht ist."}},{"step":2,"text":{"en":"=== checks if two values are exactly equal — it''s the comparison you''ll use most often.","de":"=== prüft, ob zwei Werte exakt gleich sind — das ist der Vergleich, den du am häufigsten benutzen wirst."}},{"step":3,"text":{"en":"Change the age value and run the code to see both branches.","de":"Ändere den Wert von age und führe den Code aus, um beide Zweige zu sehen."}}]'::jsonb,
    '{"js":"let age = 17;\n\nif (age >= 18) {\n  console.log(\"You can vote.\");\n} else {\n  console.log(\"Not old enough yet.\");\n}"}'::jsonb,
    'beginner', false, false, 19
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-loops',
    '{"en":"Loops: Repeating Actions","de":"Schleifen: Aktionen wiederholen"}'::jsonb,
    '[{"step":1,"text":{"en":"A for loop repeats code a set number of times, without you writing it out manually.","de":"Eine for-Schleife wiederholt Code eine festgelegte Anzahl von Malen, ohne dass du ihn manuell ausschreiben musst."}},{"step":2,"text":{"en":"i is just a counter variable — it starts at 1, and goes up by 1 each time, until the condition is false.","de":"i ist einfach eine Zählvariable — sie startet bei 1 und erhöht sich jedes Mal um 1, bis die Bedingung falsch ist."}},{"step":3,"text":{"en":"Change the loop to count to 10 instead of 5.","de":"Ändere die Schleife so, dass sie bis 10 statt bis 5 zählt."}}]'::jsonb,
    '{"js":"for (let i = 1; i <= 5; i++) {\n  console.log(\"Count: \" + i);\n}"}'::jsonb,
    'beginner', false, false, 20
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-functions',
    '{"en":"Functions: Reusable Code","de":"Funktionen: Wiederverwendbarer Code"}'::jsonb,
    '[{"step":1,"text":{"en":"A function is a reusable block of code. You give it a name, and run it whenever you need it.","de":"Eine Funktion ist ein wiederverwendbarer Codeblock. Du gibst ihr einen Namen und führst sie aus, wann immer du sie brauchst."}},{"step":2,"text":{"en":"Parameters (like name) let you pass information into a function. return sends a value back out.","de":"Parameter (wie name) lassen dich Informationen in eine Funktion hineingeben. return gibt einen Wert zurück."}},{"step":3,"text":{"en":"Call greet() again with a different name.","de":"Rufe greet() erneut mit einem anderen Namen auf."}}]'::jsonb,
    '{"js":"function greet(name) {\n  return \"Hello, \" + name + \"!\";\n}\n\nconsole.log(greet(\"Ahmed\"));"}'::jsonb,
    'beginner', false, false, 21
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-arrays',
    '{"en":"Arrays: Lists of Data","de":"Arrays: Listen von Daten"}'::jsonb,
    '[{"step":1,"text":{"en":"An array holds a list of values in order, like a row of boxes you can look up by position.","de":"Ein Array enthält eine geordnete Liste von Werten, wie eine Reihe von Boxen, die du nach Position abrufen kannst."}},{"step":2,"text":{"en":".push() adds a new item to the end of an array.","de":".push() fügt ein neues Element am Ende eines Arrays hinzu."}},{"step":3,"text":{"en":"Add one more fruit to the list and log the result.","de":"Füge der Liste eine weitere Frucht hinzu und gib das Ergebnis aus."}}]'::jsonb,
    '{"js":"const fruits = [\"Apple\", \"Banana\", \"Mango\"];\nfruits.push(\"Orange\");\nconsole.log(fruits);"}'::jsonb,
    'beginner', false, false, 22
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-objects',
    '{"en":"Objects: Grouping Related Data","de":"Objekte: Zusammengehörige Daten gruppieren"}'::jsonb,
    '[{"step":1,"text":{"en":"An object groups related information together using named properties, like a mini profile card in code.","de":"Ein Objekt gruppiert zusammengehörige Informationen mit benannten Eigenschaften, wie eine Mini-Profilkarte im Code."}},{"step":2,"text":{"en":"Use object.property to read a value out of an object.","de":"Nutze objekt.eigenschaft, um einen Wert aus einem Objekt zu lesen."}},{"step":3,"text":{"en":"Add a new property to the student object, like a favorite language.","de":"Füge dem student-Objekt eine neue Eigenschaft hinzu, zum Beispiel eine Lieblingssprache."}}]'::jsonb,
    '{"js":"const student = {\n  name: \"Ahmed\",\n  level: 3,\n  xp: 250\n};\n\nconsole.log(student.name + \" is level \" + student.level);"}'::jsonb,
    'beginner', false, false, 23
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-dom-basics',
    '{"en":"The DOM: Changing Your Page Live","de":"Das DOM: Deine Seite live verändern"}'::jsonb,
    '[{"step":1,"text":{"en":"The DOM is the browser''s live version of your HTML — JavaScript can read and change it after the page has loaded.","de":"Das DOM ist die lebendige Version deines HTML im Browser — JavaScript kann es nach dem Laden der Seite lesen und ändern."}},{"step":2,"text":{"en":"document.getElementById finds an element. .textContent changes what text it shows.","de":"document.getElementById findet ein Element. .textContent ändert den angezeigten Text."}},{"step":3,"text":{"en":"Click the button, then try changing the new text it sets.","de":"Klicke den Button und ändere dann den neuen Text, den er setzt."}}]'::jsonb,
    '{"html":"<h1 id=\"title\">Hello</h1>\n<button id=\"change-btn\">Change Title</button>","css":"#change-btn {\n  padding: 8px 16px;\n  cursor: pointer;\n}","js":"document.getElementById(\"change-btn\").addEventListener(\"click\", function () {\n  document.getElementById(\"title\").textContent = \"You changed me!\";\n});"}'::jsonb,
    'beginner', false, false, 24
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-name-greeting-project',
    '{"en":"Project: Name Greeting System","de":"Projekt: Namens-Begrüßungssystem"}'::jsonb,
    '[{"step":1,"text":{"en":"You''ve now learned enough to combine HTML, CSS, and JavaScript into a real interactive feature.","de":"Du hast jetzt genug gelernt, um HTML, CSS und JavaScript zu einer echten interaktiven Funktion zu kombinieren."}},{"step":2,"text":{"en":"HTML creates the input and button. CSS styles them. JavaScript reads what was typed and reacts to it.","de":"HTML erstellt das Eingabefeld und den Button. CSS gestaltet sie. JavaScript liest, was eingegeben wurde, und reagiert darauf."}},{"step":3,"text":{"en":"Type your name, press the button, then try personalizing the greeting message.","de":"Gib deinen Namen ein, drücke den Button und personalisiere dann die Begrüßungsnachricht."}}]'::jsonb,
    '{"html":"<input id=\"nameInput\" placeholder=\"Your name\">\n<button id=\"greetBtn\">Say Hello</button>\n<p id=\"output\"></p>","css":"input, button {\n  padding: 8px;\n  margin-right: 8px;\n}","js":"document.getElementById(\"greetBtn\").addEventListener(\"click\", function () {\n  const name = document.getElementById(\"nameInput\").value;\n  document.getElementById(\"output\").textContent = \"Hello, \" + name + \"!\";\n});"}'::jsonb,
    'beginner', false, false, 25
  ),
  (
    (select id from courses where slug = 'frontend'),
    'js-calculator-project',
    '{"en":"Project: Simple Calculator","de":"Projekt: Einfacher Taschenrechner"}'::jsonb,
    '[{"step":1,"text":{"en":"Number() converts text from an input into an actual number, so + adds instead of joining text together.","de":"Number() wandelt Text aus einem Eingabefeld in eine echte Zahl um, sodass + addiert statt Text aneinanderzuhängen."}},{"step":2,"text":{"en":"Without Number(), \"2\" + \"3\" would give you \"23\" — text joined together, not math.","de":"Ohne Number() würde \"2\" + \"3\" \"23\" ergeben — aneinandergehängter Text, keine Rechnung."}},{"step":3,"text":{"en":"Try the calculator, then add a second button that subtracts instead of adds.","de":"Probiere den Taschenrechner aus und füge dann einen zweiten Button hinzu, der subtrahiert statt addiert."}}]'::jsonb,
    '{"html":"<input id=\"numA\" type=\"number\" value=\"0\">\n<input id=\"numB\" type=\"number\" value=\"0\">\n<button id=\"addBtn\">Add</button>\n<p id=\"result\"></p>","css":"input, button {\n  padding: 8px;\n  margin-right: 8px;\n}","js":"document.getElementById(\"addBtn\").addEventListener(\"click\", function () {\n  const a = Number(document.getElementById(\"numA\").value);\n  const b = Number(document.getElementById(\"numB\").value);\n  document.getElementById(\"result\").textContent = \"Result: \" + (a + b);\n});"}'::jsonb,
    'intermediate', false, true, 26
  )
on conflict (slug) do nothing;

-- ── Backend: first 8 free lessons ────────────────────────────────────────────────────

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
values
  (
    (select id from courses where slug = 'backend'),
    'what-happens-when-you-open-a-website',
    '{"en":"What Happens When You Open a Website?","de":"Was passiert, wenn du eine Website öffnest?"}'::jsonb,
    '[{"step":1,"text":{"en":"When a user opens a website, their browser sends a request.","de":"Wenn ein Nutzer eine Website öffnet, sendet sein Browser eine Anfrage."}},{"step":2,"text":{"en":"A server receives the request, processes it, and sends back a response.","de":"Ein Server empfängt die Anfrage, verarbeitet sie und sendet eine Antwort zurück."}},{"step":3,"text":{"en":"That journey — frontend, backend, database, backend, frontend — is what the rest of this course is about.","de":"Diese Reise — Frontend, Backend, Datenbank, Backend, Frontend — ist das Thema des restlichen Kurses."}}]'::jsonb,
    null,
    'beginner', true, false, 1
  ),
  (
    (select id from courses where slug = 'backend'),
    'creating-your-first-server',
    '{"en":"Creating Your First Server","de":"Deinen ersten Server erstellen"}'::jsonb,
    '[{"step":1,"text":{"en":"A server is a program that waits for requests and sends back responses. It is always running, listening.","de":"Ein Server ist ein Programm, das auf Anfragen wartet und Antworten zurücksendet. Er läuft ständig und hört zu."}},{"step":2,"text":{"en":"When a browser visits a path like /hello, the server decides what to send back.","de":"Wenn ein Browser einen Pfad wie /hello aufruft, entscheidet der Server, was er zurücksendet."}},{"step":3,"text":{"en":"Below is a JavaScript function that acts like a tiny server. Run it and check the console — then try changing what /hello returns.","de":"Unten ist eine JavaScript-Funktion, die wie ein kleiner Server funktioniert. Führe sie aus und schau in die Konsole — ändere dann, was /hello zurückgibt."}}]'::jsonb,
    '{"js":"function handleRequest(path) {\n  if (path === \"/hello\") {\n    return \"Hello Student\";\n  }\n  return \"404 Not Found\";\n}\n\nconsole.log(handleRequest(\"/hello\"));"}'::jsonb,
    'beginner', true, false, 2
  ),
  (
    (select id from courses where slug = 'backend'),
    'frontend-backend-connection',
    '{"en":"Frontend Asks, Backend Answers","de":"Frontend fragt, Backend antwortet"}'::jsonb,
    '[{"step":1,"text":{"en":"In a real app, the frontend (browser) sends a request, and the backend (server) sends back data — like a message or a list of users.","de":"In einer echten App sendet das Frontend (Browser) eine Anfrage, und das Backend (Server) sendet Daten zurück — etwa eine Nachricht oder eine Liste von Nutzern."}},{"step":2,"text":{"en":"This request-response pattern is the foundation of almost everything on the internet.","de":"Dieses Anfrage-Antwort-Muster ist die Grundlage für fast alles im Internet."}},{"step":3,"text":{"en":"Simulate it: this getMessage() function returns what a backend would send to the frontend. Run it and check the console.","de":"Simuliere es: Diese getMessage()-Funktion gibt zurück, was ein Backend an das Frontend senden würde. Führe sie aus und schau in die Konsole."}}]'::jsonb,
    '{"js":"function getMessage() {\n  return \"Welcome to CodePath Academy\";\n}\n\nconsole.log(getMessage());"}'::jsonb,
    'beginner', true, false, 3
  ),
  (
    (select id from courses where slug = 'backend'),
    'nodejs-introduction',
    '{"en":"Node.js: JavaScript Outside the Browser","de":"Node.js: JavaScript außerhalb des Browsers"}'::jsonb,
    '[{"step":1,"text":{"en":"You already know JavaScript from the frontend. Node.js lets that same language run on a server, not just in a browser.","de":"Du kennst JavaScript schon vom Frontend. Node.js lässt dieselbe Sprache auf einem Server laufen, nicht nur im Browser."}},{"step":2,"text":{"en":"This means the language you learned for buttons and forms can also handle requests, files, and databases.","de":"Das bedeutet: Die Sprache, die du für Buttons und Formulare gelernt hast, kann auch Anfragen, Dateien und Datenbanken verarbeiten."}},{"step":3,"text":{"en":"There is no browser here — just JavaScript logic. Run this function, then add a fourth username to the list.","de":"Hier gibt es keinen Browser — nur JavaScript-Logik. Führe diese Funktion aus und füge dann einen vierten Nutzernamen zur Liste hinzu."}}]'::jsonb,
    '{"js":"function getUsers() {\n  return [\"Ahmed\", \"Sara\", \"Lina\"];\n}\n\nconsole.log(getUsers());"}'::jsonb,
    'beginner', true, false, 4
  ),
  (
    (select id from courses where slug = 'backend'),
    'express-routes-intro',
    '{"en":"Routes: Answering Different Requests","de":"Routen: Verschiedene Anfragen beantworten"}'::jsonb,
    '[{"step":1,"text":{"en":"A real server needs to handle many different paths — /users, /login, /products — each with its own response. These are called routes.","de":"Ein echter Server muss viele verschiedene Pfade verarbeiten — /users, /login, /products — jeder mit einer eigenen Antwort. Das nennt man Routen."}},{"step":2,"text":{"en":"Express is a popular tool that makes defining routes simple. You will use it for real once you have this mental model down.","de":"Express ist ein beliebtes Tool, das das Definieren von Routen einfach macht. Du wirst es später wirklich nutzen, sobald du dieses Grundprinzip verstanden hast."}},{"step":3,"text":{"en":"This router(path) function simulates routing. Run it, then add a new route for /login.","de":"Diese router(path)-Funktion simuliert Routing. Führe sie aus und füge dann eine neue Route für /login hinzu."}}]'::jsonb,
    '{"js":"function router(path) {\n  if (path === \"/users\") return [\"Ahmed\", \"Sara\"];\n  if (path === \"/products\") return [\"Laptop\", \"Mouse\"];\n  return \"Not Found\";\n}\n\nconsole.log(router(\"/users\"));\nconsole.log(router(\"/products\"));"}'::jsonb,
    'beginner', true, false, 5
  ),
  (
    (select id from courses where slug = 'backend'),
    'building-an-api-endpoint',
    '{"en":"Building an API Endpoint","de":"Einen API-Endpunkt bauen"}'::jsonb,
    '[{"step":1,"text":{"en":"An API endpoint is a specific URL a frontend can call to get or send data — like /api/users returning a list of users.","de":"Ein API-Endpunkt ist eine bestimmte URL, die ein Frontend aufrufen kann, um Daten zu holen oder zu senden — z. B. gibt /api/users eine Liste von Nutzern zurück."}},{"step":2,"text":{"en":"JSON (JavaScript Object Notation) is the format almost all APIs use to send data — it looks just like JavaScript objects.","de":"JSON (JavaScript Object Notation) ist das Format, das fast alle APIs zum Senden von Daten nutzen — es sieht genauso aus wie JavaScript-Objekte."}},{"step":3,"text":{"en":"This simulates an API endpoint. Run it, then add an email field to each user.","de":"Das simuliert einen API-Endpunkt. Führe es aus und füge dann jedem Nutzer ein E-Mail-Feld hinzu."}}]'::jsonb,
    '{"js":"function getUsersEndpoint() {\n  return [\n    { id: 1, name: \"Ahmed\" },\n    { id: 2, name: \"Sara\" }\n  ];\n}\n\nconsole.log(JSON.stringify(getUsersEndpoint(), null, 2));"}'::jsonb,
    'beginner', true, false, 6
  ),
  (
    (select id from courses where slug = 'backend'),
    'why-databases-exist',
    '{"en":"Why Databases Exist","de":"Warum es Datenbanken gibt"}'::jsonb,
    '[{"step":1,"text":{"en":"Without a database, information disappears the moment your program stops running. A database stores it permanently.","de":"Ohne Datenbank verschwinden Informationen, sobald dein Programm nicht mehr läuft. Eine Datenbank speichert sie dauerhaft."}},{"step":2,"text":{"en":"A database organizes data into tables — think of a table like a spreadsheet, with rows and columns.","de":"Eine Datenbank organisiert Daten in Tabellen — stell dir eine Tabelle wie eine Kalkulationstabelle mit Zeilen und Spalten vor."}},{"step":3,"text":{"en":"This array represents a ''users'' table with 2 rows. Run it, then add a third user row.","de":"Dieses Array stellt eine „users“-Tabelle mit 2 Zeilen dar. Führe es aus und füge dann eine dritte Nutzerzeile hinzu."}}]'::jsonb,
    '{"js":"const usersTable = [\n  { id: 1, name: \"Ahmed\", email: \"ahmed@example.com\" },\n  { id: 2, name: \"Sara\", email: \"sara@example.com\" }\n];\n\nconsole.log(usersTable);"}'::jsonb,
    'beginner', true, false, 7
  ),
  (
    (select id from courses where slug = 'backend'),
    'backend-free-exam',
    '{"en":"Exam: Design a Simple API","de":"Prüfung: Entwirf eine einfache API"}'::jsonb,
    '[{"step":1,"text":{"en":"This is your Backend foundations check. You will not run a real server yet — but you will design one.","de":"Das ist deine Backend-Grundlagenprüfung. Du wirst noch keinen echten Server betreiben — aber einen entwerfen."}},{"step":2,"text":{"en":"Requirements: write a router(path) function with at least 3 routes, and a getUsersEndpoint() function that returns JSON-shaped data.","de":"Anforderungen: Schreibe eine router(path)-Funktion mit mindestens 3 Routen und eine getUsersEndpoint()-Funktion, die JSON-förmige Daten zurückgibt."}},{"step":3,"text":{"en":"This is exactly the mental model real backend frameworks like Express use — you already understand it. When you''re happy with it, mark your practice complete, submit the quiz, and submit it to your portfolio below.","de":"Das ist genau das Grundprinzip, das echte Backend-Frameworks wie Express verwenden — du verstehst es schon. Wenn du zufrieden bist, markiere die Übung als erledigt, sende das Quiz ab und reiche sie unten in dein Portfolio ein."}}]'::jsonb,
    '{"js":"// Write your router(path) function and getUsersEndpoint() function here\n"}'::jsonb,
    'intermediate', true, true, 8
  ),
  (
    (select id from courses where slug = 'backend'),
    'backend-database-tables',
    '{"en":"Designing a Real Database Table","de":"Eine echte Datenbanktabelle entwerfen"}'::jsonb,
    '[{"step":1,"text":{"en":"A real users table needs more than a name — an id to uniquely identify each row, and a created date to know when it was added.","de":"Eine echte users-Tabelle braucht mehr als nur einen Namen — eine id, um jede Zeile eindeutig zu identifizieren, und ein Erstellungsdatum, um zu wissen, wann sie hinzugefügt wurde."}},{"step":2,"text":{"en":"addUser() below simulates an INSERT: it builds a new row and adds it to the table.","de":"addUser() unten simuliert ein INSERT: Es baut eine neue Zeile und fügt sie der Tabelle hinzu."}},{"step":3,"text":{"en":"Run it, then call addUser() again with a different name and email.","de":"Führe es aus und rufe addUser() dann erneut mit einem anderen Namen und einer anderen E-Mail auf."}}]'::jsonb,
    '{"js":"const usersTable = [\n  { id: 1, name: \"Ahmed\", email: \"ahmed@example.com\", createdAt: \"2026-01-01\" }\n];\n\nfunction addUser(name, email) {\n  const newUser = { id: usersTable.length + 1, name: name, email: email, createdAt: new Date().toISOString() };\n  usersTable.push(newUser);\n  return newUser;\n}\n\nconsole.log(addUser(\"Sara\", \"sara@example.com\"));"}'::jsonb,
    'beginner', false, false, 9
  ),
  (
    (select id from courses where slug = 'backend'),
    'backend-password-security',
    '{"en":"Passwords: Never Store Them in Plain Text","de":"Passwörter: Niemals im Klartext speichern"}'::jsonb,
    '[{"step":1,"text":{"en":"If passwords were stored as plain, readable text and the database was ever exposed, every user''s real password would be exposed too.","de":"Wenn Passwörter als reiner, lesbarer Text gespeichert würden und die Datenbank jemals offengelegt würde, wäre auch das echte Passwort jedes Nutzers offengelegt."}},{"step":2,"text":{"en":"Hashing turns a password into a scrambled value that can''t be reversed back into the original. Real apps use a proper library (like bcrypt) for this — Supabase already does it for you.","de":"Hashing verwandelt ein Passwort in einen verschlüsselten Wert, der nicht zurück in das Original umgewandelt werden kann. Echte Apps nutzen dafür eine richtige Bibliothek (wie bcrypt) — Supabase macht das bereits automatisch für dich."}},{"step":3,"text":{"en":"This fakeHash function is just for illustration, not real security. Run it with a different password.","de":"Diese fakeHash-Funktion dient nur zur Veranschaulichung, nicht als echte Sicherheit. Führe sie mit einem anderen Passwort aus."}}]'::jsonb,
    '{"js":"// A real app uses a proper library (like bcrypt) — this is just to see the idea.\nfunction fakeHash(password) {\n  let hash = 0;\n  for (let i = 0; i < password.length; i++) {\n    hash = (hash * 31 + password.charCodeAt(i)) % 1000000;\n  }\n  return \"hash_\" + hash;\n}\n\nconsole.log(fakeHash(\"mypassword123\"));"}'::jsonb,
    'beginner', false, false, 10
  ),
  (
    (select id from courses where slug = 'backend'),
    'backend-registration-flow',
    '{"en":"Building a Register Flow","de":"Einen Registrierungs-Flow bauen"}'::jsonb,
    '[{"step":1,"text":{"en":"When someone registers, the frontend sends their name, email, and password to the backend — but the backend must never fully trust that data.","de":"Wenn sich jemand registriert, sendet das Frontend Name, E-Mail und Passwort an das Backend — aber das Backend darf diesen Daten niemals vollständig vertrauen."}},{"step":2,"text":{"en":"registerUser() below checks the data is valid before accepting it, and returns a clear error if not.","de":"registerUser() unten prüft, ob die Daten gültig sind, bevor sie akzeptiert werden, und gibt bei Fehlern eine klare Fehlermeldung zurück."}},{"step":3,"text":{"en":"Run it, then try calling registerUser() with a missing field.","de":"Führe es aus und rufe registerUser() dann mit einem fehlenden Feld auf."}}]'::jsonb,
    '{"js":"function registerUser(name, email, password) {\n  if (!name || !email || !password) {\n    return { error: \"All fields are required.\" };\n  }\n  if (password.length < 8) {\n    return { error: \"Password must be at least 8 characters.\" };\n  }\n  return { success: true, user: { name: name, email: email } };\n}\n\nconsole.log(registerUser(\"Ahmed\", \"ahmed@example.com\", \"short\"));\nconsole.log(registerUser(\"Ahmed\", \"ahmed@example.com\", \"longenough123\"));"}'::jsonb,
    'beginner', false, false, 11
  ),
  (
    (select id from courses where slug = 'backend'),
    'backend-sessions-auth',
    '{"en":"Staying Logged In: Sessions & Tokens","de":"Angemeldet bleiben: Sessions & Tokens"}'::jsonb,
    '[{"step":1,"text":{"en":"Every request to a server is independent by default — the server doesn''t automatically remember who you are between requests.","de":"Jede Anfrage an einen Server ist standardmäßig unabhängig — der Server merkt sich nicht automatisch, wer du zwischen Anfragen bist."}},{"step":2,"text":{"en":"A session or token is issued when you log in, and sent along with every later request so the server recognizes you.","de":"Eine Session oder ein Token wird beim Login ausgestellt und bei jeder späteren Anfrage mitgeschickt, damit der Server dich erkennt."}},{"step":3,"text":{"en":"Run this simulation, then look up the same token again to confirm it still works.","de":"Führe diese Simulation aus und rufe dasselbe Token dann erneut ab, um zu bestätigen, dass es noch funktioniert."}}]'::jsonb,
    '{"js":"const activeSessions = {};\n\nfunction login(userId) {\n  const token = \"token_\" + userId + \"_\" + Date.now();\n  activeSessions[token] = userId;\n  return token;\n}\n\nfunction getUserFromToken(token) {\n  return activeSessions[token] || null;\n}\n\nconst myToken = login(1);\nconsole.log(\"Token:\", myToken);\nconsole.log(\"Logged in as user:\", getUserFromToken(myToken));"}'::jsonb,
    'intermediate', false, false, 12
  ),
  (
    (select id from courses where slug = 'backend'),
    'backend-error-handling',
    '{"en":"Handling Errors Gracefully","de":"Fehler sauber behandeln"}'::jsonb,
    '[{"step":1,"text":{"en":"Things go wrong — a user might not exist, or a request might be malformed. A good API responds clearly instead of crashing.","de":"Dinge gehen schief — ein Nutzer existiert vielleicht nicht, oder eine Anfrage ist fehlerhaft. Eine gute API antwortet klar, statt abzustürzen."}},{"step":2,"text":{"en":"Returning a status and a message (like 404 and \"User not found\") lets the frontend react appropriately instead of guessing.","de":"Ein Status und eine Nachricht (wie 404 und „User not found“) lassen das Frontend angemessen reagieren, statt zu raten."}},{"step":3,"text":{"en":"Run it with an id that exists, then one that doesn''t.","de":"Führe es mit einer existierenden id aus, dann mit einer, die es nicht gibt."}}]'::jsonb,
    '{"js":"function getUserById(id, usersTable) {\n  const user = usersTable.find(function (u) { return u.id === id; });\n  if (!user) {\n    return { status: 404, error: \"User not found\" };\n  }\n  return { status: 200, data: user };\n}\n\nconst users = [{ id: 1, name: \"Ahmed\" }];\nconsole.log(getUserById(1, users));\nconsole.log(getUserById(99, users));"}'::jsonb,
    'intermediate', false, false, 13
  ),
  (
    (select id from courses where slug = 'backend'),
    'backend-paid-exam',
    '{"en":"Exam: Build a Mini User System","de":"Prüfung: Baue ein Mini-Nutzersystem"}'::jsonb,
    '[{"step":1,"text":{"en":"Time to combine everything: registration, login, and error handling, into one small system.","de":"Zeit, alles zu kombinieren: Registrierung, Login und Fehlerbehandlung zu einem kleinen System."}},{"step":2,"text":{"en":"Requirements: a registerUser() function, a login() function that issues a token, and a getUserFromToken() function.","de":"Anforderungen: eine registerUser()-Funktion, eine login()-Funktion, die ein Token ausstellt, und eine getUserFromToken()-Funktion."}},{"step":3,"text":{"en":"This is exactly the mental model real authentication systems use — you already understand it. When you''re happy with it, mark your practice complete, submit the quiz, and submit it to your portfolio below.","de":"Das ist genau das Grundprinzip, das echte Authentifizierungssysteme verwenden — du verstehst es schon. Wenn du zufrieden bist, markiere die Übung als erledigt, sende das Quiz ab und reiche sie unten in dein Portfolio ein."}}]'::jsonb,
    '{"js":"// Combine what you''ve learned: registration, login, and error handling.\n// Write registerUser(), login(), and getUserFromToken() below.\n"}'::jsonb,
    'intermediate', false, true, 14
  )
on conflict (slug) do nothing;

-- ── Quiz questions (one per lesson that has one) ─────────────────────────

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
values
  (
    (select id from lessons where slug = 'html-hello-world'),
    '{"en":"What does HTML control on a website?","de":"Was steuert HTML auf einer Website?"}'::jsonb,
    '{"en":["The database","The structure and content","The server","The payment system"],"de":["Die Datenbank","Die Struktur und den Inhalt","Den Server","Das Zahlungssystem"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'css-styling-basics'),
    '{"en":"What does CSS control?","de":"Was steuert CSS?"}'::jsonb,
    '{"en":["The database","Website design","The server","User accounts"],"de":["Die Datenbank","Das Design der Website","Den Server","Benutzerkonten"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'html-css-div-profile-card'),
    '{"en":"What does the border-radius property do?","de":"Was macht die Eigenschaft border-radius?"}'::jsonb,
    '{"en":["Adds a shadow","Rounds the corners of an element","Changes text color","Adds a border image"],"de":["Fügt einen Schatten hinzu","Rundet die Ecken eines Elements ab","Ändert die Textfarbe","Fügt ein Rahmenbild hinzu"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'website-structure-nav-footer'),
    '{"en":"What does display: flex do?","de":"Was macht display: flex?"}'::jsonb,
    '{"en":["Deletes an element","Arranges child elements in a row (or column)","Makes text bold","Adds a border"],"de":["Löscht ein Element","Ordnet Kindelemente in einer Reihe (oder Spalte) an","Macht Text fett","Fügt einen Rahmen hinzu"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'flexbox-layout-basics'),
    '{"en":"Which property adds space between flex items?","de":"Welche Eigenschaft fügt Abstand zwischen Flex-Elementen hinzu?"}'::jsonb,
    '{"en":["space","margin-all","gap","spacing"],"de":["space","margin-all","gap","spacing"]}'::jsonb, 2, 1
  ),
  (
    (select id from lessons where slug = 'semantic-html-sections'),
    '{"en":"Which tag best marks the main content of a page?","de":"Welches Tag markiert den Hauptinhalt einer Seite am besten?"}'::jsonb,
    '{"en":["<div>","<main>","<span>","<b>"],"de":["<div>","<main>","<span>","<b>"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'typography-basics'),
    '{"en":"What does line-height control?","de":"Was steuert line-height?"}'::jsonb,
    '{"en":["Font color","Space between lines of text","Font size","Text alignment"],"de":["Die Schriftfarbe","Den Abstand zwischen Textzeilen","Die Schriftgröße","Die Textausrichtung"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'box-model-deep-dive'),
    '{"en":"What is the difference between margin and padding?","de":"Was ist der Unterschied zwischen margin und padding?"}'::jsonb,
    '{"en":["No difference","Margin is inside the border, padding is outside","Padding is inside the border, margin is outside","Margin only works on text"],"de":["Kein Unterschied","Margin ist innerhalb des Rahmens, Padding außerhalb","Padding ist innerhalb des Rahmens, Margin außerhalb","Margin funktioniert nur bei Text"]}'::jsonb, 2, 1
  ),
  (
    (select id from lessons where slug = 'hero-section'),
    '{"en":"What is a \"hero section\"?","de":"Was ist eine „Hero-Section“?"}'::jsonb,
    '{"en":["The website''s footer","A large introductory section at the top of a page","A navigation menu","A contact form"],"de":["Der Footer der Website","Ein großer einleitender Bereich oben auf einer Seite","Ein Navigationsmenü","Ein Kontaktformular"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'landing-page-assembly'),
    '{"en":"What usually comes first on a landing page?","de":"Was kommt auf einer Landingpage normalerweise zuerst?"}'::jsonb,
    '{"en":["The footer","A hero section","A login form","A database"],"de":["Der Footer","Eine Hero-Section","Ein Login-Formular","Eine Datenbank"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'responsive-images'),
    '{"en":"What does max-width: 100% do on an image?","de":"Was bewirkt max-width: 100% bei einem Bild?"}'::jsonb,
    '{"en":["Makes it always 100px wide","Stops it from growing wider than its container","Deletes the image","Adds a border"],"de":["Macht es immer 100px breit","Verhindert, dass es breiter als sein Container wird","Löscht das Bild","Fügt einen Rahmen hinzu"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'css-grid-basics'),
    '{"en":"Which property sets the number of grid columns?","de":"Welche Eigenschaft legt die Anzahl der Grid-Spalten fest?"}'::jsonb,
    '{"en":["grid-columns","grid-template-columns","column-count","display: columns"],"de":["grid-columns","grid-template-columns","column-count","display: columns"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'html-forms-basics'),
    '{"en":"What is <label> used for?","de":"Wofür wird <label> verwendet?"}'::jsonb,
    '{"en":["Styling a button","Describing what a form field is for","Creating a link","Adding an image"],"de":["Um einen Button zu gestalten","Um zu beschreiben, wofür ein Formularfeld da ist","Um einen Link zu erstellen","Um ein Bild hinzuzufügen"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'buttons-hover-transitions'),
    '{"en":"When does a :hover style apply?","de":"Wann gilt ein :hover-Style?"}'::jsonb,
    '{"en":["Always","Only while the mouse is over the element","Only on page load","Never in modern browsers"],"de":["Immer","Nur solange sich die Maus über dem Element befindet","Nur beim Laden der Seite","Nie in modernen Browsern"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'complete-webpage-project'),
    '{"en":"Which of these is NOT typically part of a complete webpage?","de":"Was gehört normalerweise NICHT zu einer vollständigen Webseite?"}'::jsonb,
    '{"en":["Header","Footer","Hero section","Database schema"],"de":["Header","Footer","Hero-Section","Datenbankschema"]}'::jsonb, 3, 1
  ),
  (
    (select id from lessons where slug = 'frontend-free-exam'),
    '{"en":"Why does this exam not use JavaScript yet?","de":"Warum verwendet diese Prüfung noch kein JavaScript?"}'::jsonb,
    '{"en":["JavaScript does not work in browsers","You first master structure (HTML) and design (CSS) before adding behavior","JavaScript is only for backend","CSS can replace JavaScript entirely"],"de":["JavaScript funktioniert nicht in Browsern","Du beherrschst zuerst Struktur (HTML) und Design (CSS), bevor Verhalten dazukommt","JavaScript ist nur für Backend","CSS kann JavaScript vollständig ersetzen"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'js-introduction'),
    '{"en":"What does addEventListener let you do?","de":"Was ermöglicht dir addEventListener?"}'::jsonb,
    '{"en":["Style an element","Run code when something happens, like a click","Create a database","Send an email"],"de":["Ein Element stylen","Code ausführen, wenn etwas passiert, z. B. ein Klick","Eine Datenbank erstellen","Eine E-Mail senden"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'js-variables'),
    '{"en":"Which keyword creates a variable that can change later?","de":"Welches Schlüsselwort erstellt eine Variable, die sich später ändern kann?"}'::jsonb,
    '{"en":["const","let","final","fixed"],"de":["const","let","final","fixed"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'js-conditions'),
    '{"en":"What does === check?","de":"Was prüft ===?"}'::jsonb,
    '{"en":["If a variable exists","If two values are strictly equal","If a value is a string","If a loop should stop"],"de":["Ob eine Variable existiert","Ob zwei Werte exakt gleich sind","Ob ein Wert ein String ist","Ob eine Schleife stoppen soll"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'js-loops'),
    '{"en":"What does a for loop do?","de":"Was macht eine for-Schleife?"}'::jsonb,
    '{"en":["Deletes variables","Repeats code a set number of times","Creates a function","Connects to a server"],"de":["Löscht Variablen","Wiederholt Code eine festgelegte Anzahl von Malen","Erstellt eine Funktion","Verbindet sich mit einem Server"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'js-functions'),
    '{"en":"What does the return keyword do in a function?","de":"Was macht das Schlüsselwort return in einer Funktion?"}'::jsonb,
    '{"en":["Stops the whole program","Sends a value back to where the function was called","Deletes the function","Creates a loop"],"de":["Stoppt das ganze Programm","Gibt einen Wert dorthin zurück, wo die Funktion aufgerufen wurde","Löscht die Funktion","Erstellt eine Schleife"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'js-arrays'),
    '{"en":"Which method adds an item to the end of an array?","de":"Welche Methode fügt ein Element am Ende eines Arrays hinzu?"}'::jsonb,
    '{"en":[".push()",".remove()",".delete()",".add()"],"de":[".push()",".remove()",".delete()",".add()"]}'::jsonb, 0, 1
  ),
  (
    (select id from lessons where slug = 'js-objects'),
    '{"en":"How do you access a property on an object?","de":"Wie greift man auf eine Eigenschaft eines Objekts zu?"}'::jsonb,
    '{"en":["object[property]() only","object.property or object[\"property\"]","object->property","object::property"],"de":["Nur object[property]()","object.property oder object[\"property\"]","object->property","object::property"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'js-dom-basics'),
    '{"en":"What is the DOM?","de":"Was ist das DOM?"}'::jsonb,
    '{"en":["A database format","The browser''s live representation of your page, which JS can change","A CSS framework","A type of server"],"de":["Ein Datenbankformat","Die lebendige Darstellung deiner Seite im Browser, die JS ändern kann","Ein CSS-Framework","Eine Art von Server"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'js-name-greeting-project'),
    '{"en":"In this lesson, what is JavaScript responsible for?","de":"Wofür ist JavaScript in dieser Lektion verantwortlich?"}'::jsonb,
    '{"en":["Creating the input element","Styling the button","Reading the input value and updating the page","Storing data in a database"],"de":["Das Eingabefeld erstellen","Den Button gestalten","Den Eingabewert lesen und die Seite aktualisieren","Daten in einer Datenbank speichern"]}'::jsonb, 2, 1
  ),
  (
    (select id from lessons where slug = 'js-calculator-project'),
    '{"en":"Why do we use Number() around the input values?","de":"Warum verwenden wir Number() um die Eingabewerte?"}'::jsonb,
    '{"en":["To make them red","Input values are text by default; Number() converts them so + adds instead of joining text","To delete them","To hide them"],"de":["Um sie rot zu färben","Eingabewerte sind standardmäßig Text; Number() wandelt sie um, sodass + addiert statt Text aneinanderzuhängen","Um sie zu löschen","Um sie zu verstecken"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'creating-your-first-server'),
    '{"en":"What does a server do when it receives a request?","de":"Was macht ein Server, wenn er eine Anfrage empfängt?"}'::jsonb,
    '{"en":["Deletes the browser","Processes it and sends back a response","Only stores passwords","Shows a CSS file"],"de":["Löscht den Browser","Verarbeitet sie und sendet eine Antwort zurück","Speichert nur Passwörter","Zeigt eine CSS-Datei"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'frontend-backend-connection'),
    '{"en":"In the request-response pattern, who sends the request?","de":"Wer sendet im Anfrage-Antwort-Muster die Anfrage?"}'::jsonb,
    '{"en":["The database","The frontend","The backend","The server itself"],"de":["Die Datenbank","Das Frontend","Das Backend","Der Server selbst"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'nodejs-introduction'),
    '{"en":"What is Node.js?","de":"Was ist Node.js?"}'::jsonb,
    '{"en":["A CSS framework","A way to run JavaScript outside the browser, e.g. on a server","A database","A design tool"],"de":["Ein CSS-Framework","Eine Möglichkeit, JavaScript außerhalb des Browsers auszuführen, z. B. auf einem Server","Eine Datenbank","Ein Design-Tool"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'express-routes-intro'),
    '{"en":"What is a \"route\" on a server?","de":"Was ist eine „Route“ auf einem Server?"}'::jsonb,
    '{"en":["A CSS class","A specific path the server knows how to respond to","A type of database","A browser tab"],"de":["Eine CSS-Klasse","Ein bestimmter Pfad, auf den der Server antworten kann","Eine Art Datenbank","Ein Browser-Tab"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'building-an-api-endpoint'),
    '{"en":"What format do most APIs use to send data?","de":"Welches Format verwenden die meisten APIs zum Senden von Daten?"}'::jsonb,
    '{"en":["CSS","JSON","HTML","MP3"],"de":["CSS","JSON","HTML","MP3"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'why-databases-exist'),
    '{"en":"What happens to data without a database?","de":"Was passiert mit Daten ohne Datenbank?"}'::jsonb,
    '{"en":["It becomes faster","It disappears when the program stops","It becomes more secure","Nothing changes"],"de":["Sie werden schneller","Sie verschwinden, wenn das Programm stoppt","Sie werden sicherer","Nichts ändert sich"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'backend-free-exam'),
    '{"en":"What have routes and endpoints let you simulate in this lesson?","de":"Was konntest du mit Routen und Endpunkten in dieser Lektion simulieren?"}'::jsonb,
    '{"en":["A CSS animation","How a server responds differently to different requests","A database backup","An image gallery"],"de":["Eine CSS-Animation","Wie ein Server unterschiedlich auf verschiedene Anfragen reagiert","Ein Datenbank-Backup","Eine Bildergalerie"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'backend-database-tables'),
    '{"en":"Why does each user need a unique id?","de":"Warum braucht jeder Nutzer eine eindeutige id?"}'::jsonb,
    '{"en":["To make the table colorful","So each row can be found and referenced without confusion","To slow down the database","It''s optional and never used"],"de":["Um die Tabelle bunt zu machen","Damit jede Zeile eindeutig gefunden und referenziert werden kann","Um die Datenbank zu verlangsamen","Sie ist optional und wird nie verwendet"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'backend-password-security'),
    '{"en":"Why should passwords never be stored in plain text?","de":"Warum sollten Passwörter niemals im Klartext gespeichert werden?"}'::jsonb,
    '{"en":["It uses more storage space","If the database is ever exposed, attackers would see every real password","It makes login slower","Plain text passwords are illegal everywhere"],"de":["Es braucht mehr Speicherplatz","Wenn die Datenbank jemals offengelegt wird, sehen Angreifer jedes echte Passwort","Es macht den Login langsamer","Klartext-Passwörter sind überall illegal"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'backend-registration-flow'),
    '{"en":"Why does the backend validate data again, even if the frontend already checked it?","de":"Warum validiert das Backend Daten erneut, obwohl das Frontend sie schon geprüft hat?"}'::jsonb,
    '{"en":["It doesn''t need to — frontend checks are enough","A request can be sent directly to the backend, bypassing the frontend entirely","To make the code longer","Validation is only for looks"],"de":["Muss es nicht — Frontend-Prüfungen reichen aus","Eine Anfrage kann direkt ans Backend gesendet werden, komplett am Frontend vorbei","Um den Code länger zu machen","Validierung ist nur fürs Aussehen"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'backend-sessions-auth'),
    '{"en":"Why are sessions/tokens needed?","de":"Warum sind Sessions/Tokens notwendig?"}'::jsonb,
    '{"en":["Websites look nicer with them","HTTP requests don''t remember each other by default, so the server needs a way to recognize you on the next request","They make the CSS load faster","They replace the need for a database"],"de":["Websites sehen damit hübscher aus","HTTP-Anfragen erinnern sich standardmäßig nicht aneinander, der Server braucht also eine Möglichkeit, dich bei der nächsten Anfrage wiederzuerkennen","Sie lassen CSS schneller laden","Sie ersetzen die Notwendigkeit einer Datenbank"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'backend-error-handling'),
    '{"en":"What should a well-behaved API do when something goes wrong?","de":"Was sollte eine gut gebaute API tun, wenn etwas schiefgeht?"}'::jsonb,
    '{"en":["Crash immediately with no message","Return a clear error response so the frontend can react appropriately","Delete the request","Ignore it silently"],"de":["Sofort ohne Meldung abstürzen","Eine klare Fehlerantwort zurückgeben, damit das Frontend angemessen reagieren kann","Die Anfrage löschen","Sie stillschweigend ignorieren"]}'::jsonb, 1, 1
  ),
  (
    (select id from lessons where slug = 'backend-paid-exam'),
    '{"en":"What have you built across these backend lessons?","de":"Was hast du über diese Backend-Lektionen hinweg gebaut?"}'::jsonb,
    '{"en":["A CSS animation library","The core mental model behind real authentication systems","A video game","An image editor"],"de":["Eine CSS-Animationsbibliothek","Das Kernprinzip hinter echten Authentifizierungssystemen","Ein Videospiel","Einen Bildeditor"]}'::jsonb, 1, 1
  )
on conflict (lesson_id, question) do nothing;
-- CodePath Academy — checkpoint exams
-- Adds a mid-part "checkpoint" exam to each curriculum part that previously
-- only had an end-of-part exam (HTML/CSS, JavaScript, Backend foundations,
-- Backend security). Run this in the Supabase SQL editor AFTER schema.sql
-- and seed.sql have already been run once.
--
-- Every step below is guarded ("if not exists" / "where not exists"), so
-- it is safe to paste and run this file more than once.
--
-- Generated by gen-checkpoint-exams.js — don't hand-edit, regenerate instead.

-- Shift lessons at/after position 9 in "frontend" to make room for "html-css-checkpoint-exam"
do $$
begin
  if not exists (select 1 from lessons where slug = 'html-css-checkpoint-exam') then
    update lessons
      set sort_order = sort_order + 1
      where course_id = (select id from courses where slug = 'frontend')
        and sort_order >= 9;
  end if;
end $$;

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'html-css-checkpoint-exam',
  '{"en":"Checkpoint: HTML & CSS","de":"Zwischenprüfung: HTML & CSS"}'::jsonb,
  '[{"step":1,"text":{"en":"This is a checkpoint — a short exam that checks everything you''ve built so far: structure, styling, layout, and semantic HTML.","de":"Das ist eine Zwischenprüfung — ein kurzer Test für alles, was du bisher gebaut hast: Struktur, Styling, Layout und semantisches HTML."}},{"step":2,"text":{"en":"Extend your profile card into a small \"About Me\" section using flexbox for layout, real HTML5 semantic tags (header, main, section), and the box-model spacing you just learned.","de":"Erweitere deine Profilkarte zu einem kleinen „Über mich\"-Bereich — mit Flexbox fürs Layout, echten semantischen HTML5-Tags (header, main, section) und den Box-Model-Abständen, die du gerade gelernt hast."}},{"step":3,"text":{"en":"Press Run to preview, then submit your project below when you''re done — same flow as a real assignment.","de":"Klicke auf Ausführen für die Vorschau und reiche dein Projekt unten ein, wenn du fertig bist — genau wie bei einer echten Aufgabe."}}]'::jsonb,
  '{"html":"<header>\n  <h1>Ahmed</h1>\n</header>\n<main>\n  <section class=\"about\">\n    <p>Add a short paragraph about yourself here.</p>\n  </section>\n</main>","css":"body {\n  font-family: sans-serif;\n}\n\n.about {\n  display: flex;\n  flex-direction: column;\n  padding: 16px;\n  border: 1px solid #ccc;\n}"}'::jsonb,
  'intermediate', true, true,
  9
where not exists (select 1 from lessons where slug = 'html-css-checkpoint-exam');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'html-css-checkpoint-exam'),
  '{"en":"Which HTML5 element is the correct semantic choice for a page''s main navigation links?","de":"Welches HTML5-Element ist die richtige semantische Wahl für die Hauptnavigation einer Seite?"}'::jsonb,
  '{"en":["<div>","<nav>","<span>","<p>"],"de":["<div>","<nav>","<span>","<p>"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'html-css-checkpoint-exam')
);

-- Shift lessons at/after position 23 in "frontend" to make room for "js-checkpoint-exam"
do $$
begin
  if not exists (select 1 from lessons where slug = 'js-checkpoint-exam') then
    update lessons
      set sort_order = sort_order + 1
      where course_id = (select id from courses where slug = 'frontend')
        and sort_order >= 23;
  end if;
end $$;

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'js-checkpoint-exam',
  '{"en":"Checkpoint: JavaScript Fundamentals","de":"Zwischenprüfung: JavaScript-Grundlagen"}'::jsonb,
  '[{"step":1,"text":{"en":"You''ve learned variables, conditions, loops, and functions — the core building blocks of any program.","de":"Du hast Variablen, Bedingungen, Schleifen und Funktionen gelernt — die Grundbausteine jedes Programms."}},{"step":2,"text":{"en":"Write a function that takes a number and returns whether it''s even or odd, then loop from 1 to 10 and log the result for each number.","de":"Schreibe eine Funktion, die eine Zahl entgegennimmt und zurückgibt, ob sie gerade oder ungerade ist. Durchlaufe dann 1 bis 10 und logge das Ergebnis für jede Zahl."}},{"step":3,"text":{"en":"This checkpoint only uses what you''ve learned so far — no arrays or objects yet, those come right after this.","de":"Diese Zwischenprüfung nutzt nur das, was du bisher gelernt hast — noch keine Arrays oder Objekte, die kommen direkt danach."}}]'::jsonb,
  '{"js":"function evenOrOdd(number) {\n  // return \"even\" or \"odd\"\n}\n\nfor (let i = 1; i <= 10; i++) {\n  console.log(i, evenOrOdd(i));\n}"}'::jsonb,
  'intermediate', false, true,
  23
where not exists (select 1 from lessons where slug = 'js-checkpoint-exam');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'js-checkpoint-exam'),
  '{"en":"What does the % operator do in JavaScript?","de":"Was macht der %-Operator in JavaScript?"}'::jsonb,
  '{"en":["Divides two numbers","Returns the remainder of a division","Multiplies two numbers","Rounds a number"],"de":["Dividiert zwei Zahlen","Gibt den Rest einer Division zurück","Multipliziert zwei Zahlen","Rundet eine Zahl"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'js-checkpoint-exam')
);

-- Shift lessons at/after position 5 in "backend" to make room for "backend-foundations-checkpoint-exam"
do $$
begin
  if not exists (select 1 from lessons where slug = 'backend-foundations-checkpoint-exam') then
    update lessons
      set sort_order = sort_order + 1
      where course_id = (select id from courses where slug = 'backend')
        and sort_order >= 5;
  end if;
end $$;

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-foundations-checkpoint-exam',
  '{"en":"Checkpoint: How the Web Works","de":"Zwischenprüfung: Wie das Web funktioniert"}'::jsonb,
  '[{"step":1,"text":{"en":"Before Express and databases, let''s make sure the fundamentals are solid: what a server is, how requests and responses work, and what Node.js actually is.","de":"Bevor es mit Express und Datenbanken weitergeht, sollten die Grundlagen sitzen: was ein Server ist, wie Anfragen und Antworten funktionieren, und was Node.js eigentlich ist."}},{"step":2,"text":{"en":"Using the same simulated request-handling style from earlier lessons, write a function that returns a different response for the \"/home\" path than for any other path.","de":"Schreibe im gleichen simulierten Stil wie in den vorherigen Lektionen eine Funktion, die für den Pfad „/home\" eine andere Antwort liefert als für jeden anderen Pfad."}},{"step":3,"text":{"en":"This checkpoint uses plain simulated JavaScript, just like the lessons before it — real Express comes right after this.","de":"Diese Zwischenprüfung nutzt einfaches, simuliertes JavaScript, genau wie die Lektionen davor — echtes Express kommt direkt danach."}}]'::jsonb,
  '{"js":"function handleRequest(path) {\n  // return \"Welcome home!\" for \"/home\", otherwise \"Not found\"\n}\n\nconsole.log(handleRequest(\"/home\"));\nconsole.log(handleRequest(\"/about\"));"}'::jsonb,
  'intermediate', true, true,
  5
where not exists (select 1 from lessons where slug = 'backend-foundations-checkpoint-exam');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-foundations-checkpoint-exam'),
  '{"en":"What is the job of a server?","de":"Was ist die Aufgabe eines Servers?"}'::jsonb,
  '{"en":["To render CSS in the browser","To store your keyboard shortcuts","To respond to requests from a browser with data or files","To compile JavaScript into HTML"],"de":["CSS im Browser darzustellen","Tastenkürzel zu speichern","Anfragen eines Browsers mit Daten oder Dateien zu beantworten","JavaScript zu HTML zu kompilieren"]}'::jsonb,
  2,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-foundations-checkpoint-exam')
);

-- Shift lessons at/after position 12 in "backend" to make room for "backend-security-checkpoint-exam"
do $$
begin
  if not exists (select 1 from lessons where slug = 'backend-security-checkpoint-exam') then
    update lessons
      set sort_order = sort_order + 1
      where course_id = (select id from courses where slug = 'backend')
        and sort_order >= 12;
  end if;
end $$;

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-security-checkpoint-exam',
  '{"en":"Checkpoint: Data & Password Security","de":"Zwischenprüfung: Daten & Passwortsicherheit"}'::jsonb,
  '[{"step":1,"text":{"en":"You now know how data is organized in database tables, and why passwords must never be stored in plain text.","de":"Du weißt jetzt, wie Daten in Datenbanktabellen organisiert werden — und warum Passwörter niemals im Klartext gespeichert werden dürfen."}},{"step":2,"text":{"en":"Write a simulated hashPassword(password) function (a simplified stand-in for real hashing) and an isStrongPassword(password) check that requires at least 8 characters.","de":"Schreibe eine simulierte Funktion hashPassword(password) (ein vereinfachter Platzhalter für echtes Hashing) und eine Prüfung isStrongPassword(password), die mindestens 8 Zeichen verlangt."}},{"step":3,"text":{"en":"Real registration flows, sessions, and authentication come next — this checkpoint makes sure the fundamentals are locked in first.","de":"Echte Registrierungsabläufe, Sessions und Authentifizierung kommen als Nächstes — diese Zwischenprüfung stellt sicher, dass die Grundlagen sitzen."}}]'::jsonb,
  '{"js":"function hashPassword(password) {\n  // return a simplified \"hashed\" version of the password\n}\n\nfunction isStrongPassword(password) {\n  // return true if password.length >= 8\n}\n\nconsole.log(hashPassword(\"hunter2\"));\nconsole.log(isStrongPassword(\"hunter2\"));"}'::jsonb,
  'intermediate', false, true,
  12
where not exists (select 1 from lessons where slug = 'backend-security-checkpoint-exam');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-security-checkpoint-exam'),
  '{"en":"Why should passwords never be stored as plain text in a database?","de":"Warum sollten Passwörter niemals im Klartext in einer Datenbank gespeichert werden?"}'::jsonb,
  '{"en":["It takes up more storage space","Anyone with database access could read every user''s password directly","It makes the website slower","Databases don''t support text fields"],"de":["Es verbraucht mehr Speicherplatz","Jeder mit Datenbankzugriff könnte jedes Passwort direkt lesen","Es macht die Website langsamer","Datenbanken unterstützen keine Textfelder"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-security-checkpoint-exam')
);

-- CodePath Academy — React lessons
-- Appends 7 paid-tier Frontend lessons covering React (components, props,
-- state, events, list rendering, and a mini project) right after
-- js-calculator-project (sort_order 28). Run this in the Supabase SQL editor
-- after schema.sql, seed.sql, and checkpoint_exams.sql. Safe to paste more
-- than once — every insert is guarded with "where not exists".
--
-- Generated by gen-react-lessons.js — don't hand-edit, regenerate instead.

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-introduction',
  '{"en":"React: Your First Component","de":"React: Deine erste Komponente"}'::jsonb,
  '[{"step":1,"text":{"en":"React lets you build user interfaces out of small, reusable pieces called components. Instead of writing HTML by hand, a component is a JavaScript function that returns what should appear on screen.","de":"Mit React baust du Benutzeroberflächen aus kleinen, wiederverwendbaren Teilen, sogenannten Komponenten. Statt HTML von Hand zu schreiben, ist eine Komponente eine JavaScript-Funktion, die zurückgibt, was auf dem Bildschirm erscheinen soll."}},{"step":2,"text":{"en":"The code that looks like HTML inside a JavaScript function is called JSX — it gets turned into real HTML for you automatically.","de":"Der Code, der wie HTML aussieht und in einer JavaScript-Funktion steht, heißt JSX — er wird automatisch in echtes HTML umgewandelt."}},{"step":3,"text":{"en":"Change the text inside the <h1> below and press Run to see your first component update.","de":"Ändere den Text im <h1> unten und klicke auf Ausführen, um deine erste Komponente zu aktualisieren."}}]'::jsonb,
  '{"jsx":"function App() {\n  return (\n    <div>\n      <h1>Hello, I''m learning React</h1>\n      <p>This is my first component.</p>\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<App />);"}'::jsonb,
  'beginner', false, false,
  29
where not exists (select 1 from lessons where slug = 'react-introduction');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-introduction'),
  '{"en":"What does a React component return?","de":"Was gibt eine React-Komponente zurück?"}'::jsonb,
  '{"en":["A database connection","JSX describing what should appear on screen","A CSS file","A server response"],"de":["Eine Datenbankverbindung","JSX, das beschreibt, was auf dem Bildschirm erscheinen soll","Eine CSS-Datei","Eine Serverantwort"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-introduction')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-components',
  '{"en":"Components: Breaking the UI into Pieces","de":"Komponenten: Die Oberfläche aufteilen"}'::jsonb,
  '[{"step":1,"text":{"en":"Real apps are built from many small components, not one giant file. A component can use another component just by writing it like an HTML tag.","de":"Echte Apps bestehen aus vielen kleinen Komponenten, nicht aus einer riesigen Datei. Eine Komponente kann eine andere nutzen, indem du sie einfach wie ein HTML-Tag schreibst."}},{"step":2,"text":{"en":"Split your page into a Header component and a Profile component, then use both inside App.","de":"Teile deine Seite in eine Header-Komponente und eine Profile-Komponente auf und nutze beide innerhalb von App."}},{"step":3,"text":{"en":"This is the same \"combine\" idea from earlier lessons — small pieces, reused everywhere.","de":"Das ist dieselbe „Kombinieren\"-Idee aus früheren Lektionen — kleine Teile, überall wiederverwendet."}}]'::jsonb,
  '{"jsx":"function Header() {\n  return <h1>My Portfolio</h1>;\n}\n\nfunction Profile() {\n  return <p>Hi, I''m Ahmed. I''m learning to code.</p>;\n}\n\nfunction App() {\n  return (\n    <div>\n      <Header />\n      <Profile />\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<App />);"}'::jsonb,
  'beginner', false, false,
  30
where not exists (select 1 from lessons where slug = 'react-components');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-components'),
  '{"en":"In React, how do you use one component inside another?","de":"Wie nutzt du in React eine Komponente innerhalb einer anderen?"}'::jsonb,
  '{"en":["Import it as CSS","Write it like an HTML tag, e.g. <Header />","Call it with new Header()","Copy and paste its code"],"de":["Als CSS importieren","Wie ein HTML-Tag schreiben, z. B. <Header />","Mit new Header() aufrufen","Ihren Code kopieren und einfügen"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-components')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-props',
  '{"en":"Props: Passing Data into Components","de":"Props: Daten an Komponenten übergeben"}'::jsonb,
  '[{"step":1,"text":{"en":"Components become reusable when they can receive different data. Props are how you pass data from a parent component into a child component.","de":"Komponenten werden wiederverwendbar, wenn sie unterschiedliche Daten empfangen können. Props sind der Weg, Daten von einer übergeordneten Komponente an eine Kind-Komponente zu übergeben."}},{"step":2,"text":{"en":"Give your Profile component a name prop so it can greet different people without rewriting the component.","de":"Gib deiner Profile-Komponente eine name-Prop, damit sie verschiedene Personen begrüßen kann, ohne die Komponente neu zu schreiben."}},{"step":3,"text":{"en":"Notice App can now render <Profile name=\"Ahmed\" /> and <Profile name=\"Lina\" /> using the exact same component.","de":"App kann jetzt <Profile name=\"Ahmed\" /> und <Profile name=\"Lina\" /> mit genau derselben Komponente rendern."}}]'::jsonb,
  '{"jsx":"function Profile(props) {\n  return <p>Hi, I''m {props.name}. I''m learning to code.</p>;\n}\n\nfunction App() {\n  return (\n    <div>\n      <Profile name=\"Ahmed\" />\n      <Profile name=\"Lina\" />\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<App />);"}'::jsonb,
  'beginner', false, false,
  31
where not exists (select 1 from lessons where slug = 'react-props');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-props'),
  '{"en":"What are props used for in React?","de":"Wofür werden Props in React genutzt?"}'::jsonb,
  '{"en":["Styling a component with CSS","Passing data from a parent component into a child component","Storing data in a database","Running a server"],"de":["Um eine Komponente mit CSS zu stylen","Um Daten von einer übergeordneten an eine Kind-Komponente zu übergeben","Um Daten in einer Datenbank zu speichern","Um einen Server zu betreiben"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-props')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-state',
  '{"en":"State: Components That Remember","de":"State: Komponenten, die sich erinnern"}'::jsonb,
  '[{"step":1,"text":{"en":"Props are data passed in from outside — state is data a component keeps and manages itself, using the useState hook.","de":"Props sind Daten, die von außen übergeben werden — State sind Daten, die eine Komponente selbst verwaltet, mit dem useState-Hook."}},{"step":2,"text":{"en":"useState gives you a value and a function to update it. When you update it, React automatically re-renders the component with the new value.","de":"useState gibt dir einen Wert und eine Funktion, um ihn zu ändern. Wenn du ihn änderst, rendert React die Komponente automatisch mit dem neuen Wert neu."}},{"step":3,"text":{"en":"Click the button below — the count is stored in state, so React redraws the number every time it changes.","de":"Klicke auf den Button unten — die Zahl wird im State gespeichert, React zeichnet sie bei jeder Änderung neu."}}]'::jsonb,
  '{"jsx":"function Counter() {\n  const [count, setCount] = React.useState(0);\n\n  return (\n    <div>\n      <h1>Count: {count}</h1>\n      <button onClick={() => setCount(count + 1)}>Add one</button>\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<Counter />);"}'::jsonb,
  'beginner', false, false,
  32
where not exists (select 1 from lessons where slug = 'react-state');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-state'),
  '{"en":"What does calling setCount(count + 1) do?","de":"Was macht der Aufruf setCount(count + 1)?"}'::jsonb,
  '{"en":["Deletes the counter","Updates the state and tells React to re-render","Sends data to a server","Changes the CSS of the button"],"de":["Löscht den Zähler","Aktualisiert den State und lässt React neu rendern","Sendet Daten an einen Server","Ändert das CSS des Buttons"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-state')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-events',
  '{"en":"Handling User Input","de":"Nutzereingaben verarbeiten"}'::jsonb,
  '[{"step":1,"text":{"en":"Real apps react to what the user does — typing, clicking, submitting. In React, you handle these with event props like onClick and onChange.","de":"Echte Apps reagieren auf das, was Nutzer tun — tippen, klicken, absenden. In React handhabst du das mit Event-Props wie onClick und onChange."}},{"step":2,"text":{"en":"Build a small input box that updates state as the user types, and shows the current value live on the page.","de":"Baue ein kleines Eingabefeld, das den State aktualisiert, während getippt wird, und zeigt den aktuellen Wert live auf der Seite."}},{"step":3,"text":{"en":"This is the same pattern every form in this course will use: state holds the value, an event handler updates it.","de":"Das ist das gleiche Muster, das jedes Formular in diesem Kurs nutzt: State hält den Wert, ein Event-Handler aktualisiert ihn."}}]'::jsonb,
  '{"jsx":"function NameInput() {\n  const [name, setName] = React.useState(\"\");\n\n  return (\n    <div>\n      <input\n        value={name}\n        onChange={(e) => setName(e.target.value)}\n        placeholder=\"Type your name\"\n      />\n      <p>Hello, {name || \"stranger\"}!</p>\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<NameInput />);"}'::jsonb,
  'beginner', false, false,
  33
where not exists (select 1 from lessons where slug = 'react-events');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-events'),
  '{"en":"Which prop do you use to react to text being typed into an <input>?","de":"Welche Prop nutzt du, um auf getippten Text in einem <input> zu reagieren?"}'::jsonb,
  '{"en":["onClick","onType","onChange","onSubmitText"],"de":["onClick","onType","onChange","onSubmitText"]}'::jsonb,
  2,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-events')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-list-rendering',
  '{"en":"Rendering Lists","de":"Listen rendern"}'::jsonb,
  '[{"step":1,"text":{"en":"Apps rarely show just one item — they show lists: posts, products, tasks. In React you use the array''s .map() method to turn data into components.","de":"Apps zeigen selten nur ein Element — sie zeigen Listen: Beiträge, Produkte, Aufgaben. In React nutzt du die Array-Methode .map(), um Daten in Komponenten umzuwandeln."}},{"step":2,"text":{"en":"Every item in a list needs a unique key prop, so React can track which item is which when the list changes.","de":"Jedes Element in einer Liste braucht eine eindeutige key-Prop, damit React nachverfolgen kann, welches Element sich geändert hat, wenn sich die Liste ändert."}},{"step":3,"text":{"en":"Turn the tasks array below into a list of <li> elements using .map().","de":"Verwandle das tasks-Array unten mit .map() in eine Liste von <li>-Elementen."}}]'::jsonb,
  '{"jsx":"function TaskList() {\n  const tasks = [\"Learn HTML\", \"Learn CSS\", \"Learn JavaScript\", \"Learn React\"];\n\n  return (\n    <ul>\n      {tasks.map((task, index) => (\n        <li key={index}>{task}</li>\n      ))}\n    </ul>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<TaskList />);"}'::jsonb,
  'beginner', false, false,
  34
where not exists (select 1 from lessons where slug = 'react-list-rendering');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-list-rendering'),
  '{"en":"Why does each item in a rendered list need a unique key prop?","de":"Warum braucht jedes Element einer gerenderten Liste eine eindeutige key-Prop?"}'::jsonb,
  '{"en":["It makes the text bold","It''s required by CSS","It helps React track which item changed, was added, or removed","It sorts the list alphabetically"],"de":["Es macht den Text fett","CSS verlangt es","Es hilft React nachzuverfolgen, welches Element geändert, hinzugefügt oder entfernt wurde","Es sortiert die Liste alphabetisch"]}'::jsonb,
  2,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-list-rendering')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-mini-project',
  '{"en":"Project: Task Tracker","de":"Projekt: Aufgaben-Tracker"}'::jsonb,
  '[{"step":1,"text":{"en":"Time to combine everything: components, props, state, events, and list rendering — in one small real app.","de":"Zeit, alles zu kombinieren: Komponenten, Props, State, Events und Listen-Rendering — in einer kleinen echten App."}},{"step":2,"text":{"en":"Build a task tracker: an input + button to add a new task, and a list that renders every task using state and .map().","de":"Baue einen Aufgaben-Tracker: ein Eingabefeld mit Button, um eine neue Aufgabe hinzuzufügen, und eine Liste, die jede Aufgabe mit State und .map() rendert."}},{"step":3,"text":{"en":"When it works the way you want, submit it to your portfolio below.","de":"Wenn es so funktioniert, wie du willst, reiche es unten in dein Portfolio ein."}}]'::jsonb,
  '{"jsx":"function TaskTracker() {\n  const [tasks, setTasks] = React.useState([\"Learn React\"]);\n  const [text, setText] = React.useState(\"\");\n\n  function addTask() {\n    if (text.trim() === \"\") return;\n    setTasks([...tasks, text]);\n    setText(\"\");\n  }\n\n  return (\n    <div>\n      <h1>My Tasks</h1>\n      <input value={text} onChange={(e) => setText(e.target.value)} placeholder=\"New task\" />\n      <button onClick={addTask}>Add</button>\n      <ul>\n        {tasks.map((task, index) => (\n          <li key={index}>{task}</li>\n        ))}\n      </ul>\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<TaskTracker />);"}'::jsonb,
  'intermediate', false, true,
  35
where not exists (select 1 from lessons where slug = 'react-mini-project');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-mini-project'),
  '{"en":"In the task tracker, why do we use [...tasks, text] instead of tasks.push(text)?","de":"Warum nutzen wir im Aufgaben-Tracker [...tasks, text] statt tasks.push(text)?"}'::jsonb,
  '{"en":["push() doesn''t exist in JavaScript","React needs a brand new array so it notices the state changed","[...tasks, text] is faster to type","It converts the array to a string"],"de":["push() gibt es in JavaScript nicht","React braucht ein komplett neues Array, um die State-Änderung zu bemerken","[...tasks, text] ist schneller zu tippen","Es wandelt das Array in einen String um"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-mini-project')
);

-- CodePath Academy — React hooks/routing lessons
-- Appends 4 more paid-tier Frontend lessons (useEffect, simulated data
-- fetching, state-based routing, and a capstone mini dashboard project)
-- right after react-mini-project (sort_order 35). Completes the PRD's named
-- React scope: components, props, state, hooks, routing, API. Run this in
-- the Supabase SQL editor after react_lessons.sql. Safe to paste more than
-- once — every insert is guarded with "where not exists".
--
-- Generated by gen-react-hooks-lessons.js — don't hand-edit, regenerate instead.

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-effects',
  '{"en":"Effects: Running Code After Render","de":"Effekte: Code nach dem Rendern ausführen"}'::jsonb,
  '[{"step":1,"text":{"en":"Some things need to happen after a component renders and keep happening on their own — like a clock ticking forward every second. The useEffect hook lets you run this kind of code as a side effect of rendering.","de":"Manche Dinge müssen nach dem Rendern passieren und von selbst weiterlaufen — wie eine Uhr, die jede Sekunde weitertickt. Der useEffect-Hook lässt dich solchen Code als Seiteneffekt des Renderns ausführen."}},{"step":2,"text":{"en":"useEffect takes a function to run, and a dependency array that controls when it re-runs. An empty array [] means \"run once, when the component first appears\" — perfect for starting a timer.","de":"useEffect nimmt eine Funktion, die ausgeführt wird, und ein Abhängigkeits-Array, das steuert, wann sie erneut läuft. Ein leeres Array [] bedeutet „einmal ausführen, wenn die Komponente zum ersten Mal erscheint\" — perfekt, um einen Timer zu starten."}},{"step":3,"text":{"en":"Notice the function returned inside useEffect: it''s a cleanup function React calls when the component is removed, so the timer doesn''t keep running forever.","de":"Beachte die Funktion, die useEffect zurückgibt: Das ist eine Cleanup-Funktion, die React aufruft, wenn die Komponente entfernt wird, damit der Timer nicht für immer weiterläuft."}}]'::jsonb,
  '{"jsx":"function Clock() {\n  const [seconds, setSeconds] = React.useState(0);\n\n  React.useEffect(() => {\n    const timer = setInterval(() => {\n      setSeconds((s) => s + 1);\n    }, 1000);\n    return () => clearInterval(timer);\n  }, []);\n\n  return <h1>Seconds elapsed: {seconds}</h1>;\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<Clock />);"}'::jsonb,
  'intermediate', false, false,
  36
where not exists (select 1 from lessons where slug = 'react-effects');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-effects'),
  '{"en":"Why does useEffect return a function in the clock example?","de":"Warum gibt useEffect im Uhr-Beispiel eine Funktion zurück?"}'::jsonb,
  '{"en":["To make the code run faster","To clean up the timer so it stops when the component is removed","To send data to a server","To style the h1 element"],"de":["Um den Code schneller zu machen","Um den Timer aufzuräumen, damit er stoppt, wenn die Komponente entfernt wird","Um Daten an einen Server zu senden","Um das h1-Element zu stylen"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-effects')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-fetching-data',
  '{"en":"Fetching Data","de":"Daten abrufen"}'::jsonb,
  '[{"step":1,"text":{"en":"Real apps load data from a server instead of hardcoding it. fetchUser() below simulates that with a Promise and a short delay — the same shape as a real fetch() call to an API.","de":"Echte Apps laden Daten von einem Server, statt sie fest einzucodieren. fetchUser() simuliert das unten mit einem Promise und einer kurzen Verzögerung — genau wie ein echter fetch()-Aufruf an eine API."}},{"step":2,"text":{"en":"While the data is loading, the component shows \"Loading...\" — this loading state is a pattern you''ll use in almost every real app.","de":"Während die Daten laden, zeigt die Komponente „Loading...\" — dieses Lade-Muster nutzt du in fast jeder echten App."}},{"step":3,"text":{"en":"Once the promise resolves, setUser and setLoading update state, and React re-renders with the real data.","de":"Sobald das Promise aufgelöst ist, aktualisieren setUser und setLoading den State, und React rendert mit den echten Daten neu."}}]'::jsonb,
  '{"jsx":"function UserProfile() {\n  const [user, setUser] = React.useState(null);\n  const [loading, setLoading] = React.useState(true);\n\n  function fetchUser() {\n    return new Promise((resolve) => {\n      setTimeout(() => resolve({ name: \"Ahmed\", role: \"Student\" }), 1000);\n    });\n  }\n\n  React.useEffect(() => {\n    fetchUser().then((data) => {\n      setUser(data);\n      setLoading(false);\n    });\n  }, []);\n\n  if (loading) return <p>Loading...</p>;\n\n  return (\n    <div>\n      <h1>{user.name}</h1>\n      <p>{user.role}</p>\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<UserProfile />);"}'::jsonb,
  'intermediate', false, false,
  37
where not exists (select 1 from lessons where slug = 'react-fetching-data');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-fetching-data'),
  '{"en":"Why does the component check loading before rendering the user''s data?","de":"Warum prüft die Komponente loading, bevor sie die Nutzerdaten anzeigt?"}'::jsonb,
  '{"en":["Because user is not available yet while the data is being fetched","Because loading is required by React","To make the component run faster","Because fetch() cannot be used with useState"],"de":["Weil user während des Ladens noch nicht verfügbar ist","Weil loading von React verlangt wird","Um die Komponente schneller zu machen","Weil fetch() nicht mit useState genutzt werden kann"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-fetching-data')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-routing-basics',
  '{"en":"Routing: Multiple Pages in One App","de":"Routing: Mehrere Seiten in einer App"}'::jsonb,
  '[{"step":1,"text":{"en":"Real apps have multiple pages — Home, About, Profile. In a full setup you''d use a router library, but the core idea is simple: keep track of which \"page\" is active in state, and render different content for each.","de":"Echte Apps haben mehrere Seiten — Home, About, Profil. In einem vollständigen Setup würdest du eine Router-Bibliothek nutzen, aber die Grundidee ist einfach: merke dir im State, welche „Seite\" gerade aktiv ist, und rendere für jede unterschiedlichen Inhalt."}},{"step":2,"text":{"en":"This simulated router shows how real routing works underneath: one variable decides what''s on screen, and clicking a link just changes that variable.","de":"Dieser simulierte Router zeigt, wie echtes Routing im Kern funktioniert: eine Variable entscheidet, was auf dem Bildschirm ist, und ein Klick auf einen Link ändert einfach diese Variable."}},{"step":3,"text":{"en":"Try switching between Home and About using the buttons below.","de":"Probiere, mit den Buttons unten zwischen Home und About zu wechseln."}}]'::jsonb,
  '{"jsx":"function App() {\n  const [page, setPage] = React.useState(\"home\");\n\n  return (\n    <div>\n      <nav>\n        <button onClick={() => setPage(\"home\")}>Home</button>\n        <button onClick={() => setPage(\"about\")}>About</button>\n      </nav>\n      {page === \"home\" && <h1>Welcome home!</h1>}\n      {page === \"about\" && <h1>About this app</h1>}\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<App />);"}'::jsonb,
  'intermediate', false, false,
  38
where not exists (select 1 from lessons where slug = 'react-routing-basics');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-routing-basics'),
  '{"en":"In this simplified router, what actually decides which page is shown?","de":"Was entscheidet in diesem vereinfachten Router tatsächlich, welche Seite angezeigt wird?"}'::jsonb,
  '{"en":["The browser''s URL bar","A piece of state that tracks the current page","A separate HTML file for each page","The order of the buttons"],"de":["Die URL-Leiste des Browsers","Ein Stück State, das die aktuelle Seite verfolgt","Eine separate HTML-Datei pro Seite","Die Reihenfolge der Buttons"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-routing-basics')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'react-final-project',
  '{"en":"Project: Mini Dashboard","de":"Projekt: Mini-Dashboard"}'::jsonb,
  '[{"step":1,"text":{"en":"Final React project: combine components, props, state, events, lists, effects, simulated data fetching, and simple routing into one small dashboard app.","de":"Letztes React-Projekt: Kombiniere Komponenten, Props, State, Events, Listen, Effekte, simuliertes Datenabrufen und einfaches Routing in einer kleinen Dashboard-App."}},{"step":2,"text":{"en":"Build a two-page app: a Home page showing a loading-then-loaded list of items (simulated fetch), and a Stats page showing a simple count. Use the state-based router pattern from the last lesson.","de":"Baue eine App mit zwei Seiten: eine Home-Seite, die eine erst ladende, dann geladene Liste von Elementen zeigt (simulierter Abruf), und eine Stats-Seite mit einer einfachen Zählung. Nutze das State-basierte Router-Muster aus der letzten Lektion."}},{"step":3,"text":{"en":"When you''re happy with it, submit it to your portfolio.","de":"Wenn du zufrieden bist, reiche es in dein Portfolio ein."}}]'::jsonb,
  '{"jsx":"function Dashboard() {\n  const [page, setPage] = React.useState(\"home\");\n  const [items, setItems] = React.useState([]);\n  const [loading, setLoading] = React.useState(true);\n\n  React.useEffect(() => {\n    setTimeout(() => {\n      setItems([\"Task 1\", \"Task 2\", \"Task 3\"]);\n      setLoading(false);\n    }, 800);\n  }, []);\n\n  return (\n    <div>\n      <nav>\n        <button onClick={() => setPage(\"home\")}>Home</button>\n        <button onClick={() => setPage(\"stats\")}>Stats</button>\n      </nav>\n\n      {page === \"home\" && (\n        <div>\n          <h1>Your Items</h1>\n          {loading ? (\n            <p>Loading...</p>\n          ) : (\n            <ul>\n              {items.map((item, i) => (\n                <li key={i}>{item}</li>\n              ))}\n            </ul>\n          )}\n        </div>\n      )}\n\n      {page === \"stats\" && <h1>You have {items.length} items</h1>}\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(<Dashboard />);"}'::jsonb,
  'advanced', false, true,
  39
where not exists (select 1 from lessons where slug = 'react-final-project');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'react-final-project'),
  '{"en":"What combination of React concepts does this dashboard use?","de":"Welche Kombination von React-Konzepten nutzt dieses Dashboard?"}'::jsonb,
  '{"en":["Only CSS animations","State, effects, simulated fetching, lists, and a state-based router — all together","A real backend server","Only HTML forms"],"de":["Nur CSS-Animationen","State, Effekte, simuliertes Abrufen, Listen und einen State-basierten Router — alles zusammen","Einen echten Backend-Server","Nur HTML-Formulare"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'react-final-project')
);

-- CodePath Academy — deeper Backend lessons
-- Appends 6 more paid-tier Backend lessons (Express middleware, SQL basics,
-- SQL joins, REST API design, a Supabase concept lesson, and a full-stack
-- capstone project) right after backend-paid-exam (sort_order 16). Run this
-- in the Supabase SQL editor after checkpoint_exams.sql. Safe to paste more
-- than once — every insert is guarded with "where not exists".
--
-- Generated by gen-backend-deep-lessons.js — don't hand-edit, regenerate instead.

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-express-middleware',
  '{"en":"Express: Middleware","de":"Express: Middleware"}'::jsonb,
  '[{"step":1,"text":{"en":"Express handles requests through a chain of functions called middleware — each one can inspect or modify the request before passing it along, or stop it entirely.","de":"Express verarbeitet Anfragen durch eine Kette von Funktionen namens Middleware — jede kann die Anfrage prüfen oder verändern, bevor sie weitergereicht wird, oder sie ganz stoppen."}},{"step":2,"text":{"en":"A common use is an auth-guard: middleware that checks if a user is logged in before letting the request continue to the real route handler.","de":"Ein häufiger Einsatz ist ein Auth-Guard: Middleware, die prüft, ob ein Nutzer angemeldet ist, bevor die Anfrage zum eigentlichen Route-Handler weitergeht."}},{"step":3,"text":{"en":"Write a simulated requireAuth(request) middleware that returns an error if request.user is missing, otherwise lets the request through.","de":"Schreibe eine simulierte requireAuth(request)-Middleware, die einen Fehler zurückgibt, wenn request.user fehlt, und die Anfrage sonst durchlässt."}}]'::jsonb,
  '{"js":"function requireAuth(request, next) {\n  if (!request.user) {\n    return { status: 401, body: \"Unauthorized\" };\n  }\n  return next(request);\n}\n\nfunction homeRoute(request) {\n  return { status: 200, body: \"Welcome, \" + request.user };\n}\n\nconsole.log(requireAuth({ user: \"Ahmed\" }, homeRoute));\nconsole.log(requireAuth({}, homeRoute));"}'::jsonb,
  'intermediate', false, false,
  17
where not exists (select 1 from lessons where slug = 'backend-express-middleware');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-express-middleware'),
  '{"en":"What is middleware in Express used for?","de":"Wofür wird Middleware in Express genutzt?"}'::jsonb,
  '{"en":["Styling the frontend","Running code between a request arriving and the route handler responding","Storing files on disk","Compiling JavaScript"],"de":["Um das Frontend zu stylen","Um Code zwischen dem Eintreffen einer Anfrage und der Antwort des Route-Handlers auszuführen","Um Dateien auf der Festplatte zu speichern","Um JavaScript zu kompilieren"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-express-middleware')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-sql-basics',
  '{"en":"SQL: Querying a Database","de":"SQL: Eine Datenbank abfragen"}'::jsonb,
  '[{"step":1,"text":{"en":"SQL (Structured Query Language) is how you ask a database for data. SELECT chooses which columns, FROM chooses the table, and WHERE filters the rows.","de":"SQL (Structured Query Language) ist die Art, wie du eine Datenbank nach Daten fragst. SELECT wählt die Spalten, FROM die Tabelle, und WHERE filtert die Zeilen."}},{"step":2,"text":{"en":"This simulated query() function mimics running SQL against a table of users stored as a plain array — real SQL does the exact same filtering, just against real disk storage.","de":"Diese simulierte query()-Funktion ahmt eine SQL-Abfrage gegen eine users-Tabelle nach, die als einfaches Array gespeichert ist — echtes SQL macht genau dasselbe Filtern, nur gegen echten Speicher."}},{"step":3,"text":{"en":"Change the WHERE condition to find only users older than 20.","de":"Ändere die WHERE-Bedingung, sodass nur Nutzer über 20 gefunden werden."}}]'::jsonb,
  '{"js":"const users = [\n  { name: \"Ahmed\", age: 19 },\n  { name: \"Lina\", age: 22 },\n  { name: \"Sam\", age: 17 },\n];\n\n// Simulates: SELECT name FROM users WHERE age > 18\nfunction query(table, whereFn) {\n  return table.filter(whereFn).map((row) => row.name);\n}\n\nconsole.log(query(users, (user) => user.age > 18));"}'::jsonb,
  'intermediate', false, false,
  18
where not exists (select 1 from lessons where slug = 'backend-sql-basics');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-sql-basics'),
  '{"en":"In SQL, what does the WHERE clause do?","de":"Was macht die WHERE-Klausel in SQL?"}'::jsonb,
  '{"en":["Chooses which table to use","Filters rows based on a condition","Deletes the table","Sorts columns alphabetically"],"de":["Wählt die zu nutzende Tabelle","Filtert Zeilen anhand einer Bedingung","Löscht die Tabelle","Sortiert Spalten alphabetisch"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-sql-basics')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-sql-joins',
  '{"en":"SQL: Joining Tables","de":"SQL: Tabellen verbinden"}'::jsonb,
  '[{"step":1,"text":{"en":"Real data is split across multiple tables — users in one table, their orders in another. A JOIN combines rows from both tables that share a matching id.","de":"Echte Daten sind über mehrere Tabellen verteilt — Nutzer in einer Tabelle, ihre Bestellungen in einer anderen. Ein JOIN verbindet Zeilen aus beiden Tabellen, die eine übereinstimmende id haben."}},{"step":2,"text":{"en":"This simulated join connects each order to its user by matching userId to a user''s id — the same idea as a real SQL JOIN ... ON.","de":"Dieser simulierte Join verbindet jede Bestellung mit ihrem Nutzer, indem userId mit der id eines Nutzers abgeglichen wird — dieselbe Idee wie ein echtes SQL JOIN ... ON."}},{"step":3,"text":{"en":"Run it to see each order paired with the name of the user who placed it.","de":"Führe es aus, um jede Bestellung mit dem Namen des Nutzers zu sehen, der sie aufgegeben hat."}}]'::jsonb,
  '{"js":"const users = [\n  { id: 1, name: \"Ahmed\" },\n  { id: 2, name: \"Lina\" },\n];\n\nconst orders = [\n  { id: 101, userId: 1, item: \"Keyboard\" },\n  { id: 102, userId: 2, item: \"Monitor\" },\n];\n\n// Simulates: SELECT orders.item, users.name FROM orders JOIN users ON orders.userId = users.id\nfunction joinOrdersWithUsers() {\n  return orders.map((order) => {\n    const user = users.find((u) => u.id === order.userId);\n    return { item: order.item, boughtBy: user.name };\n  });\n}\n\nconsole.log(joinOrdersWithUsers());"}'::jsonb,
  'intermediate', false, false,
  19
where not exists (select 1 from lessons where slug = 'backend-sql-joins');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-sql-joins'),
  '{"en":"What does a JOIN let you do in SQL?","de":"Was ermöglicht dir ein JOIN in SQL?"}'::jsonb,
  '{"en":["Delete rows from two tables at once","Combine related rows from two different tables","Create a new database","Style query results"],"de":["Zeilen aus zwei Tabellen gleichzeitig löschen","Zusammengehörige Zeilen aus zwei verschiedenen Tabellen verbinden","Eine neue Datenbank erstellen","Abfrageergebnisse stylen"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-sql-joins')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-rest-api-design',
  '{"en":"Designing a REST API","de":"Eine REST-API entwerfen"}'::jsonb,
  '[{"step":1,"text":{"en":"REST APIs use HTTP methods to mean different actions on the same URL: GET reads, POST creates, PUT updates, DELETE removes.","de":"REST-APIs nutzen HTTP-Methoden, um unterschiedliche Aktionen an derselben URL zu bedeuten: GET liest, POST erstellt, PUT aktualisiert, DELETE entfernt."}},{"step":2,"text":{"en":"Status codes tell the client what happened: 200 OK, 201 Created, 404 Not Found, 401 Unauthorized.","de":"Statuscodes sagen dem Client, was passiert ist: 200 OK, 201 Created, 404 Not Found, 401 Unauthorized."}},{"step":3,"text":{"en":"Write a simulated handleRequest(method, path) for a /tasks endpoint that responds correctly to GET and POST.","de":"Schreibe ein simuliertes handleRequest(method, path) für einen /tasks-Endpunkt, das korrekt auf GET und POST reagiert."}}]'::jsonb,
  '{"js":"function handleRequest(method, path) {\n  if (path === \"/tasks\" && method === \"GET\") {\n    return { status: 200, body: [\"Buy milk\", \"Learn REST\"] };\n  }\n  if (path === \"/tasks\" && method === \"POST\") {\n    return { status: 201, body: \"Task created\" };\n  }\n  return { status: 404, body: \"Not found\" };\n}\n\nconsole.log(handleRequest(\"GET\", \"/tasks\"));\nconsole.log(handleRequest(\"POST\", \"/tasks\"));\nconsole.log(handleRequest(\"DELETE\", \"/tasks\"));"}'::jsonb,
  'intermediate', false, false,
  20
where not exists (select 1 from lessons where slug = 'backend-rest-api-design');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-rest-api-design'),
  '{"en":"Which HTTP method is conventionally used to create a new resource in a REST API?","de":"Welche HTTP-Methode wird üblicherweise genutzt, um eine neue Ressource in einer REST-API zu erstellen?"}'::jsonb,
  '{"en":["GET","POST","DELETE","HEAD"],"de":["GET","POST","DELETE","HEAD"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-rest-api-design')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-supabase-intro',
  '{"en":"Supabase: A Real Backend, Free","de":"Supabase: Ein echtes Backend, kostenlos"}'::jsonb,
  '[{"step":1,"text":{"en":"Everything you''ve simulated — a server, routes, a database, authentication — is exactly what Supabase gives you for real, for free, without managing your own server.","de":"Alles, was du simuliert hast — ein Server, Routen, eine Datenbank, Authentifizierung — ist genau das, was dir Supabase wirklich gibt, kostenlos, ohne einen eigenen Server zu verwalten."}},{"step":2,"text":{"en":"Supabase runs a real PostgreSQL database plus a real auth system, and gives your frontend a JavaScript client to talk to both — this whole platform is actually built on it.","de":"Supabase betreibt eine echte PostgreSQL-Datenbank plus ein echtes Auth-System und gibt deinem Frontend einen JavaScript-Client, um mit beidem zu sprechen — genau darauf ist diese ganze Plattform aufgebaut."}},{"step":3,"text":{"en":"You won''t run real Supabase code inside these lessons, but everything you''ve learned — tables, SQL, auth, sessions — maps directly onto how it works.","de":"Du wirst in diesen Lektionen keinen echten Supabase-Code ausführen, aber alles, was du gelernt hast — Tabellen, SQL, Auth, Sessions — überträgt sich direkt darauf, wie es funktioniert."}}]'::jsonb,
  null,
  'beginner', false, false,
  21
where not exists (select 1 from lessons where slug = 'backend-supabase-intro');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-supabase-intro'),
  '{"en":"What does Supabase provide, based on what you''ve already learned?","de":"Was bietet Supabase, basierend auf dem, was du bereits gelernt hast?"}'::jsonb,
  '{"en":["A real PostgreSQL database and a real auth system","Only a code editor","A way to style websites","A video hosting service"],"de":["Eine echte PostgreSQL-Datenbank und ein echtes Auth-System","Nur einen Code-Editor","Eine Möglichkeit, Websites zu stylen","Einen Video-Hosting-Dienst"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-supabase-intro')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-fullstack-capstone',
  '{"en":"Project: Full-Stack Task Board","de":"Projekt: Full-Stack Aufgabenboard"}'::jsonb,
  '[{"step":1,"text":{"en":"Time to put frontend and backend together the way a real full-stack app works: a UI that calls an API, and an API that talks to a simulated database.","de":"Zeit, Frontend und Backend so zusammenzubringen, wie eine echte Full-Stack-App funktioniert: eine Oberfläche, die eine API aufruft, und eine API, die mit einer simulierten Datenbank spricht."}},{"step":2,"text":{"en":"Build a simulated API (getTasks, addTask) backed by an in-memory array, then a simulated fetch layer that calls it — the same shape as a real frontend calling a real backend.","de":"Baue eine simulierte API (getTasks, addTask), die von einem Array im Speicher unterstützt wird, dann eine simulierte Fetch-Schicht, die sie aufruft — genau wie ein echtes Frontend, das ein echtes Backend aufruft."}},{"step":3,"text":{"en":"This is the same pattern you''ll use with React + a real Express + Supabase backend later — only the network calls are simulated here.","de":"Das ist dasselbe Muster, das du später mit React + einem echten Express + Supabase-Backend nutzt — nur die Netzwerkaufrufe sind hier simuliert."}}]'::jsonb,
  '{"js":"// Simulated database\nlet tasks = [{ id: 1, title: \"Learn full-stack basics\" }];\n\n// Simulated backend API\nfunction api(method, path, body) {\n  if (method === \"GET\" && path === \"/tasks\") {\n    return { status: 200, body: tasks };\n  }\n  if (method === \"POST\" && path === \"/tasks\") {\n    const newTask = { id: tasks.length + 1, title: body.title };\n    tasks.push(newTask);\n    return { status: 201, body: newTask };\n  }\n  return { status: 404, body: \"Not found\" };\n}\n\n// Simulated frontend calling the API\nfunction loadTasks() {\n  return api(\"GET\", \"/tasks\").body;\n}\n\nfunction createTask(title) {\n  return api(\"POST\", \"/tasks\", { title }).body;\n}\n\nconsole.log(loadTasks());\nconsole.log(createTask(\"Build a full-stack project\"));\nconsole.log(loadTasks());"}'::jsonb,
  'advanced', false, true,
  22
where not exists (select 1 from lessons where slug = 'backend-fullstack-capstone');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-fullstack-capstone'),
  '{"en":"In this exercise, what plays the role of a real database?","de":"Was übernimmt in dieser Übung die Rolle einer echten Datenbank?"}'::jsonb,
  '{"en":["The tasks array kept in memory","The console.log statements","The api() function''s method parameter","The HTML page"],"de":["Das tasks-Array, das im Speicher gehalten wird","Die console.log-Anweisungen","Der method-Parameter der api()-Funktion","Die HTML-Seite"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-fullstack-capstone')
);

-- CodePath Academy — Phase 8: real Stripe payments
-- Adds two nullable columns to the existing subscriptions table so it can
-- be linked to a real Stripe customer/subscription. Safe to run more than
-- once ("add column if not exists"), safe on a database that's never seen
-- this file before.

alter table subscriptions add column if not exists stripe_customer_id text;
alter table subscriptions add column if not exists stripe_subscription_id text;

-- Every webhook lookup goes stripe_subscription_id -> user, so this needs
-- to be fast and (once set) unique per subscription.
create unique index if not exists subscriptions_stripe_subscription_id_key
  on subscriptions (stripe_subscription_id)
  where stripe_subscription_id is not null;
-- CodePath Academy — Phase 9: daily streaks + leaderboard
-- New profiles columns (streak tracking) and a security-definer function
-- for a public leaderboard that doesn't expose the full profiles table
-- (email, account_type, etc.) to other students. Safe to run more than
-- once — every statement is idempotent.

alter table profiles add column if not exists current_streak integer not null default 0;
alter table profiles add column if not exists longest_streak integer not null default 0;
alter table profiles add column if not exists last_activity_date date;

-- Exposes only what a leaderboard needs — never email, account_type, or
-- anything else in profiles — so it's safe to let any signed-in student
-- call this, unlike loosening profiles' own SELECT policy would be.
create or replace function public.get_leaderboard(result_limit integer default 20)
returns table(id uuid, name text, xp integer, level integer)
as $$
  select id, name, xp, level
  from public.profiles
  order by xp desc, level desc
  limit result_limit;
$$ language sql security definer stable;

grant execute on function public.get_leaderboard(integer) to authenticated;
-- CodePath Academy — embedded lesson Quick Checks
-- Adds a small multiple-choice "check" to one step of every existing
-- lesson's content (LessonContentBlock.check — see src/lib/supabase/types.ts).
-- Shown inline in the lesson card itself, distinct from the separate
-- end-of-lesson quiz and the separate practice screen. Uses jsonb_set with
-- an existence guard, so safe to paste more than once.
--
-- Generated by gen-quick-checks.js — don't hand-edit, regenerate instead.

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What is a computer program, at its core?","de":"Was ist ein Computerprogramm im Kern?"},"choices":{"en":["A random collection of files","A set of exact instructions run one after another","A picture of what an app should look like"],"de":["Eine zufällige Sammlung von Dateien","Eine Folge exakter Anweisungen, die nacheinander ausgeführt werden","Ein Bild davon, wie eine App aussehen soll"]},"correctIndex":1}'::jsonb, true)
where slug = 'how-programming-works'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does the browser do with the files a server sends back?","de":"Was macht der Browser mit den Dateien, die ein Server zurücksendet?"},"choices":{"en":["Deletes them","Turns them into the page you see","Sends them to another server"],"de":["Löscht sie","Verwandelt sie in die Seite, die du siehst","Sendet sie an einen anderen Server"]},"correctIndex":1}'::jsonb, true)
where slug = 'how-websites-work'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"Which HTML tag creates a paragraph of text?","de":"Welches HTML-Tag erzeugt einen Textabsatz?"},"choices":{"en":["<h1>","<p>","<div>"],"de":["<h1>","<p>","<div>"]},"correctIndex":1}'::jsonb, true)
where slug = 'html-hello-world'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does CSS control?","de":"Was steuert CSS?"},"choices":{"en":["The structure of content","How elements look (color, size, spacing)","What a server sends back"],"de":["Die Struktur des Inhalts","Wie Elemente aussehen (Farbe, Größe, Abstand)","Was ein Server zurücksendet"]},"correctIndex":1}'::jsonb, true)
where slug = 'css-styling-basics'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does a <div> do?","de":"Was macht ein <div>?"},"choices":{"en":["Groups content together","Shows a picture","Sends a network request"],"de":["Gruppiert Inhalte zusammen","Zeigt ein Bild","Sendet eine Netzwerkanfrage"]},"correctIndex":0}'::jsonb, true)
where slug = 'html-css-div-profile-card'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Which tag is meant to hold your navigation links?","de":"Welches Tag ist für deine Navigationslinks gedacht?"},"choices":{"en":["<footer>","<nav>","<section>"],"de":["<footer>","<nav>","<section>"]},"correctIndex":1}'::jsonb, true)
where slug = 'website-structure-nav-footer'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does justify-content control in flexbox?","de":"Was steuert justify-content in Flexbox?"},"choices":{"en":["Text color","Horizontal spacing of flex items","Image size"],"de":["Textfarbe","Horizontalen Abstand der Flex-Elemente","Bildgröße"]},"correctIndex":1}'::jsonb, true)
where slug = 'flexbox-layout-basics'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does <main> mark in a page?","de":"Was markiert <main> auf einer Seite?"},"choices":{"en":["The primary content of the page","The navigation bar","A single image"],"de":["Den primären Inhalt der Seite","Die Navigationsleiste","Ein einzelnes Bild"]},"correctIndex":0}'::jsonb, true)
where slug = 'semantic-html-sections'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Which CSS property controls how bold text looks?","de":"Welche CSS-Eigenschaft steuert, wie fett Text aussieht?"},"choices":{"en":["font-family","font-weight","line-height"],"de":["font-family","font-weight","line-height"]},"correctIndex":1}'::jsonb, true)
where slug = 'typography-basics'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Where is padding, relative to an element''s border?","de":"Wo befindet sich padding relativ zum Rand (border) eines Elements?"},"choices":{"en":["Inside the border","Outside the border","It replaces the border"],"de":["Innerhalb des Rands","Außerhalb des Rands","Es ersetzt den Rand"]},"correctIndex":0}'::jsonb, true)
where slug = 'box-model-deep-dive'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What is a hero section?","de":"Was ist eine Hero-Section?"},"choices":{"en":["The footer of a page","The big eye-catching area at the top of a page","A form for user login"],"de":["Der Footer einer Seite","Der große, auffällige Bereich oben auf einer Seite","Ein Formular für den Nutzer-Login"]},"correctIndex":1}'::jsonb, true)
where slug = 'hero-section'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does a landing page typically combine?","de":"Was kombiniert eine Landingpage typischerweise?"},"choices":{"en":["Only images","Header/nav, hero, content sections, and a footer","Just a single paragraph"],"de":["Nur Bilder","Header/Nav, Hero, Inhaltsbereiche und einen Footer","Nur einen einzelnen Absatz"]},"correctIndex":1}'::jsonb, true)
where slug = 'landing-page-assembly'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does max-width: 100% do for an image?","de":"Was bewirkt max-width: 100% bei einem Bild?"},"choices":{"en":["Makes it always full screen","Stops it from overflowing its container","Removes the image"],"de":["Macht es immer bildschirmfüllend","Verhindert, dass es seinen Container überläuft","Entfernt das Bild"]},"correctIndex":1}'::jsonb, true)
where slug = 'responsive-images'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Which property turns an element into a grid container?","de":"Welche Eigenschaft macht ein Element zu einem Grid-Container?"},"choices":{"en":["display: flex","display: grid","display: block"],"de":["display: flex","display: grid","display: block"]},"correctIndex":1}'::jsonb, true)
where slug = 'css-grid-basics'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does <label> do in a form?","de":"Was macht <label> in einem Formular?"},"choices":{"en":["Collects text input","Describes what an input is for","Submits the form"],"de":["Sammelt Texteingaben","Beschreibt, wofür ein Eingabefeld ist","Sendet das Formular ab"]},"correctIndex":1}'::jsonb, true)
where slug = 'html-forms-basics'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"When does a :hover style apply?","de":"Wann gilt ein :hover-Stil?"},"choices":{"en":["Always","Only while the mouse is over the element","Only after clicking"],"de":["Immer","Nur solange die Maus über dem Element ist","Nur nach einem Klick"]},"correctIndex":1}'::jsonb, true)
where slug = 'buttons-hover-transitions'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Which three things does a complete webpage combine, per this lesson?","de":"Welche drei Dinge kombiniert eine vollständige Webseite laut dieser Lektion?"},"choices":{"en":["Structure, layout, and styling","Only images and text","Only JavaScript logic"],"de":["Struktur, Layout und Styling","Nur Bilder und Text","Nur JavaScript-Logik"]},"correctIndex":0}'::jsonb, true)
where slug = 'complete-webpage-project'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does this exam require, at minimum, besides a header and footer?","de":"Was verlangt diese Prüfung mindestens, außer Header und Footer?"},"choices":{"en":["A hero section and at least two content sections","A working login system","A database connection"],"de":["Eine Hero-Section und mindestens zwei Inhaltsbereiche","Ein funktionierendes Login-System","Eine Datenbankverbindung"]},"correctIndex":0}'::jsonb, true)
where slug = 'frontend-free-exam'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"Which layout tool does this checkpoint ask you to use for the About Me section?","de":"Welches Layout-Werkzeug sollst du laut dieser Zwischenprüfung für den „Über mich\"-Bereich nutzen?"},"choices":{"en":["CSS Grid","Flexbox","Tables"],"de":["CSS Grid","Flexbox","Tabellen"]},"correctIndex":1}'::jsonb, true)
where slug = 'html-css-checkpoint-exam'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does JavaScript add that HTML and CSS can''t?","de":"Was fügt JavaScript hinzu, was HTML und CSS nicht können?"},"choices":{"en":["Structure","Behavior — reacting to what users do","Color and spacing"],"de":["Struktur","Verhalten — reagieren auf das, was Nutzer tun","Farbe und Abstand"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-introduction'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does the let keyword do?","de":"Was macht das Schlüsselwort let?"},"choices":{"en":["Deletes a variable","Creates a variable you can use later","Runs a loop"],"de":["Löscht eine Variable","Erstellt eine Variable, die du später nutzen kannst","Führt eine Schleife aus"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-variables'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does === check?","de":"Was prüft ===?"},"choices":{"en":["If two values are exactly equal","If a variable exists","If a loop should stop"],"de":["Ob zwei Werte exakt gleich sind","Ob eine Variable existiert","Ob eine Schleife stoppen soll"]},"correctIndex":0}'::jsonb, true)
where slug = 'js-conditions'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does a for loop do?","de":"Was macht eine for-Schleife?"},"choices":{"en":["Runs code once","Repeats code a set number of times","Stores a single value"],"de":["Führt Code einmal aus","Wiederholt Code eine festgelegte Anzahl an Malen","Speichert einen einzelnen Wert"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-loops'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What is a function?","de":"Was ist eine Funktion?"},"choices":{"en":["A single stored value","A reusable block of code","A type of loop"],"de":["Ein einzelner gespeicherter Wert","Ein wiederverwendbarer Codeblock","Eine Art Schleife"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-functions'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does an array hold?","de":"Was enthält ein Array?"},"choices":{"en":["A single value","A list of values in order","A function"],"de":["Einen einzelnen Wert","Eine geordnete Liste von Werten","Eine Funktion"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-arrays'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"How does an object organize information?","de":"Wie organisiert ein Objekt Informationen?"},"choices":{"en":["In a numbered list","Using named properties","As plain text"],"de":["In einer nummerierten Liste","Mit benannten Eigenschaften","Als reiner Text"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-objects'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What is the DOM?","de":"Was ist das DOM?"},"choices":{"en":["A CSS file","The browser''s live version of your HTML","A server-side database"],"de":["Eine CSS-Datei","Die lebendige Browser-Version deines HTML","Eine serverseitige Datenbank"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-dom-basics'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"In this project, what does JavaScript do?","de":"Was macht JavaScript in diesem Projekt?"},"choices":{"en":["Creates the button''s shape","Reads what was typed and responds","Colors the background"],"de":["Erstellt die Form des Buttons","Liest das Eingetippte und reagiert darauf","Färbt den Hintergrund"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-name-greeting-project'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Why is Number() needed before adding two input values?","de":"Warum wird Number() benötigt, bevor zwei Eingabewerte addiert werden?"},"choices":{"en":["It''s not needed","Input values are text by default, and Number() converts them for math","It deletes the input"],"de":["Es wird nicht benötigt","Eingabewerte sind standardmäßig Text, Number() wandelt sie für Berechnungen um","Es löscht die Eingabe"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-calculator-project'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Which topics does this checkpoint test?","de":"Welche Themen prüft diese Zwischenprüfung?"},"choices":{"en":["Arrays and objects","Variables, conditions, loops, and functions","React components"],"de":["Arrays und Objekte","Variablen, Bedingungen, Schleifen und Funktionen","React-Komponenten"]},"correctIndex":1}'::jsonb, true)
where slug = 'js-checkpoint-exam'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does a server do with an incoming request?","de":"Was macht ein Server mit einer eingehenden Anfrage?"},"choices":{"en":["Ignores it","Processes it and sends back a response","Deletes the browser''s files"],"de":["Ignoriert sie","Verarbeitet sie und sendet eine Antwort zurück","Löscht die Dateien des Browsers"]},"correctIndex":1}'::jsonb, true)
where slug = 'what-happens-when-you-open-a-website'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What is a server, in simple terms?","de":"Was ist ein Server, einfach erklärt?"},"choices":{"en":["A physical building","A program that waits for requests and sends responses","A type of database"],"de":["Ein physisches Gebäude","Ein Programm, das auf Anfragen wartet und Antworten sendet","Eine Art Datenbank"]},"correctIndex":1}'::jsonb, true)
where slug = 'creating-your-first-server'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"In the request-response pattern, who sends the request?","de":"Wer sendet im Anfrage-Antwort-Muster die Anfrage?"},"choices":{"en":["The backend","The frontend","The database"],"de":["Das Backend","Das Frontend","Die Datenbank"]},"correctIndex":1}'::jsonb, true)
where slug = 'frontend-backend-connection'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does Node.js let you do?","de":"Was ermöglicht dir Node.js?"},"choices":{"en":["Run JavaScript on a server","Write CSS faster","Design a database"],"de":["JavaScript auf einem Server ausführen","Schneller CSS schreiben","Eine Datenbank entwerfen"]},"correctIndex":0}'::jsonb, true)
where slug = 'nodejs-introduction'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does Express help you do?","de":"Wobei hilft dir Express?"},"choices":{"en":["Style a webpage","Define server routes simply","Store passwords in plain text"],"de":["Eine Webseite stylen","Server-Routen einfach definieren","Passwörter im Klartext speichern"]},"correctIndex":1}'::jsonb, true)
where slug = 'express-routes-intro'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What format do most APIs use to send data?","de":"Welches Format nutzen die meisten APIs, um Daten zu senden?"},"choices":{"en":["JSON","CSS","HTML"],"de":["JSON","CSS","HTML"]},"correctIndex":0}'::jsonb, true)
where slug = 'building-an-api-endpoint'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What happens to information without a database?","de":"Was passiert mit Informationen ohne Datenbank?"},"choices":{"en":["It''s automatically backed up","It disappears when the program stops running","It becomes faster to access"],"de":["Sie wird automatisch gesichert","Sie verschwindet, wenn das Programm stoppt","Sie wird schneller zugänglich"]},"correctIndex":1}'::jsonb, true)
where slug = 'why-databases-exist'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What must your router function have, at minimum?","de":"Was muss deine Router-Funktion mindestens haben?"},"choices":{"en":["At least 3 routes","A working database","A CSS stylesheet"],"de":["Mindestens 3 Routen","Eine funktionierende Datenbank","Ein CSS-Stylesheet"]},"correctIndex":0}'::jsonb, true)
where slug = 'backend-free-exam'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does this checkpoint focus on?","de":"Worauf konzentriert sich diese Zwischenprüfung?"},"choices":{"en":["React hooks","Server/request fundamentals and what Node.js is","CSS animations"],"de":["React-Hooks","Server-/Anfrage-Grundlagen und was Node.js ist","CSS-Animationen"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-foundations-checkpoint-exam'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Why does a table row need an id?","de":"Warum braucht eine Tabellenzeile eine id?"},"choices":{"en":["To make it look nicer","To uniquely identify each row","To store passwords"],"de":["Damit es hübscher aussieht","Um jede Zeile eindeutig zu identifizieren","Um Passwörter zu speichern"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-database-tables'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does hashing do to a password?","de":"Was macht Hashing mit einem Passwort?"},"choices":{"en":["Encrypts it reversibly","Scrambles it into a value that can''t be reversed back","Deletes it"],"de":["Verschlüsselt es umkehrbar","Verwandelt es in einen nicht umkehrbaren Wert","Löscht es"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-password-security'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What should happen before accepting new registration data?","de":"Was sollte passieren, bevor neue Registrierungsdaten akzeptiert werden?"},"choices":{"en":["Nothing, just save it","Check that the data is valid","Email the password to the user"],"de":["Nichts, einfach speichern","Prüfen, ob die Daten gültig sind","Das Passwort per E-Mail an den Nutzer senden"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-registration-flow'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What is a session/token used for?","de":"Wofür wird eine Session/ein Token genutzt?"},"choices":{"en":["Styling the login page","Proving who you are on later requests after logging in","Storing images"],"de":["Die Login-Seite zu stylen","Zu belegen, wer du bist, bei späteren Anfragen nach dem Login","Bilder zu speichern"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-sessions-auth'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What should an API return when something goes wrong?","de":"Was sollte eine API zurückgeben, wenn etwas schiefgeht?"},"choices":{"en":["Nothing","A clear status and message","The entire database"],"de":["Nichts","Einen klaren Status und eine Nachricht","Die gesamte Datenbank"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-error-handling'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What must your login() function do?","de":"Was muss deine login()-Funktion tun?"},"choices":{"en":["Delete the user","Issue a token","Change the CSS"],"de":["Den Nutzer löschen","Ein Token ausstellen","Das CSS ändern"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-paid-exam'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Why must passwords never be stored in plain text?","de":"Warum dürfen Passwörter niemals im Klartext gespeichert werden?"},"choices":{"en":["It''s slower","Anyone with database access could read them directly","It uses more storage"],"de":["Es ist langsamer","Jeder mit Datenbankzugriff könnte sie direkt lesen","Es braucht mehr Speicherplatz"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-security-checkpoint-exam'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What are React UIs built out of?","de":"Woraus werden React-Oberflächen gebaut?"},"choices":{"en":["One giant HTML file","Small, reusable components","CSS-only blocks"],"de":["Einer riesigen HTML-Datei","Kleinen, wiederverwendbaren Komponenten","Reinen CSS-Blöcken"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-introduction'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"How do you use one component inside another?","de":"Wie nutzt du eine Komponente innerhalb einer anderen?"},"choices":{"en":["Copy its code","Write it like an HTML tag","Import it as CSS"],"de":["Ihren Code kopieren","Wie ein HTML-Tag schreiben","Als CSS importieren"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-components'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What are props used for?","de":"Wofür werden Props genutzt?"},"choices":{"en":["Styling with CSS","Passing data from a parent to a child component","Storing data in a database"],"de":["Um mit CSS zu stylen","Um Daten von einer übergeordneten an eine Kind-Komponente zu übergeben","Um Daten in einer Datenbank zu speichern"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-props'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does useState give you?","de":"Was gibt dir useState?"},"choices":{"en":["A CSS class","A value and a function to update it","A server route"],"de":["Eine CSS-Klasse","Einen Wert und eine Funktion, um ihn zu ändern","Eine Server-Route"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-state'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Which prop handles a click in React?","de":"Welche Prop behandelt einen Klick in React?"},"choices":{"en":["onHover","onClick","onLoad"],"de":["onHover","onClick","onLoad"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-events'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"Why does each list item need a unique key prop?","de":"Warum braucht jedes Listenelement eine eindeutige key-Prop?"},"choices":{"en":["To make it bold","So React can track which item changed, was added, or removed","To sort it alphabetically"],"de":["Um es fett zu machen","Damit React nachverfolgen kann, was sich geändert, hinzugefügt oder entfernt hat","Um es alphabetisch zu sortieren"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-list-rendering'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Which React concepts does this project combine?","de":"Welche React-Konzepte kombiniert dieses Projekt?"},"choices":{"en":["Only styling","Components, props, state, events, and lists","Only server routing"],"de":["Nur Styling","Komponenten, Props, State, Events und Listen","Nur Server-Routing"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-mini-project'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does useEffect''s dependency array control?","de":"Was steuert das Abhängigkeits-Array von useEffect?"},"choices":{"en":["The component''s color","When the effect re-runs","The HTML structure"],"de":["Die Farbe der Komponente","Wann der Effekt erneut läuft","Die HTML-Struktur"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-effects'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does a loading state let you show while data is being fetched?","de":"Was lässt dich ein Lade-Status anzeigen, während Daten abgerufen werden?"},"choices":{"en":["An error page","A ''Loading...'' message","The final data early"],"de":["Eine Fehlerseite","Eine „Loading...\"-Meldung","Die endgültigen Daten vorzeitig"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-fetching-data'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"In this simplified router, what decides which page is shown?","de":"Was entscheidet in diesem vereinfachten Router, welche Seite angezeigt wird?"},"choices":{"en":["The browser''s URL bar","A piece of state","A CSS file"],"de":["Die URL-Leiste des Browsers","Ein Stück State","Eine CSS-Datei"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-routing-basics'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does the Home page show while data hasn''t loaded yet?","de":"Was zeigt die Home-Seite, solange die Daten noch nicht geladen sind?"},"choices":{"en":["Nothing at all","A loading state","An error message"],"de":["Gar nichts","Einen Lade-Status","Eine Fehlermeldung"]},"correctIndex":1}'::jsonb, true)
where slug = 'react-final-project'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What can middleware do to a request?","de":"Was kann Middleware mit einer Anfrage tun?"},"choices":{"en":["Only delete it","Inspect or modify it before passing it along","Change its CSS"],"de":["Sie nur löschen","Sie prüfen oder verändern, bevor sie weitergereicht wird","Ihr CSS ändern"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-express-middleware'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does WHERE do in SQL?","de":"Was macht WHERE in SQL?"},"choices":{"en":["Chooses the table","Filters rows based on a condition","Chooses which columns to show"],"de":["Wählt die Tabelle aus","Filtert Zeilen anhand einer Bedingung","Wählt die anzuzeigenden Spalten aus"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-sql-basics'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"What does a JOIN do?","de":"Was macht ein JOIN?"},"choices":{"en":["Deletes a table","Combines matching rows from two tables","Creates a new database"],"de":["Löscht eine Tabelle","Verbindet passende Zeilen aus zwei Tabellen","Erstellt eine neue Datenbank"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-sql-joins'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{0,check}', '{"question":{"en":"Which HTTP method is used to read data?","de":"Welche HTTP-Methode wird genutzt, um Daten zu lesen?"},"choices":{"en":["POST","GET","DELETE"],"de":["POST","GET","DELETE"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-rest-api-design'
  and (content -> 0 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"What does Supabase provide?","de":"Was bietet Supabase?"},"choices":{"en":["Only a code editor","A real database and a real auth system","A CSS framework"],"de":["Nur einen Code-Editor","Eine echte Datenbank und ein echtes Auth-System","Ein CSS-Framework"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-supabase-intro'
  and (content -> 1 -> 'check') is null;

update lessons
set content = jsonb_set(content, '{1,check}', '{"question":{"en":"In this capstone, what plays the role of the database?","de":"Was übernimmt in diesem Abschlussprojekt die Rolle der Datenbank?"},"choices":{"en":["The console.log statements","The in-memory array","The HTML page"],"de":["Die console.log-Anweisungen","Das Array im Speicher","Die HTML-Seite"]},"correctIndex":1}'::jsonb, true)
where slug = 'backend-fullstack-capstone'
  and (content -> 1 -> 'check') is null;

-- CodePath Academy — Git & GitHub version control unit
-- Appends 5 more paid-tier Frontend lessons (git-what-is-version-control
-- through git-merge-conflicts-project, sort_order 40-44, right after
-- react-final-project at 39). Git/GitHub was a completely missing topic —
-- every professional developer needs it, and it wasn't taught anywhere in
-- the curriculum before this. There's no real terminal in the sandbox, so
-- every lesson simulates git commands through a plain JS git(command)
-- function that logs realistic output — same "simulate what the sandbox
-- can't really run" pattern already used for Backend/React routing/fetching.
-- Safe to paste more than once — every insert is guarded with "where not exists".
--
-- Generated by gen-git-lessons.js — don't hand-edit, regenerate instead.

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'git-what-is-version-control',
  '{"en":"What Is Version Control?","de":"Was ist Versionskontrolle?"}'::jsonb,
  '[{"step":1,"text":{"en":"Every real project needs a way to track changes over time and undo mistakes safely — that''s what version control does.","de":"Jedes echte Projekt braucht eine Möglichkeit, Änderungen über die Zeit nachzuverfolgen und Fehler sicher rückgängig zu machen — genau das macht Versionskontrolle."}},{"step":2,"text":{"en":"Git is the version control system almost every professional team uses. It saves \"snapshots\" of your project called commits, so you can go back to any point in history.","de":"Git ist das Versionskontrollsystem, das fast jedes professionelle Team nutzt. Es speichert \"Schnappschüsse\" deines Projekts, genannt Commits, sodass du zu jedem Punkt in der Geschichte zurückkehren kannst."}},{"step":3,"text":{"en":"GitHub is a website that hosts your Git repositories online — it''s how you back up your code and how teams collaborate on the same project from different computers.","de":"GitHub ist eine Website, die deine Git-Repositories online hostet — so sicherst du deinen Code und so arbeiten Teams von verschiedenen Computern aus am selben Projekt."}}]'::jsonb,
  null,
  'beginner', false, false,
  40
where not exists (select 1 from lessons where slug = 'git-what-is-version-control');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'git-what-is-version-control'),
  '{"en":"What does Git actually save when you make a commit?","de":"Was speichert Git eigentlich, wenn du einen Commit machst?"}'::jsonb,
  '{"en":["A snapshot of your project at that point in time","A backup of your whole computer","Only the file names, not their contents","A video recording of your screen"],"de":["Einen Schnappschuss deines Projekts zu diesem Zeitpunkt","Ein Backup deines ganzen Computers","Nur die Dateinamen, nicht ihren Inhalt","Eine Videoaufnahme deines Bildschirms"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'git-what-is-version-control')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'git-init-and-commit',
  '{"en":"Saving Your Work: init and commit","de":"Deine Arbeit speichern: init und commit"}'::jsonb,
  '[{"step":1,"text":{"en":"git init turns a folder into a Git repository — from that point on, Git starts watching it for changes.","de":"git init verwandelt einen Ordner in ein Git-Repository — ab diesem Moment beobachtet Git ihn auf Änderungen."}},{"step":2,"text":{"en":"A changed file starts out \"unstaged\". git add <file> tells Git which changes you want to include in your next snapshot.","de":"Eine geänderte Datei ist zunächst \"unstaged\". git add <datei> sagt Git, welche Änderungen in deinen nächsten Schnappschuss sollen."}},{"step":3,"text":{"en":"git commit -m \"message\" saves a permanent snapshot of everything staged, together with a message describing what changed and why.","de":"git commit -m \"nachricht\" speichert einen dauerhaften Schnappschuss von allem Staged, zusammen mit einer Nachricht, die beschreibt, was sich geändert hat und warum."}},{"step":4,"text":{"en":"The starter code simulates real git output in the console. Run it, then try staging and committing a second file yourself.","de":"Der Startcode simuliert echte Git-Ausgaben in der Konsole. Führe ihn aus und versuche dann selbst, eine zweite Datei zu stagen und zu committen."}}]'::jsonb,
  '{"js":"// A tiny simulated Git — logs what a real git command would print.\nlet staged = [];\nlet commits = [];\n\nfunction git(command) {\n  if (command === \"init\") {\n    console.log(\"Initialized empty Git repository\");\n  } else if (command.startsWith(\"add \")) {\n    const file = command.slice(4);\n    staged.push(file);\n    console.log(\"Staged: \" + file);\n  } else if (command.startsWith(\"commit -m \")) {\n    const message = command.slice(11, -1);\n    commits.push({ message, files: staged });\n    console.log(\"[main] \" + message + \" (\" + staged.length + \" file(s))\");\n    staged = [];\n  }\n}\n\ngit(\"init\");\ngit(\"add index.html\");\ngit(''commit -m \"first commit\"'');\n"}'::jsonb,
  'beginner', false, false,
  41
where not exists (select 1 from lessons where slug = 'git-init-and-commit');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'git-init-and-commit'),
  '{"en":"What does git add actually do?","de":"Was macht git add eigentlich?"}'::jsonb,
  '{"en":["Permanently saves the file forever","Marks a change to be included in the next commit","Uploads the file to GitHub","Deletes the file"],"de":["Speichert die Datei dauerhaft für immer","Markiert eine Änderung für den nächsten Commit","Lädt die Datei zu GitHub hoch","Löscht die Datei"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'git-init-and-commit')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'git-branches',
  '{"en":"Branches: Working Without Breaking Things","de":"Branches: Arbeiten, ohne etwas kaputtzumachen"}'::jsonb,
  '[{"step":1,"text":{"en":"A branch is a separate line of work — you can try something new on a branch without touching the working version on main at all.","de":"Ein Branch ist eine eigene Arbeitslinie — du kannst darauf etwas Neues ausprobieren, ohne die funktionierende Version auf main überhaupt zu berühren."}},{"step":2,"text":{"en":"git checkout -b feature-name creates a new branch and switches to it in one step. Any commits you make now only exist on that branch.","de":"git checkout -b feature-name erstellt einen neuen Branch und wechselt in einem Schritt dorthin. Alle Commits, die du jetzt machst, existieren nur auf diesem Branch."}},{"step":3,"text":{"en":"Once the work on your branch is finished and tested, you merge it back into main — combining the two histories into one.","de":"Sobald die Arbeit auf deinem Branch fertig und getestet ist, mergst du sie zurück in main — die beiden Verläufe werden zu einem zusammengeführt."}}]'::jsonb,
  '{"js":"// Simulated branching — tracks which branch is \"checked out\".\nlet currentBranch = \"main\";\nconst branches = [\"main\"];\n\nfunction git(command) {\n  if (command.startsWith(\"checkout -b \")) {\n    const name = command.slice(12);\n    branches.push(name);\n    currentBranch = name;\n    console.log(\"Switched to a new branch ''\" + name + \"''\");\n  } else if (command.startsWith(\"checkout \")) {\n    currentBranch = command.slice(9);\n    console.log(\"Switched to branch ''\" + currentBranch + \"''\");\n  } else if (command === \"branch\") {\n    branches.forEach((b) => console.log((b === currentBranch ? \"* \" : \"  \") + b));\n  }\n}\n\ngit(\"checkout -b feature-navbar\");\ngit(\"branch\");\ngit(\"checkout main\");\n"}'::jsonb,
  'intermediate', false, false,
  42
where not exists (select 1 from lessons where slug = 'git-branches');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'git-branches'),
  '{"en":"Why create a separate branch instead of committing straight to main?","de":"Warum einen eigenen Branch erstellen, statt direkt auf main zu committen?"}'::jsonb,
  '{"en":["It makes Git run faster","So you can experiment without risking the working main version","Branches are required by GitHub","It automatically fixes bugs"],"de":["Es macht Git schneller","Damit du experimentieren kannst, ohne die funktionierende main-Version zu riskieren","Branches sind von GitHub vorgeschrieben","Es behebt automatisch Fehler"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'git-branches')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'git-github-remote',
  '{"en":"GitHub: Pushing Your Code Online","de":"GitHub: Deinen Code online hochladen"}'::jsonb,
  '[{"step":1,"text":{"en":"Your local Git repository only exists on your own computer until you connect it to a remote — usually a repository on GitHub.","de":"Dein lokales Git-Repository existiert nur auf deinem eigenen Computer, bis du es mit einem Remote verbindest — meist einem Repository auf GitHub."}},{"step":2,"text":{"en":"git remote add origin <url> links your local repo to that GitHub repository, under the name \"origin\". git push origin main then uploads your commits to it.","de":"git remote add origin <url> verknüpft dein lokales Repository mit diesem GitHub-Repository unter dem Namen \"origin\". git push origin main lädt dann deine Commits dorthin hoch."}},{"step":3,"text":{"en":"git pull downloads any changes that were pushed since your last pull — by you from another computer, or by a teammate — keeping everyone in sync.","de":"git pull lädt alle Änderungen herunter, die seit deinem letzten pull gepusht wurden — von dir selbst an einem anderen Computer oder von einem Teammitglied — und hält alle synchron."}}]'::jsonb,
  '{"js":"// Simulated remote — no real network call, just realistic log output.\nlet remoteUrl = null;\nlet pushedCommits = 0;\n\nfunction git(command) {\n  if (command.startsWith(\"remote add origin \")) {\n    remoteUrl = command.slice(19);\n    console.log(\"Remote ''origin'' set to \" + remoteUrl);\n  } else if (command === \"push origin main\") {\n    pushedCommits += 3;\n    console.log(\"Enumerating objects... done.\");\n    console.log(\"To \" + remoteUrl);\n    console.log(\"main -> main\");\n  } else if (command === \"pull\") {\n    console.log(\"Already up to date.\");\n  }\n}\n\ngit(\"remote add origin https://github.com/you/project.git\");\ngit(\"push origin main\");\ngit(\"pull\");\n"}'::jsonb,
  'intermediate', false, false,
  43
where not exists (select 1 from lessons where slug = 'git-github-remote');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'git-github-remote'),
  '{"en":"What does git push actually do?","de":"Was macht git push eigentlich?"}'::jsonb,
  '{"en":["Downloads changes from GitHub","Deletes your local commits","Uploads your local commits to the remote repository","Creates a new branch"],"de":["Lädt Änderungen von GitHub herunter","Löscht deine lokalen Commits","Lädt deine lokalen Commits in das Remote-Repository hoch","Erstellt einen neuen Branch"]}'::jsonb,
  2,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'git-github-remote')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'git-merge-conflicts-project',
  '{"en":"Project: Resolve a Merge Conflict","de":"Projekt: Einen Merge-Konflikt lösen"}'::jsonb,
  '[{"step":1,"text":{"en":"When two branches change the same line of the same file differently, Git can''t merge them automatically — this is called a merge conflict.","de":"Wenn zwei Branches dieselbe Zeile derselben Datei unterschiedlich ändern, kann Git sie nicht automatisch zusammenführen — das nennt man einen Merge-Konflikt."}},{"step":2,"text":{"en":"Git marks the conflict directly inside the file using <<<<<<<, =======, and >>>>>>> markers, showing both versions so a human can decide.","de":"Git markiert den Konflikt direkt in der Datei mit den Markierungen <<<<<<<, ======= und >>>>>>> und zeigt beide Versionen, damit ein Mensch entscheiden kann."}},{"step":3,"text":{"en":"To resolve it, you edit the file to keep the version you want (or combine both), delete the conflict markers completely, then git add and git commit the result.","de":"Um ihn zu lösen, bearbeitest du die Datei so, dass die gewünschte Version bleibt (oder kombinierst beide), löschst die Konfliktmarkierungen vollständig und machst dann git add und git commit."}},{"step":4,"text":{"en":"Final project: look at the conflicting versions in the starter code, write your resolved version with no markers left, and submit it.","de":"Abschlussprojekt: Sieh dir die widersprüchlichen Versionen im Startcode an, schreibe deine aufgelöste Version ohne verbleibende Markierungen und reiche sie ein."}}]'::jsonb,
  '{"js":"// Two branches both changed the SAME line of a file differently.\n// Git can''t guess which one is right, so it marks the conflict like this:\nconst fileWithConflict = `\n<h1>Welcome</h1>\n<<<<<<< HEAD\n<p>Version from main</p>\n=======\n<p>Version from feature-hero</p>\n>>>>>>> feature-hero\n`;\n\nconsole.log(fileWithConflict);\n\n// Your task: write the RESOLVED version of the file below (pick one\n// line, combine them, or write something new) with the conflict\n// markers removed, then log it.\nconst resolved = `\n<h1>Welcome</h1>\n<p>TODO: your resolved line here</p>\n`;\n\nconsole.log(\"Resolved:\", resolved);\n"}'::jsonb,
  'advanced', false, true,
  44
where not exists (select 1 from lessons where slug = 'git-merge-conflicts-project');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'git-merge-conflicts-project'),
  '{"en":"What must you do before committing a resolved merge conflict?","de":"Was musst du tun, bevor du einen gelösten Merge-Konflikt committest?"}'::jsonb,
  '{"en":["Nothing, Git resolves it automatically","Delete the whole file","Remove the conflict markers and keep only the final version you want","Create a new branch"],"de":["Nichts, Git löst es automatisch","Die ganze Datei löschen","Die Konfliktmarkierungen entfernen und nur die gewünschte finale Version behalten","Einen neuen Branch erstellen"]}'::jsonb,
  2,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'git-merge-conflicts-project')
);

-- CodePath Academy — TypeScript unit
-- Appends 6 more paid-tier Frontend lessons (ts-what-is-typescript through
-- ts-final-project, sort_order 45-50, right after git-merge-conflicts-project
-- at 44). TypeScript was a completely missing topic despite being used in
-- nearly every real React job today. Requires two small platform additions
-- alongside this content: StarterCode gained a `ts` field and CodeWorkspace
-- gained a "ts" editor tab that Babel Standalone transpiles client-side via
-- the "typescript" preset (same no-build-step technique already used for
-- JSX) — see src/components/learn/CodeWorkspace.tsx. The JSX tab's Babel
-- presets were also widened to "react,typescript" so a lesson can write
-- typed React props directly (ts-typed-react-props), without a separate
-- .tsx language tab. Safe to paste more than once — every insert is
-- guarded with "where not exists".
--
-- Generated by gen-ts-lessons.js — don't hand-edit, regenerate instead.

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'ts-what-is-typescript',
  '{"en":"What Is TypeScript?","de":"Was ist TypeScript?"}'::jsonb,
  '[{"step":1,"text":{"en":"TypeScript is JavaScript with an extra layer on top: types. You write almost the same code you already know, but you can describe what kind of value each variable is meant to hold.","de":"TypeScript ist JavaScript mit einer zusätzlichen Ebene: Typen. Du schreibst fast denselben Code, den du schon kennst, kannst aber beschreiben, welche Art von Wert eine Variable enthalten soll."}},{"step":2,"text":{"en":"The browser can''t run TypeScript directly. A tool (here, Babel) strips the type annotations before running, turning your TypeScript into plain JavaScript underneath.","de":"Der Browser kann TypeScript nicht direkt ausführen. Ein Tool (hier Babel) entfernt die Typangaben vor der Ausführung und macht aus deinem TypeScript darunter reines JavaScript."}},{"step":3,"text":{"en":"The real benefit isn''t at runtime — it''s while you''re writing code. Your type checker catches mistakes immediately, before you ever click Run, instead of you discovering them later as a bug.","de":"Der eigentliche Vorteil liegt nicht zur Laufzeit — sondern beim Schreiben des Codes. Deine Typprüfung erkennt Fehler sofort, bevor du überhaupt auf Ausführen klickst, statt dass du sie später als Bug entdeckst."}}]'::jsonb,
  '{"ts":"// TypeScript adds types on top of JavaScript.\n// This line has a type annotation: \": string\"\nlet greeting: string = \"Hello, TypeScript!\";\nconsole.log(greeting);\n\ngreeting = \"Still a string\";\nconsole.log(greeting);\n"}'::jsonb,
  'beginner', false, false,
  45
where not exists (select 1 from lessons where slug = 'ts-what-is-typescript');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'ts-what-is-typescript'),
  '{"en":"What does TypeScript actually add on top of JavaScript?","de":"Was fügt TypeScript eigentlich zu JavaScript hinzu?"}'::jsonb,
  '{"en":["A completely different language","Optional type annotations that are checked before running","A faster way to run code","A new way to write HTML"],"de":["Eine komplett andere Sprache","Optionale Typangaben, die vor der Ausführung geprüft werden","Eine schnellere Art, Code auszuführen","Eine neue Art, HTML zu schreiben"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'ts-what-is-typescript')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'ts-basic-types',
  '{"en":"Basic Types: string, number, boolean","de":"Grundtypen: string, number, boolean"}'::jsonb,
  '[{"step":1,"text":{"en":"The three most common basic types are string, number, and boolean — matching the three basic kinds of value you already write in plain JavaScript every day.","de":"Die drei häufigsten Grundtypen sind string, number und boolean — sie entsprechen den drei grundlegenden Wertarten, die du schon täglich in reinem JavaScript schreibst."}},{"step":2,"text":{"en":"Function parameters can be typed too: (name: string, age: number). TypeScript refuses to compile if you try to call the function with the wrong kind of value.","de":"Auch Funktionsparameter können typisiert werden: (name: string, age: number). TypeScript verweigert die Kompilierung, wenn du versuchst, die Funktion mit der falschen Art von Wert aufzurufen."}},{"step":3,"text":{"en":"The \": string\" right after the closing parenthesis describes the function''s return type — a promise about what kind of value it hands back to whoever calls it.","de":"Das \": string\" direkt nach der schließenden Klammer beschreibt den Rückgabetyp der Funktion — ein Versprechen, welche Art von Wert sie an den Aufrufer zurückgibt."}}]'::jsonb,
  '{"ts":"let age: number = 25;\nlet studentName: string = \"Ahmed\";\nlet isStudent: boolean = true;\n\nfunction describe(name: string, age: number): string {\n  return name + \" is \" + age + \" years old\";\n}\n\nconsole.log(describe(studentName, age));\nconsole.log(isStudent);\n"}'::jsonb,
  'beginner', false, false,
  46
where not exists (select 1 from lessons where slug = 'ts-basic-types');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'ts-basic-types'),
  '{"en":"In `function add(a: number, b: number): number`, what does the final `: number` describe?","de":"Was beschreibt das letzte `: number` in `function add(a: number, b: number): number`?"}'::jsonb,
  '{"en":["A parameter","The return type of the function","A comment","A variable name"],"de":["Einen Parameter","Den Rückgabetyp der Funktion","Einen Kommentar","Einen Variablennamen"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'ts-basic-types')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'ts-interfaces',
  '{"en":"Interfaces: Describing Object Shapes","de":"Interfaces: Die Form von Objekten beschreiben"}'::jsonb,
  '[{"step":1,"text":{"en":"Real code deals with objects, not just single values. An interface describes the exact shape an object must have — which properties it needs, and what type each one is.","de":"Echter Code arbeitet mit Objekten, nicht nur mit einzelnen Werten. Ein Interface beschreibt die genaue Form, die ein Objekt haben muss — welche Eigenschaften es braucht und welchen Typ jede davon hat."}},{"step":2,"text":{"en":"Once a variable is typed as User, TypeScript checks every place it''s used — passing an object with the wrong shape, or a missing property, is caught immediately.","de":"Sobald eine Variable als User typisiert ist, prüft TypeScript jede Stelle, an der sie verwendet wird — ein Objekt mit falscher Form oder einer fehlenden Eigenschaft wird sofort erkannt."}},{"step":3,"text":{"en":"Interfaces don''t exist at runtime at all — they''re a compile-time-only tool, purely for catching mistakes while you write the code, and disappear completely once Babel strips them.","de":"Interfaces existieren zur Laufzeit überhaupt nicht — sie sind ein reines Compile-Zeit-Werkzeug, nur um Fehler beim Schreiben des Codes zu erkennen, und verschwinden vollständig, sobald Babel sie entfernt."}}]'::jsonb,
  '{"ts":"interface User {\n  name: string;\n  age: number;\n  isPremium: boolean;\n}\n\nfunction greetUser(user: User): string {\n  return \"Welcome, \" + user.name + \"!\";\n}\n\nconst student: User = { name: \"Sara\", age: 22, isPremium: false };\nconsole.log(greetUser(student));\n"}'::jsonb,
  'intermediate', false, false,
  47
where not exists (select 1 from lessons where slug = 'ts-interfaces');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'ts-interfaces'),
  '{"en":"What does an interface describe in TypeScript?","de":"Was beschreibt ein Interface in TypeScript?"}'::jsonb,
  '{"en":["The exact shape (properties and types) an object must have","A CSS layout","A database table","How fast a function runs"],"de":["Die genaue Form (Eigenschaften und Typen), die ein Objekt haben muss","Ein CSS-Layout","Eine Datenbanktabelle","Wie schnell eine Funktion läuft"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'ts-interfaces')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'ts-arrays-and-optional',
  '{"en":"Typed Arrays and Optional Properties","de":"Typisierte Arrays und optionale Eigenschaften"}'::jsonb,
  '[{"step":1,"text":{"en":"number[] means \"an array where every item is a number\". You can use the same pattern for any type at all, like string[] or User[].","de":"number[] bedeutet \"ein Array, in dem jedes Element eine number ist\". Du kannst dasselbe Muster für jeden beliebigen Typ nutzen, wie string[] oder User[]."}},{"step":2,"text":{"en":"Adding a ? after a property name in an interface makes it optional — some objects can include it, others can leave it out, and TypeScript allows both.","de":"Ein ? nach einem Eigenschaftsnamen in einem Interface macht sie optional — manche Objekte können sie enthalten, andere weglassen, und TypeScript erlaubt beides."}},{"step":3,"text":{"en":"Look at the starter code: some lessons have a quizId and some don''t, and TypeScript is fine with that difference specifically because of the ? on that property.","de":"Sieh dir den Startcode an: Manche Lektionen haben eine quizId, manche nicht, und TypeScript akzeptiert diesen Unterschied genau wegen des ? bei dieser Eigenschaft."}}]'::jsonb,
  '{"ts":"const scores: number[] = [90, 85, 77];\n\ninterface Lesson {\n  title: string;\n  minutes: number;\n  quizId?: string; // the \"?\" makes this property optional\n}\n\nconst lessons: Lesson[] = [\n  { title: \"HTML Basics\", minutes: 6 },\n  { title: \"CSS Grid\", minutes: 6, quizId: \"abc123\" },\n];\n\nconsole.log(scores.reduce((sum, s) => sum + s, 0) / scores.length);\nconsole.log(lessons.map((l) => l.title));\n"}'::jsonb,
  'intermediate', false, false,
  48
where not exists (select 1 from lessons where slug = 'ts-arrays-and-optional');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'ts-arrays-and-optional'),
  '{"en":"What does adding `?` after a property name in an interface mean?","de":"Was bedeutet ein `?` nach einem Eigenschaftsnamen in einem Interface?"}'::jsonb,
  '{"en":["The property is required","The property is optional — it may or may not be present","It marks the property as a boolean","It deletes the property"],"de":["Die Eigenschaft ist erforderlich","Die Eigenschaft ist optional — sie kann vorhanden sein oder nicht","Sie markiert die Eigenschaft als boolean","Sie löscht die Eigenschaft"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'ts-arrays-and-optional')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'ts-typed-react-props',
  '{"en":"Typed React Props","de":"Typisierte React-Props"}'::jsonb,
  '[{"step":1,"text":{"en":"React components take props — and in TypeScript you can describe exactly what props a component expects using an interface, the same way you typed plain objects before.","de":"React-Komponenten erhalten Props — und in TypeScript kannst du mit einem Interface genau beschreiben, welche Props eine Komponente erwartet, genauso wie du vorher einfache Objekte typisiert hast."}},{"step":2,"text":{"en":"function Greeting({ name, streak }: GreetingProps) tells TypeScript, your editor, and anyone else reading the code precisely what this component needs to receive.","de":"function Greeting({ name, streak }: GreetingProps) sagt TypeScript, deinem Editor und jedem, der den Code liest, genau, was diese Komponente empfangen muss."}},{"step":3,"text":{"en":"Imagine passing streak=\"seven\" (a string) instead of a number — a real TypeScript setup would flag that as an error immediately, before the app ever runs, not after a confusing bug shows up.","de":"Stell dir vor, du würdest streak=\"seven\" (einen String) statt einer Zahl übergeben — ein echtes TypeScript-Setup würde das sofort als Fehler markieren, bevor die App überhaupt läuft, statt dass später ein verwirrender Bug auftaucht."}}]'::jsonb,
  '{"jsx":"interface GreetingProps {\n  name: string;\n  streak: number;\n}\n\nfunction Greeting({ name, streak }: GreetingProps) {\n  return (\n    <div>\n      <h1>Hello, {name}!</h1>\n      <p>You''re on a {streak}-day streak.</p>\n    </div>\n  );\n}\n\nReactDOM.createRoot(document.getElementById(''root'')).render(\n  <Greeting name=\"Ahmed\" streak={7} />\n);\n"}'::jsonb,
  'intermediate', false, false,
  49
where not exists (select 1 from lessons where slug = 'ts-typed-react-props');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'ts-typed-react-props'),
  '{"en":"Why type a React component''s props with an interface?","de":"Warum sollte man die Props einer React-Komponente mit einem Interface typisieren?"}'::jsonb,
  '{"en":["It makes the component render faster","It documents and checks exactly what props the component expects","It''s required by React itself","It changes the component''s CSS"],"de":["Es lässt die Komponente schneller rendern","Es dokumentiert und prüft genau, welche Props die Komponente erwartet","React selbst verlangt es","Es ändert das CSS der Komponente"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'ts-typed-react-props')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'ts-final-project',
  '{"en":"Project: A Typed Shopping Cart","de":"Projekt: Ein typisierter Warenkorb"}'::jsonb,
  '[{"step":1,"text":{"en":"Final project: combine everything from this unit — interfaces, typed arrays, and typed functions — into one small typed program.","de":"Abschlussprojekt: Kombiniere alles aus dieser Einheit — Interfaces, typisierte Arrays und typisierte Funktionen — zu einem kleinen typisierten Programm."}},{"step":2,"text":{"en":"A CartItem interface describes each item; cartTotal takes a typed array of them and returns a typed total; formatPrice takes a number and returns a formatted string.","de":"Ein CartItem-Interface beschreibt jedes Element; cartTotal nimmt ein typisiertes Array davon entgegen und gibt eine typisierte Summe zurück; formatPrice nimmt eine Zahl und gibt einen formatierten String zurück."}},{"step":3,"text":{"en":"Add your own typed function, applyDiscount(total: number, percent: number): number, that returns the discounted total — then submit the finished file to your portfolio.","de":"Füge deine eigene typisierte Funktion applyDiscount(total: number, percent: number): number hinzu, die den rabattierten Gesamtbetrag zurückgibt — und reiche die fertige Datei dann in dein Portfolio ein."}}]'::jsonb,
  '{"ts":"interface CartItem {\n  name: string;\n  price: number;\n  quantity: number;\n}\n\nfunction cartTotal(items: CartItem[]): number {\n  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);\n}\n\nfunction formatPrice(amount: number): string {\n  return \"\\u20ac\" + amount.toFixed(2);\n}\n\nconst cart: CartItem[] = [\n  { name: \"Course access\", price: 4.99, quantity: 1 },\n  { name: \"Certificate\", price: 0, quantity: 1 },\n];\n\nconsole.log(formatPrice(cartTotal(cart)));\n\n// Your task: add a typed function\n// applyDiscount(total: number, percent: number): number\n// that returns the discounted total, and log the result.\n"}'::jsonb,
  'advanced', false, true,
  50
where not exists (select 1 from lessons where slug = 'ts-final-project');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'ts-final-project'),
  '{"en":"Which combination does this final project bring together?","de":"Welche Kombination bringt dieses Abschlussprojekt zusammen?"}'::jsonb,
  '{"en":["Interfaces, typed arrays, and typed functions","Only CSS Grid layouts","Only React''s useState hook","Backend routing and middleware"],"de":["Interfaces, typisierte Arrays und typisierte Funktionen","Nur CSS-Grid-Layouts","Nur Reacts useState-Hook","Backend-Routing und Middleware"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'ts-final-project')
);

-- CodePath Academy — Automated Testing unit
-- Appends 5 more paid-tier Frontend lessons (testing-why-write-tests
-- through testing-final-project, sort_order 51-55, right after
-- ts-final-project at 50). Third item off the "not a full course yet" gap
-- list. No real test runner (Jest etc.) exists in the sandbox, so every
-- lesson's starter code includes a tiny hand-written test(name, fn) +
-- expect(actual).toBe(expected) harness — a real, working, if minimal,
-- implementation of the same idea bigger tools scale up, not a fake
-- simulation, so students genuinely run tests and see PASS/FAIL. Safe to
-- paste more than once — every insert is guarded with "where not exists".
--
-- Generated by gen-testing-lessons.js — don't hand-edit, regenerate instead.

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'testing-why-write-tests',
  '{"en":"Why Write Automated Tests?","de":"Warum automatisierte Tests schreiben?"}'::jsonb,
  '[{"step":1,"text":{"en":"So far, checking your code meant running it and reading the output yourself. That works for a tiny script, but real projects have hundreds of functions — re-checking everything by hand after every change doesn''t scale.","de":"Bisher hast du deinen Code überprüft, indem du ihn ausgeführt und die Ausgabe selbst gelesen hast. Das funktioniert für ein kleines Skript, aber echte Projekte haben Hunderte von Funktionen — nach jeder Änderung alles von Hand zu prüfen, skaliert nicht."}},{"step":2,"text":{"en":"An automated test is code that checks other code for you: it runs a function, compares the result to what you expected, and tells you PASS or FAIL — automatically, every time, for free.","de":"Ein automatisierter Test ist Code, der anderen Code für dich prüft: Er führt eine Funktion aus, vergleicht das Ergebnis mit dem, was du erwartet hast, und sagt dir automatisch, bei jedem Mal, kostenlos: PASS oder FAIL."}},{"step":3,"text":{"en":"The real payoff shows up later: months from now, when you change addTax and accidentally break it, a test catches that instantly — instead of a real user noticing a wrong price.","de":"Der eigentliche Gewinn zeigt sich später: Wenn du addTax Monate später änderst und dabei versehentlich kaputt machst, erkennt ein Test das sofort — statt dass ein echter Nutzer einen falschen Preis bemerkt."}}]'::jsonb,
  '{"js":"function addTax(price) {\n  return price * 1.19;\n}\n\n// Right now, the only way to check this works is to run it and\n// read the number yourself, every single time you change the code.\nconsole.log(addTax(100));\n"}'::jsonb,
  'beginner', false, false,
  51
where not exists (select 1 from lessons where slug = 'testing-why-write-tests');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'testing-why-write-tests'),
  '{"en":"What is the main problem with only checking code by reading console output yourself?","de":"Was ist das Hauptproblem, wenn man Code nur durch selbst gelesene Konsolenausgaben prüft?"}'::jsonb,
  '{"en":["It''s illegal","It doesn''t scale — you can''t realistically re-check everything by hand after every change","The console can''t show numbers","It only works for CSS"],"de":["Es ist verboten","Es skaliert nicht — man kann nicht realistisch alles von Hand nach jeder Änderung neu prüfen","Die Konsole kann keine Zahlen anzeigen","Es funktioniert nur für CSS"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'testing-why-write-tests')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'testing-your-first-test',
  '{"en":"Your First Test","de":"Dein erster Test"}'::jsonb,
  '[{"step":1,"text":{"en":"The starter code includes a tiny hand-built test harness — a real, working (if small) version of what tools like Jest do at a much bigger scale: an expect() that compares values, and a test() that runs and labels a check.","de":"Der Startcode enthält ein kleines, selbst gebautes Test-Framework — eine echte, wenn auch kleine Version dessen, was Tools wie Jest in viel größerem Maßstab tun: ein expect(), das Werte vergleicht, und ein test(), das eine Prüfung ausführt und benennt."}},{"step":2,"text":{"en":"test(\"description\", () => { ... }) names what you''re checking and runs the function inside it. expect(actual).toBe(expected) is the actual comparison — it logs PASS or FAIL to the console.","de":"test(\"beschreibung\", () => { ... }) benennt, was du prüfst, und führt die Funktion darin aus. expect(actual).toBe(expected) ist der eigentliche Vergleich — er gibt PASS oder FAIL in der Konsole aus."}},{"step":3,"text":{"en":"Add a second test for add(-1, 1) below the first one, run it, and confirm you see PASS for both.","de":"Füge unter dem ersten einen zweiten Test für add(-1, 1) hinzu, führe ihn aus und bestätige, dass du bei beiden PASS siehst."}}]'::jsonb,
  '{"js":"function expect(actual) {\n  return {\n    toBe(expected) {\n      if (actual === expected) {\n        console.log(\"PASS: expected \" + actual + \" to be \" + expected);\n      } else {\n        console.log(\"FAIL: expected \" + expected + \" but got \" + actual);\n      }\n    },\n  };\n}\n\nfunction test(name, fn) {\n  console.log(\"Test: \" + name);\n  fn();\n}\n\nfunction add(a, b) {\n  return a + b;\n}\n\ntest(\"add(2, 3) should be 5\", () => {\n  expect(add(2, 3)).toBe(5);\n});\n\n// Try it: add a second test below for add(-1, 1).\n"}'::jsonb,
  'beginner', false, false,
  52
where not exists (select 1 from lessons where slug = 'testing-your-first-test');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'testing-your-first-test'),
  '{"en":"In `expect(add(2, 3)).toBe(5)`, what is being compared?","de":"Was wird bei `expect(add(2, 3)).toBe(5)` verglichen?"}'::jsonb,
  '{"en":["The result of add(2, 3) against the expected value 5","Two random numbers","The word \"add\" against the word \"toBe\"","Nothing, it just prints text"],"de":["Das Ergebnis von add(2, 3) gegen den erwarteten Wert 5","Zwei zufällige Zahlen","Das Wort \"add\" gegen das Wort \"toBe\"","Nichts, es gibt nur Text aus"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'testing-your-first-test')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'testing-edge-cases',
  '{"en":"Testing Edge Cases, Not Just the Obvious Input","de":"Grenzfälle testen, nicht nur den offensichtlichen Fall"}'::jsonb,
  '[{"step":1,"text":{"en":"It''s tempting to only test the input that obviously works — but real bugs almost always hide in the cases you didn''t think to check: zero, negative numbers, empty lists, missing values.","de":"Es ist verlockend, nur den Fall zu testen, der offensichtlich funktioniert — aber echte Bugs verstecken sich fast immer in den Fällen, an die man nicht gedacht hat: null, negative Zahlen, leere Listen, fehlende Werte."}},{"step":2,"text":{"en":"These are called edge cases — the unusual, boundary, or extreme inputs a function might actually receive in the real world, even if they weren''t what you had in mind while writing it.","de":"Man nennt sie Grenzfälle (edge cases) — die ungewöhnlichen, extremen Eingaben, die eine Funktion in der echten Welt tatsächlich bekommen kann, auch wenn du beim Schreiben nicht daran gedacht hast."}},{"step":3,"text":{"en":"Run the starter code: dividing by zero doesn''t crash in JavaScript, it returns Infinity — a genuinely useful thing to know and confirm with a test, not just assume.","de":"Führe den Startcode aus: Division durch null führt in JavaScript nicht zum Absturz, sondern ergibt Infinity — gut zu wissen und mit einem Test zu bestätigen, statt es nur anzunehmen."}}]'::jsonb,
  '{"js":"function expect(actual) {\n  return {\n    toBe(expected) {\n      if (actual === expected) {\n        console.log(\"PASS: expected \" + actual + \" to be \" + expected);\n      } else {\n        console.log(\"FAIL: expected \" + expected + \" but got \" + actual);\n      }\n    },\n  };\n}\n\nfunction test(name, fn) {\n  console.log(\"Test: \" + name);\n  fn();\n}\n\nfunction divide(a, b) {\n  return a / b;\n}\n\ntest(\"divide(10, 2) should be 5\", () => {\n  expect(divide(10, 2)).toBe(5);\n});\n\n// The \"obvious\" case works. But what about the edge cases?\ntest(\"divide(5, 0) should be Infinity\", () => {\n  expect(divide(5, 0)).toBe(Infinity);\n});\n"}'::jsonb,
  'intermediate', false, false,
  53
where not exists (select 1 from lessons where slug = 'testing-edge-cases');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'testing-edge-cases'),
  '{"en":"Why bother testing edge cases like dividing by zero or an empty list?","de":"Warum sollte man Grenzfälle wie Division durch null oder eine leere Liste testen?"}'::jsonb,
  '{"en":["To make the test file longer","Because real bugs usually hide in unusual inputs, not the obvious happy-path case","Edge cases are required by the browser","It makes the code run faster"],"de":["Um die Testdatei länger zu machen","Weil sich echte Bugs meist in ungewöhnlichen Eingaben verstecken, nicht im offensichtlichen Normalfall","Grenzfälle sind vom Browser vorgeschrieben","Es macht den Code schneller"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'testing-edge-cases')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'testing-catches-a-real-bug',
  '{"en":"Watching a Test Catch a Real Bug","de":"Wie ein Test einen echten Bug findet"}'::jsonb,
  '[{"step":1,"text":{"en":"This is the real loop of test-driven work: run the test, read the FAIL message, fix the code, run again, see PASS. Every professional developer does this dozens of times a day.","de":"Das ist der eigentliche Kreislauf testgetriebener Arbeit: Test ausführen, die FAIL-Meldung lesen, den Code korrigieren, erneut ausführen, PASS sehen. Jeder professionelle Entwickler macht das mehrmals täglich."}},{"step":2,"text":{"en":"Run the starter code as-is first. Read the FAIL message carefully — it tells you exactly what was expected versus what actually happened, which is usually enough to spot the bug.","de":"Führe den Startcode zuerst unverändert aus. Lies die FAIL-Meldung genau — sie sagt dir genau, was erwartet wurde und was tatsächlich passiert ist, was meist reicht, um den Bug zu finden."}},{"step":3,"text":{"en":"isEven currently checks for odd numbers (n % 2 === 1) instead of even ones. Fix the comparison so it correctly returns true for even numbers, then re-run and confirm PASS.","de":"isEven prüft aktuell auf ungerade Zahlen (n % 2 === 1) statt auf gerade. Korrigiere den Vergleich, sodass er für gerade Zahlen korrekt true zurückgibt, führe dann erneut aus und bestätige PASS."}}]'::jsonb,
  '{"js":"function expect(actual) {\n  return {\n    toBe(expected) {\n      if (actual === expected) {\n        console.log(\"PASS: expected \" + actual + \" to be \" + expected);\n      } else {\n        console.log(\"FAIL: expected \" + expected + \" but got \" + actual);\n      }\n    },\n  };\n}\n\nfunction test(name, fn) {\n  console.log(\"Test: \" + name);\n  fn();\n}\n\n// This function has a bug in it.\nfunction isEven(n) {\n  return n % 2 === 1;\n}\n\ntest(\"isEven(4) should be true\", () => {\n  expect(isEven(4)).toBe(true);\n});\n\n// Run it — the test fails, and tells you exactly what went wrong.\n// Fix isEven above so the test passes, then run again.\n"}'::jsonb,
  'intermediate', false, false,
  54
where not exists (select 1 from lessons where slug = 'testing-catches-a-real-bug');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'testing-catches-a-real-bug'),
  '{"en":"What''s the normal workflow when a test fails?","de":"Was ist der normale Ablauf, wenn ein Test fehlschlägt?"}'::jsonb,
  '{"en":["Delete the test so it stops failing","Read the failure message, fix the actual code, then re-run the test","Ignore it and move on","Rewrite the whole file from scratch"],"de":["Den Test löschen, damit er nicht mehr fehlschlägt","Die Fehlermeldung lesen, den eigentlichen Code korrigieren, dann den Test erneut ausführen","Ignorieren und weitermachen","Die ganze Datei neu schreiben"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'testing-catches-a-real-bug')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'testing-final-project',
  '{"en":"Project: Write a Small Test Suite","de":"Projekt: Eine kleine Testsuite schreiben"}'::jsonb,
  '[{"step":1,"text":{"en":"Final project: write a small but real test suite — a set of tests covering more than one function, including at least one edge case, exactly like a professional would before shipping this code.","de":"Abschlussprojekt: Schreibe eine kleine, aber echte Testsuite — mehrere Tests, die mehr als eine Funktion abdecken, inklusive mindestens einem Grenzfall, genau wie ein Profi es vor der Veröffentlichung dieses Codes tun würde."}},{"step":2,"text":{"en":"cartTotal and applyDiscount are the same style of functions from earlier in the course — now you''re testing them instead of just calling them once and eyeballing the result.","de":"cartTotal und applyDiscount sind Funktionen im selben Stil wie zuvor im Kurs — jetzt testest du sie, statt sie nur einmal aufzurufen und das Ergebnis mit dem Auge zu prüfen."}},{"step":3,"text":{"en":"Add at least 3 more tests, including one edge case (an empty cart array, or a 0% discount that should leave the total unchanged), then submit your finished file to your portfolio.","de":"Füge mindestens 3 weitere Tests hinzu, darunter einen Grenzfall (ein leeres Warenkorb-Array oder ein 0%-Rabatt, der die Summe unverändert lassen sollte), und reiche deine fertige Datei dann in dein Portfolio ein."}}]'::jsonb,
  '{"js":"function expect(actual) {\n  return {\n    toBe(expected) {\n      if (actual === expected) {\n        console.log(\"PASS: expected \" + actual + \" to be \" + expected);\n      } else {\n        console.log(\"FAIL: expected \" + expected + \" but got \" + actual);\n      }\n    },\n  };\n}\n\nfunction test(name, fn) {\n  console.log(\"Test: \" + name);\n  fn();\n}\n\nfunction cartTotal(items) {\n  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);\n}\n\nfunction applyDiscount(total, percent) {\n  return total - (total * percent) / 100;\n}\n\n// Example test to get you started:\ntest(\"cartTotal of one item\", () => {\n  expect(cartTotal([{ price: 10, quantity: 2 }])).toBe(20);\n});\n\n// Your task: add at least 3 more tests covering cartTotal and\n// applyDiscount, including at least one edge case (an empty cart,\n// or a 0% discount).\n"}'::jsonb,
  'advanced', false, true,
  55
where not exists (select 1 from lessons where slug = 'testing-final-project');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'testing-final-project'),
  '{"en":"Besides the normal case, what should a good test suite for cartTotal include?","de":"Was sollte eine gute Testsuite für cartTotal neben dem Normalfall enthalten?"}'::jsonb,
  '{"en":["Nothing else, one test is always enough","At least one edge case, like an empty cart","A CSS test","A screenshot"],"de":["Nichts weiter, ein Test reicht immer","Mindestens einen Grenzfall, wie einen leeren Warenkorb","Einen CSS-Test","Einen Screenshot"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'testing-final-project')
);

-- CodePath Academy — Foundation expansion + new Tools & Environment course
-- Adds 3 more free Foundation lessons (sort_order 3-5): what a programming
-- language is, your basic toolkit, and a roadmap explaining Frontend vs
-- Backend vs the new Tools section. Also creates a brand-new 4th course,
-- 'tools' (free, independent from Frontend/Backend like every course
-- already is — computeLessonAccess has zero cross-course dependency),
-- covering VS Code, Git & GitHub, and Cloud & AI assistants — the
-- real-world workflow every developer needs regardless of path.
--
-- The 5 existing Git/GitHub lessons (git-what-is-version-control through
-- git-merge-conflicts-project) are MOVED here from Frontend via UPDATE,
-- not duplicated — they were only ever added there because Tools didn't
-- exist yet. Their lesson_progress rows (lesson_id, not course_id-based)
-- are untouched, so no student progress is lost by the move.
--
-- Generated by gen-foundation-and-tools.js — don't hand-edit, regenerate.

insert into courses (slug, title, description, sort_order) values
  ('tools', '{"en":"Tools & Environment","de":"Werkzeuge & Umgebung"}'::jsonb, '{"en":"VS Code, Git & GitHub, and working with the cloud and AI assistants.","de":"VS Code, Git & GitHub sowie Arbeiten mit der Cloud und KI-Assistenten."}'::jsonb, 4)
on conflict (slug) do nothing;

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'foundation'),
  'foundation-programming-languages',
  '{"en":"What Is a Programming Language?","de":"Was ist eine Programmiersprache?"}'::jsonb,
  '[{"step":1,"text":{"en":"Computers only understand very simple electrical signals. A programming language is a human-readable way to write instructions that eventually get translated down to those signals.","de":"Computer verstehen nur sehr einfache elektrische Signale. Eine Programmiersprache ist eine für Menschen lesbare Art, Anweisungen zu schreiben, die am Ende in diese Signale übersetzt werden."}},{"step":2,"text":{"en":"There isn''t just one programming language — different languages exist for different jobs. This course focuses on the languages that build the web: HTML and CSS for what you see, JavaScript for behavior, and Node.js (still JavaScript) for what runs behind the scenes.","de":"Es gibt nicht nur eine Programmiersprache — verschiedene Sprachen existieren für verschiedene Aufgaben. Dieser Kurs konzentriert sich auf die Sprachen, die das Web bauen: HTML und CSS für das, was du siehst, JavaScript für das Verhalten, und Node.js (weiterhin JavaScript) für das, was im Hintergrund läuft."}},{"step":3,"text":{"en":"You don''t need to learn every language that exists to become a real developer — you need to deeply understand a focused set. That''s exactly what this course teaches, one growing project at a time.","de":"Du musst nicht jede existierende Sprache lernen, um ein echter Entwickler zu werden — du musst eine fokussierte Auswahl tief verstehen. Genau das lehrt dieser Kurs, ein wachsendes Projekt nach dem anderen."}}]'::jsonb,
  null,
  'beginner', true, false,
  3
where not exists (select 1 from lessons where slug = 'foundation-programming-languages');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'foundation-programming-languages'),
  '{"en":"Why do different programming languages exist instead of just one?","de":"Warum gibt es verschiedene Programmiersprachen und nicht nur eine?"}'::jsonb,
  '{"en":["Because computers are broken","Different languages are suited to different jobs and platforms","To make learning to code harder on purpose","Only old computers need multiple languages"],"de":["Weil Computer kaputt sind","Verschiedene Sprachen eignen sich für verschiedene Aufgaben und Plattformen","Um das Programmierenlernen absichtlich schwerer zu machen","Nur alte Computer brauchen mehrere Sprachen"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'foundation-programming-languages')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'foundation'),
  'foundation-your-toolkit',
  '{"en":"Your Toolkit: Editor, Browser, Console","de":"Dein Werkzeugkasten: Editor, Browser, Konsole"}'::jsonb,
  '[{"step":1,"text":{"en":"Every developer works with three basic tools: a code editor (where you write instructions), a browser (where websites actually run), and a console (where you see what''s happening, including errors).","de":"Jeder Entwickler arbeitet mit drei Grundwerkzeugen: einem Code-Editor (wo du Anweisungen schreibst), einem Browser (wo Websites tatsächlich laufen) und einer Konsole (wo du siehst, was passiert, einschließlich Fehler)."}},{"step":2,"text":{"en":"This course''s built-in editor is a simplified version of the real tool most professionals use — Visual Studio Code (VS Code). You''ll learn the real thing properly in the dedicated Tools section later in your roadmap.","de":"Der in diesen Kurs eingebaute Editor ist eine vereinfachte Version des echten Tools, das die meisten Profis nutzen — Visual Studio Code (VS Code). Das echte Tool lernst du später im dedizierten Werkzeuge-Bereich deines Fahrplans richtig kennen."}},{"step":3,"text":{"en":"The console isn''t just for errors — console.log() lets you \"peek inside\" your code while it''s running, which is the single most useful debugging habit you''ll build in this whole course.","de":"Die Konsole ist nicht nur für Fehler da — mit console.log() kannst du \"in deinen Code hineinschauen\", während er läuft. Das ist die nützlichste Debugging-Gewohnheit, die du in diesem ganzen Kurs aufbauen wirst."}}]'::jsonb,
  null,
  'beginner', true, false,
  4
where not exists (select 1 from lessons where slug = 'foundation-your-toolkit');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'foundation-your-toolkit'),
  '{"en":"What is the console mainly used for?","de":"Wofür wird die Konsole hauptsächlich genutzt?"}'::jsonb,
  '{"en":["Seeing what your code is doing while it runs, including errors","Changing the color of your website","Sending emails","Deleting files permanently"],"de":["Zu sehen, was dein Code beim Ausführen macht, inklusive Fehler","Die Farbe deiner Website zu ändern","E-Mails zu versenden","Dateien dauerhaft zu löschen"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'foundation-your-toolkit')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'foundation'),
  'foundation-your-roadmap',
  '{"en":"Your Roadmap: Frontend, Backend & Tools","de":"Dein Fahrplan: Frontend, Backend & Werkzeuge"}'::jsonb,
  '[{"step":1,"text":{"en":"After Foundation, you''ll choose a path. Frontend takes you through HTML, then CSS, then JavaScript, then React — everything a user actually sees and clicks. Backend takes you through servers, Node.js, Express, databases, and authentication — everything running behind the scenes.","de":"Nach Foundation wählst du einen Pfad. Frontend führt dich durch HTML, dann CSS, dann JavaScript, dann React — alles, was ein Nutzer wirklich sieht und anklickt. Backend führt dich durch Server, Node.js, Express, Datenbanken und Authentifizierung — alles, was im Hintergrund läuft."}},{"step":2,"text":{"en":"You don''t have to pick just one. Frontend and Backend are independent paths — you can do either first, switch anytime, or eventually do both, exactly like most real working developers do.","de":"Du musst nicht nur einen wählen. Frontend und Backend sind unabhängige Pfade — du kannst mit einem beliebigen anfangen, jederzeit wechseln oder irgendwann beide machen, genau wie es die meisten echten Entwickler tun."}},{"step":3,"text":{"en":"Alongside both, a separate Tools section teaches the real-world workflow every developer needs regardless of path: your code editor (VS Code), version control (Git & GitHub), and working with the cloud and AI coding assistants.","de":"Neben beiden lehrt ein eigener Werkzeuge-Bereich den echten Arbeitsablauf, den jeder Entwickler unabhängig vom Pfad braucht: dein Code-Editor (VS Code), Versionskontrolle (Git & GitHub) sowie Arbeiten mit der Cloud und KI-Coding-Assistenten."}}]'::jsonb,
  null,
  'beginner', true, false,
  5
where not exists (select 1 from lessons where slug = 'foundation-your-roadmap');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'foundation-your-roadmap'),
  '{"en":"According to your roadmap, do you have to fully finish Frontend before starting Backend?","de":"Musst du laut deinem Fahrplan Frontend komplett abschließen, bevor du mit Backend beginnst?"}'::jsonb,
  '{"en":["Yes, Backend is locked until Frontend is 100% done","No — they''re independent paths, you can do either or both in any order","No, you can only ever do one of them","Yes, but only on weekends"],"de":["Ja, Backend ist gesperrt, bis Frontend zu 100 % fertig ist","Nein — sie sind unabhängige Pfade, du kannst beide in beliebiger Reihenfolge machen","Nein, du kannst nur jemals eines davon machen","Ja, aber nur an Wochenenden"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'foundation-your-roadmap')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'tools'),
  'tools-what-is-vscode',
  '{"en":"Meet VS Code","de":"Lerne VS Code kennen"}'::jsonb,
  '[{"step":1,"text":{"en":"VS Code (Visual Studio Code) is the most widely used code editor among professional developers — free, made by Microsoft, and available on Windows, Mac, and Linux.","de":"VS Code (Visual Studio Code) ist der am weitesten verbreitete Code-Editor unter professionellen Entwicklern — kostenlos, von Microsoft, verfügbar für Windows, Mac und Linux."}},{"step":2,"text":{"en":"It highlights your code by language (syntax highlighting), points out mistakes as you type, and supports thousands of extensions that add extra features on top of the basics.","de":"Er hebt deinen Code je nach Sprache farblich hervor (Syntax-Highlighting), zeigt Fehler schon beim Tippen an und unterstützt Tausende Erweiterungen, die zusätzliche Funktionen hinzufügen."}},{"step":3,"text":{"en":"This platform''s built-in editor deliberately mimics VS Code''s dark theme and file-tab layout — what you''re already used to here will feel immediately familiar the moment you open real VS Code.","de":"Der in diese Plattform eingebaute Editor ahmt bewusst das dunkle Design und die Datei-Tab-Ansicht von VS Code nach — was du hier schon gewohnt bist, wird dir in echtem VS Code sofort vertraut vorkommen."}}]'::jsonb,
  null,
  'beginner', true, false,
  1
where not exists (select 1 from lessons where slug = 'tools-what-is-vscode');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'tools-what-is-vscode'),
  '{"en":"What is VS Code?","de":"Was ist VS Code?"}'::jsonb,
  '{"en":["A web browser","A free, widely used code editor","A programming language","A database"],"de":["Ein Webbrowser","Ein kostenloser, weit verbreiteter Code-Editor","Eine Programmiersprache","Eine Datenbank"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'tools-what-is-vscode')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'tools'),
  'tools-vscode-workflow',
  '{"en":"A Real VS Code Workflow","de":"Ein echter VS Code Workflow"}'::jsonb,
  '[{"step":1,"text":{"en":"In real VS Code, you open a whole project folder, not a single file — the sidebar on the left shows every file in it, and you click between them, exactly like the lesson tabs you''ve already been using on this platform.","de":"In echtem VS Code öffnest du einen ganzen Projektordner, nicht nur eine einzelne Datei — die Seitenleiste links zeigt jede Datei darin, und du klickst zwischen ihnen, genau wie bei den Lektions-Tabs, die du auf dieser Plattform schon nutzt."}},{"step":2,"text":{"en":"The Integrated Terminal (View → Terminal, or Ctrl+`) is a command line built right into the editor — this is exactly where you''ll type the git commands from the next lessons, and later run real servers.","de":"Das integrierte Terminal (Ansicht → Terminal, oder Strg+`) ist eine Befehlszeile direkt im Editor — genau dort wirst du die Git-Befehle der nächsten Lektionen eingeben und später echte Server starten."}},{"step":3,"text":{"en":"Extensions add features VS Code doesn''t have built in by default — for example, an extension can auto-format your code or add a live-reloading preview, similar to what this platform''s editor already does for you automatically.","de":"Erweiterungen fügen Funktionen hinzu, die VS Code nicht standardmäßig eingebaut hat — zum Beispiel kann eine Erweiterung deinen Code automatisch formatieren oder eine Live-Vorschau hinzufügen, ähnlich dem, was der Editor dieser Plattform schon automatisch für dich tut."}}]'::jsonb,
  null,
  'beginner', true, false,
  2
where not exists (select 1 from lessons where slug = 'tools-vscode-workflow');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'tools-vscode-workflow'),
  '{"en":"What does VS Code''s Integrated Terminal let you do?","de":"Was ermöglicht dir das integrierte Terminal von VS Code?"}'::jsonb,
  '{"en":["Change the editor''s color theme only","Run command-line commands, like git, without leaving the editor","Send the code to a printer","Nothing, it''s just decoration"],"de":["Nur das Farbschema des Editors ändern","Befehlszeilenbefehle wie git ausführen, ohne den Editor zu verlassen","Den Code an einen Drucker senden","Nichts, es ist nur Dekoration"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'tools-vscode-workflow')
);

-- Move the 5 existing Git/GitHub lessons from Frontend into Tools.
update lessons set course_id = (select id from courses where slug = 'tools'), sort_order = 3
  where slug = 'git-what-is-version-control';
update lessons set course_id = (select id from courses where slug = 'tools'), sort_order = 4
  where slug = 'git-init-and-commit';
update lessons set course_id = (select id from courses where slug = 'tools'), sort_order = 5
  where slug = 'git-branches';
update lessons set course_id = (select id from courses where slug = 'tools'), sort_order = 6
  where slug = 'git-github-remote';
update lessons set course_id = (select id from courses where slug = 'tools'), sort_order = 7
  where slug = 'git-merge-conflicts-project';

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'tools'),
  'tools-cloud-and-ai',
  '{"en":"The Cloud & AI Coding Assistants","de":"Die Cloud & KI-Coding-Assistenten"}'::jsonb,
  '[{"step":1,"text":{"en":"\"The cloud\" just means someone else''s computer, running your code or storing your data, reachable over the internet. This platform itself runs on cloud services: Vercel hosts the website, Supabase hosts the database.","de":"\"Die Cloud\" bedeutet einfach der Computer einer anderen Person, der deinen Code ausführt oder deine Daten speichert und über das Internet erreichbar ist. Diese Plattform selbst läuft auf Cloud-Diensten: Vercel hostet die Website, Supabase hostet die Datenbank."}},{"step":2,"text":{"en":"AI coding assistants (like GitHub Copilot, ChatGPT, or this platform''s own CodeBuddy AI mentor) can suggest code, explain errors, and answer questions — genuinely useful, but only if you still understand what the code actually does.","de":"KI-Coding-Assistenten (wie GitHub Copilot, ChatGPT oder der eigene CodeBuddy-KI-Mentor dieser Plattform) können Code vorschlagen, Fehler erklären und Fragen beantworten — wirklich nützlich, aber nur, wenn du weiterhin verstehst, was der Code tatsächlich macht."}},{"step":3,"text":{"en":"A good rule while learning: use AI to explain a concept you''re stuck on, or to review code you already wrote yourself — not to skip writing the code in the first place. Blindly pasting code you don''t understand is how bugs, and bad habits, creep in.","de":"Eine gute Regel beim Lernen: Nutze KI, um ein Konzept zu erklären, an dem du hängst, oder um Code zu überprüfen, den du selbst geschrieben hast — nicht, um das Schreiben des Codes von vornherein zu überspringen. Blind Code einzufügen, den du nicht verstehst, ist der Weg zu Bugs und schlechten Gewohnheiten."}}]'::jsonb,
  null,
  'intermediate', true, false,
  8
where not exists (select 1 from lessons where slug = 'tools-cloud-and-ai');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'tools-cloud-and-ai'),
  '{"en":"What''s the recommended way to use AI coding assistants while you''re still learning?","de":"Wie sollte man KI-Coding-Assistenten am besten nutzen, während man noch lernt?"}'::jsonb,
  '{"en":["To explain concepts or review your own code, not to skip writing it yourself","To write 100% of your projects for you","AI assistants should never be used at all","Only to fix CSS colors"],"de":["Um Konzepte zu erklären oder eigenen Code zu überprüfen, nicht um das Schreiben zu überspringen","Um 100 % deiner Projekte für dich zu schreiben","KI-Assistenten sollte man nie benutzen","Nur um CSS-Farben zu korrigieren"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'tools-cloud-and-ai')
);

-- CodePath Academy — Accessibility (a11y) unit
-- Appends 5 more paid-tier Frontend lessons (a11y-why-it-matters through
-- a11y-final-project, sort_order 56-60, right after testing-final-project
-- at 55). Fourth item off the "not a full course yet" gap list. Unlike
-- Git/testing, no simulation is needed at all here — the sandbox already
-- runs real HTML/CSS, so every lesson is genuine, runnable accessible-
-- markup practice: semantic elements, alt text, real form labels, keyboard
-- focus styles, and a final project fixing a deliberately inaccessible
-- page. Safe to paste more than once — every insert is guarded with
-- "where not exists".
--
-- Generated by gen-a11y-lessons.js — don't hand-edit, regenerate instead.

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'a11y-why-it-matters',
  '{"en":"Why Accessibility Matters","de":"Warum Barrierefreiheit wichtig ist"}'::jsonb,
  '[{"step":1,"text":{"en":"Accessibility (often shortened to a11y) means building websites that people with disabilities can actually use — screen reader users, people who navigate by keyboard only, people with low vision, people with limited motor control.","de":"Barrierefreiheit (oft als a11y abgekürzt) bedeutet, Websites so zu bauen, dass Menschen mit Behinderungen sie tatsächlich nutzen können — Screenreader-Nutzer, Menschen, die nur mit der Tastatur navigieren, Menschen mit Sehschwäche, Menschen mit eingeschränkter motorischer Kontrolle."}},{"step":2,"text":{"en":"Run the starter code and look at the preview: the div and the button look identical. But try pressing Tab in a real browser — only the real button can receive keyboard focus and be activated with Enter or Space, for free, with zero extra code.","de":"Führe den Startcode aus und sieh dir die Vorschau an: der div und der button sehen identisch aus. Aber drücke in einem echten Browser Tab — nur der echte Button kann den Tastaturfokus erhalten und mit Enter oder Leertaste ausgelöst werden, kostenlos, ohne zusätzlichen Code."}},{"step":3,"text":{"en":"A screen reader also announces the button as \"Submit, button\" automatically. The div would just be silently read as text — a screen reader user would have no idea it does anything at all. This is the core idea behind the rest of this unit: use the right HTML element, and a lot of accessibility comes for free.","de":"Ein Screenreader kündigt den Button auch automatisch als \"Submit, Schaltfläche\" an. Der div würde nur stumm als Text vorgelesen — ein Screenreader-Nutzer hätte keine Ahnung, dass er überhaupt etwas tut. Das ist die Kernidee dieser ganzen Einheit: das richtige HTML-Element nutzen, dann kommt viel Barrierefreiheit gratis dazu."}}]'::jsonb,
  '{"html":"<!-- Both look like buttons. Only one actually behaves like one. -->\n<div class=\"button-like\">Submit</div>\n<button>Submit</button>\n","css":".button-like, button {\n  background: #34d399;\n  color: white;\n  border: none;\n  padding: 10px 16px;\n  font-size: 14px;\n  border-radius: 8px;\n  cursor: pointer;\n  display: block;\n  margin-bottom: 8px;\n}\n"}'::jsonb,
  'beginner', false, false,
  56
where not exists (select 1 from lessons where slug = 'a11y-why-it-matters');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'a11y-why-it-matters'),
  '{"en":"Why is a real `<button>` better than a `<div>` styled to look like one?","de":"Warum ist ein echter `<button>` besser als ein `<div>`, das wie einer aussieht?"}'::jsonb,
  '{"en":["Buttons render faster","A real button is automatically keyboard-focusable and announced correctly by screen readers","Divs cannot have a background color","There''s no real difference"],"de":["Buttons rendern schneller","Ein echter Button ist automatisch mit der Tastatur fokussierbar und wird von Screenreadern korrekt angekündigt","Divs können keine Hintergrundfarbe haben","Es gibt keinen echten Unterschied"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'a11y-why-it-matters')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'a11y-semantic-html',
  '{"en":"Semantic HTML","de":"Semantisches HTML"}'::jsonb,
  '[{"step":1,"text":{"en":"Tags like header, nav, main, and footer describe what a section of the page actually IS, not just how it looks — this is called semantic HTML, and it''s the foundation everything else in this unit builds on.","de":"Tags wie header, nav, main und footer beschreiben, was ein Abschnitt der Seite tatsächlich IST, nicht nur wie er aussieht — das nennt man semantisches HTML, und es ist die Grundlage, auf der der Rest dieser Einheit aufbaut."}},{"step":2,"text":{"en":"A screen reader user can jump directly to <main> or to the <nav> using keyboard shortcuts, skipping repeated header content — but only if you actually used these tags instead of generic <div>s for everything.","de":"Ein Screenreader-Nutzer kann mit Tastenkürzeln direkt zu <main> oder zu <nav> springen und wiederholten Header-Inhalt überspringen — aber nur, wenn du diese Tags tatsächlich verwendet hast, statt für alles generische <div>s."}},{"step":3,"text":{"en":"A useful rule: reach for a semantic tag (header, nav, main, article, footer, button) whenever one exists for what you''re building, and only fall back to a plain <div> when none of them fit.","de":"Eine nützliche Regel: Greife zu einem semantischen Tag (header, nav, main, article, footer, button), wann immer eines für das passt, was du baust, und nutze ein einfaches <div> nur, wenn keines davon passt."}}]'::jsonb,
  '{"html":"<header>\n  <h1>My Blog</h1>\n  <nav>\n    <a href=\"#\">Home</a>\n    <a href=\"#\">Articles</a>\n  </nav>\n</header>\n\n<main>\n  <h2>Latest Post</h2>\n  <p>Semantic HTML describes the meaning of content, not just its look.</p>\n</main>\n\n<footer>\n  <p>&copy; 2026 My Blog</p>\n</footer>\n","css":"header, main, footer { padding: 16px; }\nnav a { margin-right: 12px; }\n"}'::jsonb,
  'beginner', false, false,
  57
where not exists (select 1 from lessons where slug = 'a11y-semantic-html');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'a11y-semantic-html'),
  '{"en":"What does semantic HTML describe?","de":"Was beschreibt semantisches HTML?"}'::jsonb,
  '{"en":["The color scheme of a page","What a piece of content actually is/means, not just its visual style","How fast a page loads","The programming language used"],"de":["Das Farbschema einer Seite","Was ein Inhalt tatsächlich ist/bedeutet, nicht nur sein visueller Stil","Wie schnell eine Seite lädt","Die verwendete Programmiersprache"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'a11y-semantic-html')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'a11y-alt-text-and-labels',
  '{"en":"Alt Text and Form Labels","de":"Alt-Texte und Formular-Labels"}'::jsonb,
  '[{"step":1,"text":{"en":"Every meaningful <img> needs an alt attribute — a short text description of what the image shows, read aloud by screen readers since they can''t see the picture itself.","de":"Jedes bedeutungsvolle <img> braucht ein alt-Attribut — eine kurze Textbeschreibung dessen, was das Bild zeigt, die von Screenreadern vorgelesen wird, da sie das Bild selbst nicht sehen können."}},{"step":2,"text":{"en":"A placeholder is NOT a label — it disappears the moment you start typing, and many screen readers don''t reliably announce it at all. A real <label for=\"...\"> connected to the input''s id is what actually works.","de":"Ein Placeholder ist KEIN Label — er verschwindet, sobald du zu tippen beginnst, und viele Screenreader kündigen ihn nicht zuverlässig an. Ein echtes <label for=\"...\">, das mit der id des Inputs verbunden ist, funktioniert tatsächlich."}},{"step":3,"text":{"en":"Fix the starter code: add alt=\"...\" describing the image, and wrap the input with a proper <label for=\"email\"> connected via a matching id=\"email\" on the input.","de":"Korrigiere den Startcode: Füge alt=\"...\" mit einer Beschreibung des Bildes hinzu und verbinde den Input mit einem echten <label for=\"email\"> über eine passende id=\"email\" am Input."}}]'::jsonb,
  '{"html":"<!-- This image has no description for someone who can''t see it. -->\n<img src=\"https://placehold.co/200x100\" />\n\n<!-- This input has no label connecting it to its purpose. -->\n<input type=\"email\" placeholder=\"Email\" />\n\n<!-- Fix both above: add an alt attribute, and a real <label>. -->\n","css":""}'::jsonb,
  'beginner', false, false,
  58
where not exists (select 1 from lessons where slug = 'a11y-alt-text-and-labels');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'a11y-alt-text-and-labels'),
  '{"en":"Why isn''t a placeholder attribute a substitute for a real `<label>`?","de":"Warum ist ein placeholder-Attribut kein Ersatz für ein echtes `<label>`?"}'::jsonb,
  '{"en":["Placeholders are only for numbers","It disappears once typing starts and isn''t reliably announced by screen readers","Placeholders make the page slower","There''s no difference at all"],"de":["Placeholder sind nur für Zahlen","Er verschwindet, sobald man tippt, und wird von Screenreadern nicht zuverlässig angekündigt","Placeholder machen die Seite langsamer","Es gibt überhaupt keinen Unterschied"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'a11y-alt-text-and-labels')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'a11y-keyboard-navigation',
  '{"en":"Keyboard Navigation & Focus","de":"Tastaturnavigation & Fokus"}'::jsonb,
  '[{"step":1,"text":{"en":"Many people never use a mouse at all — they Tab between links and buttons, and press Enter or Space to activate whichever one currently has focus.","de":"Viele Menschen nutzen überhaupt keine Maus — sie tabben zwischen Links und Buttons und drücken Enter oder Leertaste, um das gerade fokussierte Element zu aktivieren."}},{"step":2,"text":{"en":":focus-visible lets you style what a keyboard-focused element looks like — a clear outline, like the one in the starter CSS. Removing this with outline: none and nothing to replace it is one of the most common real accessibility bugs.","de":":focus-visible lässt dich gestalten, wie ein per Tastatur fokussiertes Element aussieht — ein klarer Rahmen, wie im Start-CSS. Ihn mit outline: none zu entfernen, ohne Ersatz, ist einer der häufigsten echten Barrierefreiheits-Bugs."}},{"step":3,"text":{"en":"The .fake-clickable div at the bottom can never receive keyboard focus at all — Tab just skips right over it, no matter how clickable it looks. This is the same lesson from earlier in the unit, now seen from the keyboard''s point of view.","de":"Das .fake-clickable-div unten kann niemals den Tastaturfokus erhalten — Tab überspringt es einfach, egal wie klickbar es aussieht. Das ist dieselbe Lektion wie zu Beginn dieser Einheit, jetzt aus der Sicht der Tastatur betrachtet."}}]'::jsonb,
  '{"html":"<a href=\"#\">Link one</a>\n<a href=\"#\">Link two</a>\n<button>A button</button>\n<div class=\"fake-clickable\">Looks clickable, but isn''t keyboard-reachable</div>\n","css":"a, button { display: block; margin: 8px 0; width: fit-content; }\n\n/* Try it: comment this rule out and press Tab in a real browser —\n   notice you completely lose track of where your keyboard focus is. */\na:focus-visible, button:focus-visible {\n  outline: 3px solid #38bdf8;\n  outline-offset: 2px;\n}\n\n.fake-clickable {\n  color: #949eb8;\n  font-style: italic;\n}\n"}'::jsonb,
  'intermediate', false, false,
  59
where not exists (select 1 from lessons where slug = 'a11y-keyboard-navigation');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'a11y-keyboard-navigation'),
  '{"en":"What''s the risk of writing `outline: none` on a focusable element without adding a replacement style?","de":"Was ist das Risiko, bei einem fokussierbaren Element `outline: none` zu setzen, ohne einen Ersatz-Stil hinzuzufügen?"}'::jsonb,
  '{"en":["The page loads slower","Keyboard users lose all visual indication of where their focus is","The element stops being clickable with a mouse","Nothing, it''s purely cosmetic"],"de":["Die Seite lädt langsamer","Tastaturnutzer verlieren jede visuelle Anzeige, wo sich ihr Fokus befindet","Das Element ist mit der Maus nicht mehr klickbar","Nichts, es ist rein kosmetisch"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'a11y-keyboard-navigation')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'frontend'),
  'a11y-final-project',
  '{"en":"Project: Fix an Inaccessible Page","de":"Projekt: Eine unzugängliche Seite reparieren"}'::jsonb,
  '[{"step":1,"text":{"en":"Final project: combine everything from this unit — semantic elements, real labels, alt text, and keyboard focus — to fix a page full of accessibility problems.","de":"Abschlussprojekt: Kombiniere alles aus dieser Einheit — semantische Elemente, echte Labels, Alt-Texte und Tastaturfokus — um eine Seite voller Barrierefreiheits-Probleme zu reparieren."}},{"step":2,"text":{"en":"One new tool for icon-only buttons: aria-label=\"Close\" gives an element an accessible name even when there''s no visible text — essential for the ✕ button here, which has nothing a screen reader could otherwise announce.","de":"Ein neues Werkzeug für Icon-only-Buttons: aria-label=\"Close\" gibt einem Element einen zugänglichen Namen, auch wenn kein sichtbarer Text da ist — essenziell für den ✕-Button hier, der sonst nichts hätte, was ein Screenreader ankündigen könnte."}},{"step":3,"text":{"en":"Rewrite the file: <nav> with real links or buttons instead of the .nav divs, a proper heading tag for \"Contact Us\", a <label> for the name input, alt text on the image, and aria-label on the icon button — then submit it to your portfolio.","de":"Schreibe die Datei um: <nav> mit echten Links oder Buttons statt der .nav-divs, ein echtes Überschriften-Tag für \"Contact Us\", ein <label> für den Namens-Input, Alt-Text beim Bild und aria-label beim Icon-Button — reiche es dann in dein Portfolio ein."}}]'::jsonb,
  '{"html":"<div class=\"nav\">\n  <div>Home</div>\n  <div>About</div>\n</div>\n\n<div class=\"title\">Contact Us</div>\n\n<input placeholder=\"Your name\" />\n\n<div class=\"icon-btn\">✕</div>\n\n<img src=\"https://placehold.co/150x80\" />\n\n<!-- Your task: fix every accessibility problem in this file.\n     Hints: real nav/button/label elements, alt text, and an\n     aria-label on the icon-only close button (it has no visible\n     text, so aria-label is the only way to give it an accessible name). -->\n","css":".nav div, .icon-btn { cursor: pointer; }\n.title { font-size: 22px; font-weight: bold; }\n"}'::jsonb,
  'advanced', false, true,
  60
where not exists (select 1 from lessons where slug = 'a11y-final-project');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'a11y-final-project'),
  '{"en":"Why does the ✕ icon-only close button need `aria-label=\"Close\"`?","de":"Warum braucht der Icon-only-Schließen-Button (✕) `aria-label=\"Close\"`?"}'::jsonb,
  '{"en":["It doesn''t, icons are always accessible on their own","It has no visible text, so aria-label gives screen readers something to announce","aria-label changes the button''s color","It''s only needed on mobile devices"],"de":["Braucht er nicht, Icons sind von selbst immer barrierefrei","Es gibt keinen sichtbaren Text, aria-label gibt Screenreadern etwas zum Ankündigen","aria-label ändert die Farbe des Buttons","Nur auf Mobilgeräten nötig"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'a11y-final-project')
);

-- CodePath Academy — Deployment/DevOps unit (Tools) + deeper Backend unit
-- Two things in one file:
-- 1. 4 more free Tools lessons (devops-what-is-deployment through
--    devops-final-project, sort_order 9-12, appended after tools-cloud-and-ai
--    at 8): what deployment means, environment variables/secrets, CI/CD
--    basics, and a pre-deploy-checklist final project. Leans on this
--    platform's own real Vercel+GitHub setup as the concrete example
--    throughout, continuing tools-cloud-and-ai's pattern.
-- 2. 4 more paid-tier Backend lessons (backend-transactions through
--    backend-deep-final-project, sort_order 23-26, appended after
--    backend-fullstack-capstone at 22): transactions, indexes, API
--    versioning/pagination, and a final project combining all three.
--    Same simulated-array pattern already used throughout Backend (no
--    real database connection exists in the sandbox).
--
-- This closes out every item on the "not a full course yet" gap list.
-- Safe to paste more than once — every insert is guarded with
-- "where not exists".
--
-- Generated by gen-devops-and-backend-deep2.js — don't hand-edit, regenerate.

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'tools'),
  'devops-what-is-deployment',
  '{"en":"What Is Deployment?","de":"Was ist Deployment?"}'::jsonb,
  '[{"step":1,"text":{"en":"Code running on your own computer only you can see. Deployment is the process of putting your code on a server that''s reachable by anyone on the internet — turning \"it works on my machine\" into a real, live website.","de":"Code, der auf deinem eigenen Computer läuft, kann nur von dir gesehen werden. Deployment ist der Vorgang, deinen Code auf einen Server zu bringen, der von jedem im Internet erreichbar ist — aus \"funktioniert auf meinem Rechner\" wird eine echte, live Website."}},{"step":2,"text":{"en":"This platform deploys itself this exact way: the code lives on GitHub, and a hosting service (Vercel) watches that repository and automatically builds and deploys a new live version every time new code is pushed.","de":"Diese Plattform deployt sich selbst genau so: Der Code liegt auf GitHub, und ein Hosting-Dienst (Vercel) beobachtet dieses Repository und baut und deployt automatisch eine neue Live-Version, sobald neuer Code gepusht wird."}},{"step":3,"text":{"en":"\"Production\" is the common name for the live version real users see, as opposed to the version running only on your own machine while you''re building it.","de":"\"Produktion\" (Production) ist der gängige Name für die Live-Version, die echte Nutzer sehen, im Gegensatz zu der Version, die nur auf deinem eigenen Rechner läuft, während du sie baust."}}]'::jsonb,
  null,
  'beginner', true, false,
  9
where not exists (select 1 from lessons where slug = 'devops-what-is-deployment');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'devops-what-is-deployment'),
  '{"en":"What does \"deployment\" mean?","de":"Was bedeutet \"Deployment\"?"}'::jsonb,
  '{"en":["Deleting old code","Putting your code on a server reachable by anyone on the internet","Writing tests","Choosing a color scheme"],"de":["Alten Code löschen","Deinen Code auf einen Server bringen, der von jedem im Internet erreichbar ist","Tests schreiben","Ein Farbschema wählen"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'devops-what-is-deployment')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'tools'),
  'devops-environment-variables',
  '{"en":"Environment Variables & Secrets","de":"Umgebungsvariablen & Geheimnisse"}'::jsonb,
  '[{"step":1,"text":{"en":"An environment variable is a named value the code reads at runtime instead of having hardcoded — this platform''s own Supabase URL and API keys are read this way, from NEXT_PUBLIC_SUPABASE_URL and friends.","de":"Eine Umgebungsvariable ist ein benannter Wert, den der Code zur Laufzeit ausliest, statt ihn fest im Code zu haben — die eigene Supabase-URL und die API-Schlüssel dieser Plattform werden genau so gelesen, aus NEXT_PUBLIC_SUPABASE_URL und ähnlichen."}},{"step":2,"text":{"en":"This solves two real problems at once: the same code can run with different settings in different places (a test database locally, a real one in production), and secret values never end up committed into Git where anyone with repo access could read them.","de":"Das löst zwei echte Probleme gleichzeitig: derselbe Code kann an verschiedenen Orten mit unterschiedlichen Einstellungen laufen (eine Test-Datenbank lokal, eine echte in Produktion), und geheime Werte landen nie in Git, wo jeder mit Repo-Zugriff sie lesen könnte."}},{"step":3,"text":{"en":"That''s exactly why .env.local is listed in .gitignore in a real project — the values live only on your machine and on the hosting service''s dashboard (like Vercel''s environment variables settings), never inside the code itself.","de":"Genau deshalb steht .env.local in einem echten Projekt in der .gitignore — die Werte existieren nur auf deinem Rechner und im Dashboard des Hosting-Dienstes (wie den Umgebungsvariablen-Einstellungen von Vercel), niemals im Code selbst."}}]'::jsonb,
  '{"js":"// Never hardcode real secrets directly in your code, like this:\n// const apiKey = \"sk_live_abc123...\";\n\n// Instead, code reads a secret from the environment at runtime:\nfunction getApiKey(env) {\n  return env.API_KEY;\n}\n\n// Simulating two different environments the same code can run in:\nconst devEnv = { API_KEY: \"dev-test-key\" };\nconst prodEnv = { API_KEY: \"live-secret-key\" };\n\nconsole.log(\"Dev:\", getApiKey(devEnv));\nconsole.log(\"Prod:\", getApiKey(prodEnv));\n"}'::jsonb,
  'beginner', true, false,
  10
where not exists (select 1 from lessons where slug = 'devops-environment-variables');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'devops-environment-variables'),
  '{"en":"Why should real secrets (API keys, passwords) never be hardcoded directly in your source code?","de":"Warum sollten echte Geheimnisse (API-Schlüssel, Passwörter) niemals direkt im Quellcode fest hinterlegt werden?"}'::jsonb,
  '{"en":["It makes the code run slower","Anyone with access to the code/Git history could read and misuse them","JavaScript doesn''t allow it","It''s fine, as long as the code isn''t public"],"de":["Es macht den Code langsamer","Jeder mit Zugriff auf den Code/die Git-Historie könnte sie lesen und missbrauchen","JavaScript erlaubt das nicht","Es ist in Ordnung, solange der Code nicht öffentlich ist"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'devops-environment-variables')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'tools'),
  'devops-ci-cd-basics',
  '{"en":"CI/CD: Automating Build & Deploy","de":"CI/CD: Build & Deploy automatisieren"}'::jsonb,
  '[{"step":1,"text":{"en":"CI (Continuous Integration) means every push automatically runs checks — installing dependencies, running tests, making sure the build succeeds — before anything is considered safe to ship.","de":"CI (Continuous Integration) bedeutet, dass jeder Push automatisch Prüfungen auslöst — Abhängigkeiten installieren, Tests ausführen, sicherstellen, dass der Build gelingt — bevor irgendetwas als sicher zum Ausliefern gilt."}},{"step":2,"text":{"en":"CD (Continuous Deployment) means that once those checks pass, the new version goes live automatically — no manual upload step. This is exactly what happens on this platform: git push, and Vercel builds and deploys by itself.","de":"CD (Continuous Deployment) bedeutet, dass die neue Version automatisch live geht, sobald diese Prüfungen bestanden sind — kein manueller Upload-Schritt. Genau das passiert auf dieser Plattform: git push, und Vercel baut und deployt von selbst."}},{"step":3,"text":{"en":"The real value: if any step fails (like a test breaking), the pipeline stops before broken code ever reaches real users — run the starter code and change one step''s run() to return false to see this in action.","de":"Der eigentliche Wert: Wenn ein Schritt fehlschlägt (z. B. ein kaputter Test), stoppt die Pipeline, bevor kaputter Code echte Nutzer erreicht — führe den Startcode aus und ändere die run()-Funktion eines Schritts auf false, um das in Aktion zu sehen."}}]'::jsonb,
  '{"js":"// A simplified simulation of what a CI/CD pipeline actually does\n// every time code is pushed — this platform''s own Vercel setup runs\n// through exactly these steps for real, automatically.\nfunction deployPipeline(steps) {\n  for (const step of steps) {\n    console.log(\"Running: \" + step.name);\n    if (!step.run()) {\n      console.log(\"FAILED at: \" + step.name + \" \\u2014 deploy stopped.\");\n      return;\n    }\n  }\n  console.log(\"Deployed to production.\");\n}\n\ndeployPipeline([\n  { name: \"install dependencies\", run: () => true },\n  { name: \"run tests\", run: () => true },\n  { name: \"build\", run: () => true },\n  { name: \"deploy\", run: () => true },\n]);\n"}'::jsonb,
  'intermediate', true, false,
  11
where not exists (select 1 from lessons where slug = 'devops-ci-cd-basics');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'devops-ci-cd-basics'),
  '{"en":"What''s the point of running tests automatically as part of a CI/CD pipeline?","de":"Was bringt es, Tests automatisch als Teil einer CI/CD-Pipeline auszuführen?"}'::jsonb,
  '{"en":["To slow down deployment on purpose","To catch broken code before it reaches real users, not after","Tests are required by law","It changes the website''s colors"],"de":["Um das Deployment absichtlich zu verlangsamen","Um kaputten Code zu erkennen, bevor er echte Nutzer erreicht, nicht danach","Tests sind gesetzlich vorgeschrieben","Es ändert die Farben der Website"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'devops-ci-cd-basics')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'tools'),
  'devops-final-project',
  '{"en":"Project: A Pre-Deploy Checklist","de":"Projekt: Eine Pre-Deploy-Checkliste"}'::jsonb,
  '[{"step":1,"text":{"en":"Final project: real teams use a pre-deploy checklist to catch problems before they ship, not after — the same idea as the tests and CI/CD pipeline you just learned, made concrete.","de":"Abschlussprojekt: Echte Teams nutzen eine Pre-Deploy-Checkliste, um Probleme vor dem Ausliefern zu erkennen, nicht danach — dieselbe Idee wie die Tests und die CI/CD-Pipeline, die du gerade gelernt hast, konkret gemacht."}},{"step":2,"text":{"en":"The starter code models a checklist as an array of { name, check() } items, and reports exactly which ones failed — the same shape a real automated deploy gate would use.","de":"Der Startcode modelliert eine Checkliste als Array von { name, check() }-Elementen und meldet genau, welche fehlgeschlagen sind — dieselbe Form, die ein echtes automatisiertes Deploy-Gate nutzen würde."}},{"step":3,"text":{"en":"Add at least 2 more realistic checklist items, then deliberately make one check() return false and confirm the failure output lists exactly the right item — then submit the finished file to your portfolio.","de":"Füge mindestens 2 weitere realistische Checklisten-Punkte hinzu, lass dann absichtlich eine check()-Funktion false zurückgeben und bestätige, dass die Fehlerausgabe genau den richtigen Punkt auflistet — reiche die fertige Datei dann in dein Portfolio ein."}}]'::jsonb,
  '{"js":"const checklist = [\n  { name: \"All tests passing\", check: () => true },\n  { name: \"No secrets hardcoded in source\", check: () => true },\n  { name: \"Environment variables set on host\", check: () => true },\n  { name: \"Build succeeds locally\", check: () => true },\n];\n\nfunction runChecklist(items) {\n  const failed = items.filter((item) => !item.check());\n  if (failed.length === 0) {\n    console.log(\"\\u2705 Ready to deploy.\");\n  } else {\n    console.log(\"\\u274c Not ready:\");\n    failed.forEach((f) => console.log(\"  - \" + f.name));\n  }\n}\n\nrunChecklist(checklist);\n\n// Your task: add at least 2 more real checklist items (e.g. \"database\n// migrations applied\", \"no console.log left in production code\"),\n// then make one of them fail on purpose and confirm the output changes.\n"}'::jsonb,
  'advanced', true, true,
  12
where not exists (select 1 from lessons where slug = 'devops-final-project');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'devops-final-project'),
  '{"en":"Why model a deploy checklist as a list of automated checks instead of a manual paper list?","de":"Warum eine Deploy-Checkliste als Liste automatisierter Prüfungen statt als manuelle Papierliste modellieren?"}'::jsonb,
  '{"en":["Automated checks can run every single time without being forgotten or skipped","Paper lists are more accurate","It''s required by every hosting provider","It has no real benefit"],"de":["Automatisierte Prüfungen können jedes Mal laufen, ohne vergessen oder übersprungen zu werden","Papierlisten sind genauer","Es ist bei jedem Hosting-Anbieter vorgeschrieben","Es bringt keinen echten Vorteil"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'devops-final-project')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-transactions',
  '{"en":"Database Transactions","de":"Datenbank-Transaktionen"}'::jsonb,
  '[{"step":1,"text":{"en":"A database transaction groups multiple operations into one all-or-nothing unit: either every operation in it succeeds, or none of them are kept at all — nothing is left half-done.","de":"Eine Datenbank-Transaktion fasst mehrere Operationen zu einer Alles-oder-nichts-Einheit zusammen: Entweder gelingen alle Operationen darin, oder keine davon wird übernommen — nichts bleibt halb erledigt."}},{"step":2,"text":{"en":"The classic example is a money transfer: subtracting from one account and adding to another must both happen, or neither should — a transaction is exactly the tool that guarantees this, even if the server crashes mid-way.","de":"Das klassische Beispiel ist eine Geldüberweisung: Von einem Konto abziehen und einem anderen gutschreiben müssen beide passieren, oder keines von beidem — eine Transaktion ist genau das Werkzeug, das dies garantiert, selbst wenn der Server mittendrin abstürzt."}},{"step":3,"text":{"en":"In real PostgreSQL (the database this platform itself uses via Supabase), this is written as BEGIN; ...your statements...; COMMIT; — with ROLLBACK available to undo everything if something goes wrong partway through.","de":"In echtem PostgreSQL (der Datenbank, die diese Plattform selbst über Supabase nutzt) schreibt man das als BEGIN; ...deine Anweisungen...; COMMIT; — mit ROLLBACK, um alles rückgängig zu machen, falls mittendrin etwas schiefgeht."}}]'::jsonb,
  '{"js":"// Simulated bank transfer WITHOUT a transaction — dangerous if it\n// crashes halfway through.\nfunction transferUnsafe(accounts, from, to, amount) {\n  accounts[from] -= amount;\n  // Imagine a crash happens right here, before the next line runs —\n  // the money would just vanish, taken from one account, never added\n  // to the other.\n  accounts[to] += amount;\n}\n\n// A transaction wraps both steps as one all-or-nothing unit.\nfunction transferWithTransaction(accounts, from, to, amount) {\n  const before = { ...accounts };\n  try {\n    accounts[from] -= amount;\n    accounts[to] += amount;\n  } catch (err) {\n    Object.assign(accounts, before); // roll back everything\n    throw err;\n  }\n}\n\nconst accounts = { alice: 100, bob: 50 };\ntransferWithTransaction(accounts, \"alice\", \"bob\", 30);\nconsole.log(accounts);\n"}'::jsonb,
  'intermediate', false, false,
  23
where not exists (select 1 from lessons where slug = 'backend-transactions');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-transactions'),
  '{"en":"What guarantee does a database transaction provide?","de":"Welche Garantie bietet eine Datenbank-Transaktion?"}'::jsonb,
  '{"en":["It makes queries run faster","All its operations succeed together, or none of them are kept","It automatically creates backups","It changes the table''s column names"],"de":["Sie macht Abfragen schneller","Alle ihre Operationen gelingen gemeinsam, oder keine davon wird übernommen","Sie erstellt automatisch Backups","Sie ändert die Spaltennamen der Tabelle"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-transactions')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-database-indexes',
  '{"en":"Database Indexes","de":"Datenbank-Indizes"}'::jsonb,
  '[{"step":1,"text":{"en":"Without help, a database looks up a row by checking every single row one at a time — fine for a handful of rows, painfully slow once a table has millions.","de":"Ohne Hilfe sucht eine Datenbank eine Zeile, indem sie jede einzelne Zeile nacheinander prüft — kein Problem bei einer Handvoll Zeilen, quälend langsam, sobald eine Tabelle Millionen hat."}},{"step":2,"text":{"en":"An index is a separate, pre-built lookup structure for one column (like email) that lets the database jump almost straight to the matching row instead of scanning everything — the Map in the starter code simulates exactly this idea.","de":"Ein Index ist eine separate, im Voraus aufgebaute Nachschlagestruktur für eine Spalte (wie email), die es der Datenbank erlaubt, fast direkt zur passenden Zeile zu springen, statt alles zu durchsuchen — die Map im Startcode simuliert genau diese Idee."}},{"step":3,"text":{"en":"Indexes aren''t free: they speed up lookups but slightly slow down writes (the index itself has to be updated too), and take extra storage — this platform''s own schema.sql already creates real indexes like the unique index on subscriptions.stripe_customer_id.","de":"Indizes sind nicht kostenlos: Sie beschleunigen Lookups, verlangsamen aber Schreibvorgänge leicht (der Index selbst muss ebenfalls aktualisiert werden) und brauchen zusätzlichen Speicher — das eigene schema.sql dieser Plattform erstellt bereits echte Indizes, wie den eindeutigen Index auf subscriptions.stripe_customer_id."}}]'::jsonb,
  '{"js":"// Simulating why an index matters, without a real database.\nconst users = Array.from({ length: 10000 }, (_, i) => ({\n  id: i,\n  email: \"user\" + i + \"@example.com\",\n}));\n\n// Without an index: check every single row one by one.\nfunction findByEmailSlow(email) {\n  for (const user of users) {\n    if (user.email === email) return user;\n  }\n  return null;\n}\n\n// With an index: a lookup table built once, ahead of time.\nconst emailIndex = new Map(users.map((u) => [u.email, u]));\nfunction findByEmailFast(email) {\n  return emailIndex.get(email) ?? null;\n}\n\nconsole.log(findByEmailSlow(\"user9999@example.com\"));\nconsole.log(findByEmailFast(\"user9999@example.com\"));\n"}'::jsonb,
  'intermediate', false, false,
  24
where not exists (select 1 from lessons where slug = 'backend-database-indexes');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-database-indexes'),
  '{"en":"What does a database index actually do?","de":"Was macht ein Datenbank-Index eigentlich?"}'::jsonb,
  '{"en":["Deletes unused rows automatically","Provides a pre-built lookup structure so matching rows can be found without scanning the whole table","Encrypts the table","Makes every column optional"],"de":["Löscht automatisch ungenutzte Zeilen","Bietet eine im Voraus aufgebaute Nachschlagestruktur, damit passende Zeilen ohne Scan der ganzen Tabelle gefunden werden","Verschlüsselt die Tabelle","Macht jede Spalte optional"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-database-indexes')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-api-versioning-pagination',
  '{"en":"API Versioning & Pagination","de":"API-Versionierung & Pagination"}'::jsonb,
  '[{"step":1,"text":{"en":"APIs change over time, but old clients (an old mobile app version still installed on someone''s phone) can''t update instantly. Versioning the URL itself (/api/v1/... vs /api/v2/...) lets both the old and new shape keep working side by side.","de":"APIs ändern sich mit der Zeit, aber alte Clients (eine alte Mobile-App-Version, die noch auf jemandes Handy installiert ist) können nicht sofort aktualisieren. Die URL selbst zu versionieren (/api/v1/... vs /api/v2/...) lässt die alte und die neue Form nebeneinander weiterlaufen."}},{"step":2,"text":{"en":"Pagination means never sending an entire huge table in one response — instead the client asks for one page at a time (e.g. 10 items), and the server reports how many pages exist in total.","de":"Pagination bedeutet, niemals eine ganze riesige Tabelle in einer einzigen Antwort zu senden — stattdessen fragt der Client jeweils eine Seite an (z. B. 10 Elemente), und der Server meldet, wie viele Seiten es insgesamt gibt."}},{"step":3,"text":{"en":"Without pagination, a table that grows from 100 rows to 100,000 rows would eventually make every single request slower and slower — pagination keeps each individual response small and fast, no matter how much data exists overall.","de":"Ohne Pagination würde eine Tabelle, die von 100 auf 100.000 Zeilen wächst, mit der Zeit jede einzelne Anfrage immer langsamer machen — Pagination hält jede einzelne Antwort klein und schnell, egal wie viele Daten insgesamt existieren."}}]'::jsonb,
  '{"js":"// Versioning: the URL itself carries which version of the API this is.\nfunction handleRequest(path) {\n  if (path.startsWith(\"/api/v1/lessons\")) return { format: \"old shape\" };\n  if (path.startsWith(\"/api/v2/lessons\")) return { format: \"new shape\" };\n  return { status: 404 };\n}\n\nconsole.log(handleRequest(\"/api/v1/lessons\"));\nconsole.log(handleRequest(\"/api/v2/lessons\"));\n\n// Pagination: never return 10,000 rows in one response.\nconst allLessons = Array.from({ length: 63 }, (_, i) => \"Lesson \" + (i + 1));\nfunction paginate(items, page, pageSize) {\n  const start = (page - 1) * pageSize;\n  return {\n    items: items.slice(start, start + pageSize),\n    page,\n    totalPages: Math.ceil(items.length / pageSize),\n  };\n}\n\nconsole.log(paginate(allLessons, 2, 10));\n"}'::jsonb,
  'intermediate', false, false,
  25
where not exists (select 1 from lessons where slug = 'backend-api-versioning-pagination');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-api-versioning-pagination'),
  '{"en":"Why do real APIs paginate large result sets instead of returning everything at once?","de":"Warum paginieren echte APIs große Ergebnismengen, statt alles auf einmal zurückzugeben?"}'::jsonb,
  '{"en":["To make the API harder to use on purpose","To keep each response small and fast regardless of how much total data exists","Pagination is required by every browser","It has no real purpose"],"de":["Um die API absichtlich schwerer nutzbar zu machen","Um jede Antwort klein und schnell zu halten, egal wie viele Daten insgesamt existieren","Pagination ist von jedem Browser vorgeschrieben","Es hat keinen echten Zweck"]}'::jsonb,
  1,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-api-versioning-pagination')
);

insert into lessons (course_id, slug, title, content, starter_code, difficulty, is_free, has_assignment, sort_order)
select
  (select id from courses where slug = 'backend'),
  'backend-deep-final-project',
  '{"en":"Project: A Paginated Orders API","de":"Projekt: Eine paginierte Bestellungen-API"}'::jsonb,
  '[{"step":1,"text":{"en":"Final project: combine everything from this deeper-backend unit — an indexed lookup, paginated listing, and a transaction-style all-or-nothing update — into one small orders API.","de":"Abschlussprojekt: Kombiniere alles aus dieser vertieften Backend-Einheit — einen indizierten Lookup, eine paginierte Auflistung und ein transaktionsartiges Alles-oder-nichts-Update — zu einer kleinen Bestellungen-API."}},{"step":2,"text":{"en":"getOrder uses the same Map-based index idea from the indexes lesson; listOrders uses the same pagination shape from the previous lesson — nothing new to learn there, just applied together.","de":"getOrder nutzt dieselbe Map-basierte Index-Idee aus der Index-Lektion; listOrders nutzt dieselbe Pagination-Form aus der vorherigen Lektion — nichts Neues zu lernen, nur gemeinsam angewendet."}},{"step":3,"text":{"en":"Write refundOrder(id, amount): look the order up, verify amount doesn''t exceed its total, then update it — if anything is invalid, throw instead of partially applying the change, then submit the finished file to your portfolio.","de":"Schreibe refundOrder(id, amount): Suche die Bestellung, prüfe, dass amount nicht über dem total liegt, und aktualisiere sie dann — ist etwas ungültig, wirf einen Fehler, statt die Änderung nur teilweise anzuwenden, und reiche die fertige Datei dann in dein Portfolio ein."}}]'::jsonb,
  '{"js":"const orders = Array.from({ length: 47 }, (_, i) => ({\n  id: i + 1,\n  total: Math.round(Math.random() * 100),\n}));\n\n// A simulated index for fast lookup by id.\nconst ordersById = new Map(orders.map((o) => [o.id, o]));\n\nfunction getOrder(id) {\n  return ordersById.get(id) ?? null;\n}\n\nfunction listOrders(page, pageSize) {\n  const start = (page - 1) * pageSize;\n  return {\n    items: orders.slice(start, start + pageSize),\n    page,\n    totalPages: Math.ceil(orders.length / pageSize),\n  };\n}\n\n// Your task: write refundOrder(id, amount) that finds the order via\n// ordersById, checks amount doesn''t exceed order.total, and either\n// applies the refund (subtract from total) or throws an error —\n// wrap the check-then-update as a single all-or-nothing step, the\n// same transaction idea from earlier in this unit.\n\nconsole.log(listOrders(1, 10));\nconsole.log(getOrder(5));\n"}'::jsonb,
  'advanced', false, true,
  26
where not exists (select 1 from lessons where slug = 'backend-deep-final-project');

insert into quiz_questions (lesson_id, question, choices, correct_index, sort_order)
select
  (select id from lessons where slug = 'backend-deep-final-project'),
  '{"en":"Which three ideas does this final project combine?","de":"Welche drei Ideen kombiniert dieses Abschlussprojekt?"}'::jsonb,
  '{"en":["Indexed lookup, pagination, and an all-or-nothing update","Only CSS Grid and Flexbox","Only React hooks","Only Git branching"],"de":["Indizierter Lookup, Pagination und ein Alles-oder-nichts-Update","Nur CSS Grid und Flexbox","Nur React-Hooks","Nur Git-Branching"]}'::jsonb,
  0,
  1
where not exists (
  select 1 from quiz_questions
  where lesson_id = (select id from lessons where slug = 'backend-deep-final-project')
);

