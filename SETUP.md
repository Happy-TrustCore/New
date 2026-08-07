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

### Add the starter curriculum

Paste [`db/seed.sql`](db/seed.sql) into the SQL Editor and run it. This adds
the real initial curriculum: both Foundation lessons, all 16 free Frontend
lessons (HTML → HTML+CSS → layout → a full HTML/CSS site exam, following the
PRD's "improve the same project" teaching method), and the first 8 free
Backend lessons (how servers/requests work, building up to a simulated
router + API, since the in-browser editor runs client-side JS only — it
can't execute a real Node.js server). Every lesson has one quiz question.
This is real content, not a placeholder — more lessons (paid-tier Frontend,
the rest of Backend, React, etc.) are still to be written, and can be added
through `/admin` without touching code.

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
  `src/lib/lesson-server.ts`, `src/lib/actions/practice.ts` and `quiz.ts`) —
  free-tier paywalling and sequential unlocking are separate checks, so a
  lesson can be sequentially unlocked but still require Pro
- The three-pane `/learn/[lessonSlug]` page: course sidebar (locked / free-to-
  continue / paywalled / completed), step-by-step lesson content, and a live
  HTML/CSS/JS code editor (CodeMirror) with a Run button, sandboxed iframe
  preview, and a captured console panel
- A lesson only counts as complete once **both** the practice ("Mark
  practice complete") and the quiz (when the lesson has one) are passed —
  matching the PRD's unlock rule. XP is awarded once, when both are done.
- Real starter curriculum (`db/seed.sql`): 2 Foundation lessons, all 16 free
  Frontend lessons, and 8 free Backend lessons, each with a quiz question —
  26 lessons total, all completable end to end
- An admin panel (`/admin`) — lesson + quiz CRUD, an overview dashboard, and
  a users page for manually granting Pro access (no payment provider is
  wired up yet, so this is how you comp accounts for now)
- Full English/German support (next-intl): every UI page and all 26 lessons
  + 23 quiz questions are translated. English is unprefixed (`/dashboard`),
  German lives at `/de/...` (`/de/dashboard`). A language switcher sits in
  the navbar and the app header. The admin panel itself stays English-only
  (it's a tool for you, not learner-facing) — but the lesson content you
  author through it is bilingual (separate EN/DE fields in the form).

## What's next

- Assignment flow (practice + quiz exist; assignments do not yet)
- AI mentor, achievements/badges beyond basic XP, real subscription/payment
  integration (paywall UI exists, nothing actually charges yet)
- The paid-tier Frontend/Backend curriculum (JS, React, Node/Express/DB in
  depth) and the rest of Backend past lesson 8 — the admin panel makes this
  authorable without touching code

All of this can continue to run on free tiers (Vercel + Supabase free plans).
