Task List — Bills Reminder (MVP)

Last updated: 2025-10-04

Goal: implement the v1 MVP (1-week deliverable): mobile-first React+Vite frontend, Supabase backend (Auth, Postgres, Storage, Edge Functions), email + in-app reminders, CSV import, receipts, household sharing, and Google Calendar sync.

At-a-glance day plan
- Day 1: Project & infra setup + frontend auth scaffold
- Day 2: DB migrations + Bills CRUD + CSV import UI
- Day 3: Reminder worker, in-app notifications, email templates
- Day 4: Attachments (storage) + mark-as-paid flow
- Day 5: Household invites + Google Calendar sync
- Day 6: QA, RLS verification, accessibility fixes
- Day 7: Deploy, monitoring, handoff

Priority task list (check items as you complete them)

1) Project & infra bootstrap (Day 1) — Estimate: small→med
- [ ] Create Supabase project (free tier) and enable Auth providers (Google, Apple, GitHub)
  - Acceptance: Supabase project exists and OAuth providers configured.
- [ ] Configure SMTP / SendGrid in Supabase and send a test email
  - Acceptance: test reminder email delivered.
- [ ] Create Vercel project, connect repo, add env vars: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE (Edge only), GOOGLE_CLIENT_ID
  - Acceptance: Vercel builds a test commit successfully.
- [ ] Update README with env setup and run steps
  - Acceptance: `npm run dev` works locally with env configured.

2) Database migrations & RLS (Day 2) — Estimate: med
- [ ] Add SQL migrations under `db/migrations/` for tables: households, household_members, bills, reminders, payments, attachments, invites, notifications
  - Acceptance: migrations apply without error on Supabase test project.
- [ ] Add indexes and constraints (money stored as amount_cents bigint)
- [ ] Implement RLS policies for household-scoped tables (SELECT/INSERT/UPDATE/DELETE) and owner-only invite creation
  - Acceptance: unauthorized users cannot access another household's data (verified by test queries).

3) Frontend skeleton & auth (Day 1→2) — Estimate: small→med
- [ ] Install client libs: `@supabase/supabase-js`, `react-query`/`swr`, `react-hook-form`, `papaparse`, `date-fns`
- [ ] Scaffold routes/pages: Auth, Dashboard, Bill Detail, Add/Edit Bill, CSV Import, Household, Notifications, Settings
- [ ] Wire Supabase auth (email + social providers) and quick onboarding flow (household creation or personal)
  - Acceptance: user can sign up/sign in and reach the dashboard.

4) Bills CRUD + UI (Day 2) — Estimate: med
- [ ] Implement dashboard list, summary tiles, and quick actions (Mark as paid placeholder)
- [ ] Implement Add/Edit Bill form (React Hook Form) with validation
- [ ] Wire CRUD to Supabase (respect RLS)
  - Acceptance: create/read/update/delete bills work and appear in dashboard for authorized users.

5) CSV import UI & server parsing (Day 2→3) — Estimate: med
- [ ] Implement CSV upload UI, header mapping, preview table with per-row validation (client-side preview)
- [ ] Implement option to "Skip invalid rows and import valid rows" and export invalid rows
- [ ] Implement Edge Function `/edge/csv-import` (TypeScript) for server-side parse/preview/import (recommended)
  - Acceptance: preview shows validation errors; importing valid rows creates bills and returns summary.

6) Reminder materialization & scheduled worker (Day 3) — Estimate: large
- [ ] Implement reminder generation when bills are created/updated (pre-generation offsets and post-generation daily reminders)
- [ ] Implement Supabase scheduled Edge Function `reminder-worker` (TypeScript)
  - Runs hourly; queries pending reminders and sends email + in-app notifications
  - Retries up to 3 times with backoff; marks failures
  - Acceptance: worker sends test email and inserts a notification row; retries on simulated failure.

7) In-app notifications (Day 3) — Estimate: small
- [ ] Create `notifications` table and UI notification center with unread badge
- [ ] Insert notifications from reminder-worker and provide quick actions (Mark read, Mark paid link)
  - Acceptance: notification appears when worker sends; marking read updates DB.

8) Email templates & transactional config (Day 3) — Estimate: small
- [ ] Create reminder email template with CTA linking to bill detail and quick mark-as-paid link
- [ ] Test deliverability and include unsubscribe/opt-out text
  - Acceptance: emails deliver and CTA opens correct bill in dev app.

