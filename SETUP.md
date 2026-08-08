# CodePath Academy — free local setup

Everything here uses free tiers. No card is required for any step.

## 1. Install dependencies

```bash
npm install
```

## 2. Create a free Supabase project

1. Go to https://supabase.com and sign up (free).
2. Create a new project (pick any name/region, free plan).
3. Once it's ready, open **Project Settings -> API** and copy:
   - **Project URL**
   - **anon public** key

## 3. Configure environment variables

Copy `.env.example` to `.env.local` and paste in the values from step 2:

```bash
cp .env.example .env.local
```

## 4. Create the database schema

1. In your Supabase project, open the **SQL Editor**.
2. Paste the contents of [`db/schema.sql`](db/schema.sql) and run it.

This creates all core tables (profiles, courses, lessons, quiz_questions,
lesson_progress, projects, subscriptions), row-level security policies, and a
trigger that auto-creates a profile + free subscription whenever someone
registers.

> Optional: in **Authentication -> Providers -> Email**, you can turn off
> "Confirm email" while developing so new accounts can log in immediately
> without clicking a confirmation link.

### Add the curriculum

Paste [`db/seed.sql`](db/seed.sql) into the SQL Editor and run it. This adds
the real curriculum, fully bilingual (English + German): both Foundation
lessons, all 16 free Frontend lessons (HTML → HTML+CSS → layout → a full
HTML/CSS site exam), the first 8 free Backend lessons, and now the first
paid-tier lessons too — 10 JavaScript lessons (variables through two real
mini-projects: a name-greeting app and a calculator) and 6 more Backend
lessons (database table design, password hashing, registration, sessions,
error handling, and a mini auth-system exam). 42 lessons total. Backend
lessons simulate the server in plain JS (the in-browser editor only runs
client-side code — it can't execute a real Node.js server). Real content,
not a placeholder — React and deeper Node/Express/DB content are still to be
written, and can be added through `/admin` without touching code.

Then paste [`db/checkpoint_exams.sql`](db/checkpoint_exams.sql) and run it
too. It adds a mid-part "checkpoint" exam to each part that previously only
had an exam at the very end (HTML/CSS, JavaScript, Backend foundations,
Backend security) — 46 lessons total, 43 with a quiz question, 8 requiring a
project submission. Safe to paste more than once (every insert/update is
guarded), and safe to run on a database that's never seen `seed.sql` before
or one that's already had it run — it renumbers existing lessons to make
room for the new ones either way.

Then paste [`db/react_lessons.sql`](db/react_lessons.sql) and run it too. It
appends 7 paid-tier Frontend lessons covering React — components, props,
state (`useState`), events, list rendering, and a "Task Tracker" mini
project — right after the JavaScript lessons. These are the first lessons
that use the editor's new `jsx` language tab: the preview iframe loads
React, ReactDOM, and Babel Standalone from a CDN and transforms JSX in the
browser, so no build step or bundler is needed. Safe to paste more than
once.

Then paste [`db/react_hooks_lessons.sql`](db/react_hooks_lessons.sql) and
run it too. It appends 4 more React lessons — `useEffect` (with a live
clock and cleanup function), simulated data fetching with a loading state,
a state-based routing pattern, and a capstone "Mini Dashboard" project that
combines all of it. This completes the PRD's named React scope
(components/props/state/hooks/routing/API). Safe to paste more than once.

Then paste [`db/backend_deep_lessons.sql`](db/backend_deep_lessons.sql) and
run it too. It appends 6 more paid-tier Backend lessons after
`backend-paid-exam`: Express middleware (an auth-guard example), real SQL
syntax (`SELECT`/`WHERE`, then `JOIN`, simulated against plain JS arrays
the same way earlier backend lessons simulate a server), REST API design
(HTTP methods and status codes), a concept-only lesson on what Supabase
actually is (no practice required — nothing to code, just how the pieces
you've learned map onto it), and a full-stack capstone that wires a
simulated frontend fetch layer to a simulated backend API and database.
**63 lessons total, 60 with a quiz, 11 requiring a project submission.**
Safe to paste more than once.

### Make yourself an admin

Register a normal account first (step 5 below), then in the SQL Editor run:

```sql
update profiles set is_admin = true where email = 'you@example.com';
```

That unlocks `/admin` — lesson/quiz management and a "Users" page where you
can manually grant Pro access to any account (useful before real payments
are wired up).

## 5. Run the app

```bash
npm run dev
```

Open http://localhost:3000 — you should see the landing page. Register an
account to reach the dashboard.

## What's built so far

- Landing page, register/login (Supabase Auth), protected dashboard shell
- Full database schema with row-level security
- Strict lesson-unlock model, enforced both when listing lessons and again
  server-side before any progress is written (`src/lib/lessons.ts`,
  `src/lib/lesson-server.ts`, `src/lib/actions/practice.ts`, `quiz.ts`, and
  `assignment.ts`) — free-tier paywalling and sequential unlocking are
  separate checks, so a lesson can be sequentially unlocked but still
  require Pro
- The `/learn/[lessonSlug]` page: course sidebar (locked / free-to-continue /
  paywalled / completed), a wide step-by-step lesson-content column, and a
  collapsible bottom "practice dock" (auto-opens once the lesson steps are
  finished) holding a VS Code–themed CodeMirror editor for HTML/CSS/JS/JSX,
  a sandboxed iframe preview that auto-live-reloads as you type, and a
  captured console panel
- A lesson only counts as complete once practice, quiz (when present), and
  assignment (when required) are all passed — matching the PRD's unlock
  rule. XP is awarded once, when everything required is done.
- Assignment flow + portfolio: lessons can require a project submission,
  saved to a real "Portfolio" section on the dashboard
- Real curriculum (`db/seed.sql` + `db/checkpoint_exams.sql` +
  `db/react_lessons.sql` + `db/react_hooks_lessons.sql` +
  `db/backend_deep_lessons.sql`): 63 lessons across Foundation, Frontend
  (through React hooks, routing, and data fetching), and Backend (through
  Express middleware, SQL, REST design, and a full-stack capstone), 60 with
  quizzes, 11 with assignments, plus mid-part checkpoint exams — see "Add
  the curriculum" above
- An admin panel (`/admin`) — lesson + quiz CRUD, an overview dashboard, and
  a users page for manually granting Pro access (no payment provider is
  wired up yet, so this is how you comp accounts for now)
- Achievements: 9 badges derived from lesson completion, shown on the
  dashboard
- Bilingual Privacy Policy and Terms of Service pages (`/privacy`, `/terms`)
  — uses placeholder contact emails you should replace before real users
  sign up, and isn't a substitute for real legal review
- Full English/German support (next-intl): every UI page and all lesson/quiz
  content is translated. English is unprefixed (`/dashboard`), German lives
  at `/de/...` (`/de/dashboard`). A language switcher sits in the navbar and
  the app header. The admin panel itself stays English-only (it's a tool for
  you, not learner-facing) — but the lesson content you author through it is
  bilingual (separate EN/DE fields in the form).

## What's next

- AI mentor — needs you to pick an LLM provider and create an API key
- Real subscription/payment integration — needs a payment provider account
  (paywall UI + manual admin grant exist, nothing actually charges yet)
- Deployed-service integration next: everything above is taught, including
  a full-stack capstone, but it's still all simulated in plain JS — no
  lesson runs a real Express server or real SQL against a real Postgres
  database. Course content past what's listed above (deeper database
  design, more advanced auth patterns, more capstones) is authorable
  through the admin panel without touching code

All of this can continue to run on free tiers (Vercel + Supabase free plans).
