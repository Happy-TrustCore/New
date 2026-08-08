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
error handling, and a mini auth-system exam). 42 lessons total, 39 with a
quiz question, 4 requiring a project submission to your portfolio. Backend
lessons simulate the server in plain JS (the in-browser editor only runs
client-side code — it can't execute a real Node.js server). Real content,
not a placeholder — React and deeper Node/Express/DB content are still to be
written, and can be added through `/admin` without touching code.

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
- The three-pane `/learn/[lessonSlug]` page: course sidebar (locked / free-to-
  continue / paywalled / completed), step-by-step lesson content, and a live
  HTML/CSS/JS code editor (CodeMirror) with a Run button, sandboxed iframe
  preview, and a captured console panel
- A lesson only counts as complete once practice, quiz (when present), and
  assignment (when required) are all passed — matching the PRD's unlock
  rule. XP is awarded once, when everything required is done.
- Assignment flow + portfolio: lessons can require a project submission,
  saved to a real "Portfolio" section on the dashboard
- Real curriculum (`db/seed.sql`): 42 lessons across Foundation, Frontend
  (through JavaScript projects), and Backend (through a mini auth system),
  39 with quizzes, 4 with assignments — see "Add the curriculum" above
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
- React lessons, deeper Node/Express/database content, and course content
  past what's listed above — the admin panel makes this authorable without
  touching code

All of this can continue to run on free tiers (Vercel + Supabase free plans).