9) Attachments / Storage (Day 4) — Estimate: med
- [ ] Create `receipts` bucket in Supabase Storage (private) and enforce 5 MB limit client-side
- [ ] Implement upload flow (signed URL / Supabase client) and store metadata in `attachments` table
- [ ] Display thumbnails and provide signed download URLs (expiry)
  - Acceptance: users upload jpg/png/pdf <= 5MB and view/download via signed URL.

10) Mark-as-paid flow & payments table (Day 4) — Estimate: med
- [ ] Implement Mark-as-paid modal (amount, date, method, optional receipt upload)
- [ ] On confirm: insert payment record, update bill status to `paid`, cancel scheduled reminders, update calendar event if synced
  - Acceptance: marking paid records payment, stops reminders for that bill.

11) Household invites & accept (Day 5) — Estimate: med
- [ ] Implement invite UI (owner only) that creates `invites` row and sends email with secure token link
- [ ] Implement Edge Function `/edge/invite-accept` to validate token and attach user to household after auth
  - Acceptance: invitee accepts link, becomes member, and sees shared bills.

12) Google Calendar sync (Day 5) — Estimate: med→large
- [ ] Frontend: UI to trigger Google OAuth consent for calendar scope
- [ ] Edge Function `/edge/calendar-sync` to exchange code, store encrypted refresh token, and materialize events (next 12 months or series)
- [ ] Update/delete events when bills change or are paid; handle token refresh and reauth
  - Acceptance: connected calendar shows events and they update on bill changes.

13) Security, RLS verification & secrets (Day 6) — Estimate: med
- [ ] Verify RLS policies with integration tests (different users, households)
- [ ] Ensure service role keys are only used server-side (Edge Functions); rotate keys if needed
  - Acceptance: RLS tests pass; service role not exposed to frontend.

14) Testing & accessibility (Day 6) — Estimate: med
- [ ] Unit tests (React Testing Library) for core components
- [ ] Integration/E2E tests (Playwright/Cypress) for signup, add bill, CSV import, mark paid
- [ ] Accessibility checks (axe) and keyboard/focus behaviors
  - Acceptance: core flows pass E2E and critical accessibility issues fixed.

15) Observability & admin tools (Day 6–7) — Estimate: small
- [ ] Add logs in Edge Functions and basic metrics (reminders sent, failures)
- [ ] Admin Edge Function to re-run reminders/backfill for a date range
- [ ] Configure alerts for worker failures / email bounces
  - Acceptance: alerts active and admin rerun works.

16) CI/CD & production deploy (Day 7) — Estimate: small
- [ ] Configure Vercel production env and deploy frontend
- [ ] Deploy Edge Functions to Supabase and schedule `reminder-worker` hourly
- [ ] Run production smoke tests
  - Acceptance: Production deploy succeeds and smoke tests pass.

17) Handoff & docs (Day 7) — Estimate: small
- [ ] Update README with deploy/run steps, env var list, and admin procedures
- [ ] Provide short operations doc: re-run reminders, revoke calendar tokens, rotate keys
  - Acceptance: Docs present and team can reproduce deploy locally.

Optional / Future (post-MVP)
- [ ] SMS reminders (Twilio) & phone OTP
- [ ] Bank/provider integrations for auto bill detection
- [ ] Multi-currency and timezone support
- [ ] Advanced recurrence rules (cron-like)

Recommended tools & libs
- Frontend: `@supabase/supabase-js`, `react-query` or `swr`, `react-hook-form`, `papaparse`, `date-fns`, `heroicons`
- Edge Functions: TypeScript, `@supabase/supabase-js`, SendGrid SDK or SMTP helper
- Testing: Jest + React Testing Library, Playwright or Cypress for E2E
- Migrations: Supabase CLI or `pg-migrate`

Estimated total effort: ~6–8 developer-days (1 developer), aggressive 1-week plan if prioritized and executed in parallel where possible.

Next steps I can take now
- Convert this list into GitHub issues with checklists and estimates.
- Generate full SQL migration files and place them under `db/migrations/`.
- Scaffold the reminder-worker Edge Function (TypeScript) in `supabase/functions/`.
