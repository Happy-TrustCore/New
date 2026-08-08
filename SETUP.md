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

> For "Forgot password" to work: in **Authentication -> URL Configuration**,
> add both `http://localhost:3000/reset-password` (and the German
> `/de/reset-password` variant) and your production
> `https://your-domain/reset-password` URLs to **Redirect URLs**. Supabase
> silently ignores `redirectTo` for any URL not on this list, so without
> this the reset email link sends users to the wrong place.

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

Then paste
[`db/phase7_marketplace_certificates.sql`](db/phase7_marketplace_certificates.sql)
and run it. This adds three brand-new tables (not more curriculum content):
`certificates`, `real_projects`, and `project_interests` — see "What's
built so far" below for what they power. Safe to paste more than once
(every `create table` already uses `if not exists`).

Finally, if you're setting up real payments (see "Turn on real payments"
below), paste [`db/phase8_payments.sql`](db/phase8_payments.sql) and run
it. It adds two columns to the existing `subscriptions` table
(`stripe_customer_id`, `stripe_subscription_id`) — skip this until you're
actually setting up Stripe, there's nothing to see without it.

### Make yourself an admin

Register a normal account first (step 5 below), then in the SQL Editor run:

```sql
update profiles set is_admin = true where email = 'you@example.com';
```

That unlocks `/admin` — lesson/quiz management and a "Users" page where you
can manually grant Pro access to any account (useful before real payments
are wired up).

### Optional: turn on the AI mentor (CodeBuddy)

The AI mentor works without a real payment provider — it's just gated to
Pro accounts, same as everything else, so grant yourself Pro from the
Users page above to test it.

1. Go to https://aistudio.google.com and sign in with any Google account
   (free, no card required).
2. Click **Get API key -> Create API key**.
3. Add it to `.env.local`:
   ```
   GEMINI_API_KEY=your-key-here
   ```
4. In production (Vercel), add the same variable in
   **Project Settings -> Environment Variables** and redeploy.

Leave it blank and the mentor panel just shows "isn't configured yet"
instead of erroring — the rest of the site works fine without it.

### Optional: turn on real payments (Stripe)

Stripe itself is free to sign up for and has no monthly fee — they only
take a cut once a real payment happens, so this doesn't cost anything
until you actually have paying students. Until you do this, "Upgrade"
buttons just send people back to the pricing section, and Pro access
still works fine via the manual admin grant.

1. Create a free account at https://stripe.com.
2. **Get your secret key**: Developers -> API keys -> copy the **Secret
   key** (starts with `sk_test_...` while you're testing, `sk_live_...`
   once you flip Stripe out of test mode).
3. **Create the Pro price**: Product catalog -> + Add product. Name it
   "CodePath Pro", set it to **Recurring**, **€4.99**, **Monthly**. Save,
   then copy the **Price ID** (starts with `price_...`) — not the Product
   ID.
4. **Get your Supabase service role key** (needed regardless of Stripe —
   the webhook writes to the database with no logged-in user, so it can't
   use the normal RLS-scoped key): Supabase dashboard -> Project Settings
   -> API -> copy the **service_role** secret. Never expose this to the
   browser.
5. Run [`db/phase8_payments.sql`](db/phase8_payments.sql) in the Supabase
   SQL Editor.
6. Add to `.env.local`:
   ```
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   STRIPE_SECRET_KEY=sk_test_...
   STRIPE_PRICE_ID=price_...
   ```
7. **Webhook, for local testing**: install the
   [Stripe CLI](https://stripe.com/docs/stripe-cli), then run
   `stripe listen --forward-to localhost:3000/api/stripe/webhook` — it
   prints a webhook signing secret (`whsec_...`) to use as
   `STRIPE_WEBHOOK_SECRET` locally. Stripe can't reach `localhost`
   directly, which is why this step exists only for local dev.
8. **Webhook, for production**: Stripe dashboard -> Developers -> Webhooks
   -> Add endpoint -> `https://your-domain/api/stripe/webhook`, subscribed
   to `checkout.session.completed`, `customer.subscription.updated`, and
   `customer.subscription.deleted`. Copy that endpoint's signing secret
   into Vercel's `STRIPE_WEBHOOK_SECRET` (it's different from the CLI's
   local one).
9. Add all four variables
   (`SUPABASE_SERVICE_ROLE_KEY`/`STRIPE_SECRET_KEY`/`STRIPE_PRICE_ID`/`STRIPE_WEBHOOK_SECRET`)
   to Vercel -> Project Settings -> Environment Variables and redeploy.

Test with [Stripe's test card numbers](https://stripe.com/docs/testing)
(`4242 4242 4242 4242`, any future expiry, any CVC) before switching to
live keys.

## 5. Run the app

```bash
npm run dev
```

Open http://localhost:3000 — you should see the landing page. Register an
account to reach the dashboard.

## What's built so far

- Landing page, register/login (Supabase Auth), protected dashboard shell
- Forgot/reset password (`/forgot-password`, `/reset-password`) — see the
  Supabase Redirect URLs note above, required for the email link to work
- Account settings (`/settings`): change display name, change password, and
  permanently delete your account — the privacy policy promises deletion
  rights, this is what actually does it. Cancels any active Stripe
  subscription first, then removes the auth user via the admin API, which
  cascades through every other table via existing foreign keys
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
  a users page for manually granting Pro access (still useful even with
  real payments wired up — comp accounts, support cases, etc.)
- Real payments (Stripe): "Upgrade" buttons on the dashboard, practice dock
  paywall, CodeBuddy upsell, and marketplace paywall start a real Stripe
  Checkout session; a webhook (`/api/stripe/webhook`) keeps `account_type`
  and the `subscriptions` row in sync as the subscription is created,
  renewed, or canceled; Pro students get a "Manage subscription" button
  that opens Stripe's own hosted Customer Portal. Optional — see "Turn on
  real payments" above. Until configured, Upgrade buttons just go back to
  the pricing section and the manual admin grant keeps working exactly as
  before
- Achievements: 9 badges derived from lesson completion, shown on the
  dashboard
- Certificates: issued automatically the moment every lesson in a course
  (Foundation/Frontend/Backend) is completed — see the "Certificates"
  section on the dashboard, each links to a public, shareable
  `/certificate/[id]` page (no login required to view — the point is you
  can send the link to an employer)
- Real Project Marketplace (`/marketplace`, gated to Pro): admin-curated
  freelance-style opportunities from small businesses. Students express
  interest with an optional note; there's no payment/contract flow yet, so
  an admin follows up manually — manage projects and see who's interested
  at `/admin/marketplace`
- CodeBuddy AI mentor (Pro-only, inside the practice dock): gives hints and
  code review, never the full solution — backed by Google Gemini's free
  tier. Optional — see "Turn on the AI mentor" above. Gracefully disables
  itself (no errors) if `GEMINI_API_KEY` isn't set
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

- The real project marketplace still has a "no payment provider" shape on
  purpose — interest is tracked, nothing gets paid or contracted through
  the platform itself. Wiring actual project payments through Stripe too
  would be a reasonable next step now that the billing plumbing exists
- Everything above is taught, including a full-stack capstone, but it's
  still all simulated in plain JS — no lesson runs a real Express server or
  real SQL against a real Postgres database. Course content past what's
  listed above (deeper database design, more advanced auth patterns, more
  capstones) is authorable through the admin panel without touching code

All of this can continue to run on free tiers (Vercel + Supabase free
plans) — Stripe is the one piece here that isn't a flat free tier, but it
costs nothing until real money actually moves through it.
