System Architecture — Bills Reminder

Last updated: 2025-10-04

Purpose
- This document translates the PRD and User Flows into a concrete system architecture for the v1 MVP (1-week deliverable). It focuses on implementable choices: Supabase backend (Postgres + Edge Functions + Storage), React+Vite frontend hosted on Vercel, Google Calendar integration, and a scheduled reminder worker implemented with Supabase scheduled Edge Functions in TypeScript.

Overview (components)
- Frontend (React + Vite)
  - Mobile-first single-page app. Uses Supabase JS client for auth and realtime where needed.
  - Pages: Auth, Dashboard, Bill detail, Add/Edit bill, CSV import preview, Household management, Notifications, Settings.

- Backend / Data (Supabase)
  - Postgres database for primary data (bills, households, members, payments, reminders, invites, attachments metadata).
  - Supabase Storage for receipts (bucket: receipts).
  - Supabase Auth for identity and OAuth providers (Google, Apple, GitHub).
  - Supabase Edge Functions (TypeScript) for server-side logic: reminder scheduler, CSV import worker, calendar sync helper endpoints, invite link handling.

- Email / Transactional
  - Use Supabase SMTP integration or third-party provider (SendGrid) configured in Supabase settings to send reminder emails.

- Calendar Integration
  - Google Calendar OAuth for write access. Frontend handles OAuth consent; server-side edge function stores tokens (encrypted) and performs event creation/updates.

- Hosting & CI/CD
  - Frontend deployed to Vercel. Edge Functions deployed to Supabase (Edge Functions). Use GitHub Actions (optional) for CI.

Data model (detailed)
Note: users are managed by Supabase Auth. IDs are UUIDs.

Table: households
- id uuid primary key
- name text not null
- owner_user_id uuid references auth.users(id)
- created_at timestamptz default now()

Table: household_members
- id uuid primary key
- household_id uuid references households(id) on delete cascade
- user_id uuid references auth.users(id)
- role text check (role in ('owner','member')) default 'member'
- invited_at timestamptz
- accepted_at timestamptz

Table: bills
- id uuid primary key
- household_id uuid references households(id) on delete cascade
- created_by uuid references auth.users(id)
- payee text not null
- name text not null
- amount_cents bigint not null -- store in paise
- currency text not null check (currency = 'INR')
- generation_date date not null -- date bill is generated (start of due lifecycle)
- due_date date -- optional explicit due date
- recurrence text check (recurrence in ('none','monthly','quarterly','yearly')) default 'none'
- repeat_daily_after_generation boolean default true
- notes text
- status text check (status in ('unpaid','paid')) default 'unpaid'
- last_generated_at timestamptz -- for bookkeeping when recurrence was last materialized
- created_at timestamptz default now()
- updated_at timestamptz default now()

Table: reminders
- id uuid primary key
- bill_id uuid references bills(id) on delete cascade
- notify_at timestamptz not null
- channel text check (channel in ('email','inapp')) not null
- sent_at timestamptz
- status text check (status in ('pending','sent','failed')) default 'pending'
- attempts int default 0

Table: payments
- id uuid primary key
- bill_id uuid references bills(id) on delete cascade
- user_id uuid references auth.users(id)
- amount_cents bigint not null
- paid_at timestamptz not null
- method text
- receipt_url text
- created_at timestamptz default now()

Table: attachments
- id uuid primary key
- bill_id uuid references bills(id) on delete cascade
- uploaded_by uuid references auth.users(id)
- file_path text not null -- path in Supabase storage
- file_size int not null
- content_type text
- uploaded_at timestamptz default now()

Table: invites
- id uuid primary key
- household_id uuid references households(id) on delete cascade
- email text not null
- token text not null -- secure random token
- status text check (status in ('pending','accepted','revoked')) default 'pending'
- invited_by uuid references auth.users(id)
- created_at timestamptz default now()
- accepted_at timestamptz

Indexes & considerations
- Index on bills(household_id, generation_date)
- Index on reminders(notify_at, status)
- Use numeric or bigint for money (store paise) to avoid floating point.

Row-Level Security (RLS) strategy
- Enforce that only members of a household can read/write its bills, reminders, payments, and attachments.
- Example policy for SELECT on bills:
  - ENABLE RLS ON bills;
  - CREATE POLICY "household_members_read" ON bills FOR SELECT USING (
      EXISTS (SELECT 1 FROM household_members hm WHERE hm.household_id = bills.household_id AND hm.user_id = auth.uid())
    );
- Similar policies for INSERT/UPDATE/DELETE restrict operations to household members and the owner for invite management.

Storage rules (Supabase Storage)
- Bucket: receipts
  - Public: false (private)
  - File path example: receipts/{household_id}/{bill_id}/{uuid}-{filename}
  - Max file size: enforce client-side and Edge Function checks to 5 MB.
- Access pattern: files are signed URLs generated by server or Supabase client using secure policies that check RLS / ownership.

API & Edge Functions (contracts)
Notes: Use Supabase client in frontend for basic CRUD where RLS suffices; use Edge Functions for privileged actions, CSV import processing, calendar sync, and scheduled jobs.

Public client calls (via Supabase JS)
- Auth: handled by Supabase client SDK (signUp, signInWithOAuth).
- Bills CRUD: use Supabase client with RLS.
- Attachments upload: upload to receipts bucket with signed policy from frontend.

Edge functions (TypeScript) — recommended list
- /edge/csv-import
  - POST: upload CSV file or provide file URL; server parses, validates rows, returns preview results and optionally performs import. Uses service key.
  - Request: { action: 'preview'|'import', csv: base64 | url, household_id }
  - Response: preview rows with per-row status and errors or import summary.

- /edge/invite-accept
  - GET: validate invite token and attach user to household on accept.

- /edge/calendar-sync
  - POST: exchange OAuth code for tokens and store encrypted refresh token; create initial events.
  - POST /edge/calendar-sync/refresh-events: reconcile events for a household.

- /edge/reminder-worker (scheduled)
  - Runs hourly (Supabase scheduled function)
  - Queries reminders where notify_at <= now() and status = 'pending'
  - Sends email via transactional provider and writes in-app notification rows (notifications table or insert into reminders.sent_at)
  - Marks reminders as sent (sets sent_at and status='sent') and observes retry logic on failure.

Reminder worker design (hourly scheduled edge function)
- Why: keep scheduling simple and reliable without a separate queue system for v1.
- What it does (high level):
  1. SELECT reminders WHERE notify_at <= now() AND status = 'pending' FOR UPDATE SKIP LOCKED LIMIT 100
  2. For each reminder row: build payload (bill details, household, user contacts)
  3. Send email via SendGrid (or Supabase SMTP) and create an in-app notification (insert notifications table or set reminders.sent_at)
  4. On success: update reminders set status='sent', sent_at=now()
  5. On failure: increment attempts; if attempts < 3 set status='pending' and backoff (e.g., schedule next notify_at = now() + 15 minutes); otherwise set status='failed' and create an operator alert

TypeScript snippet (reminder worker) — simplified
```ts
// ... simplified, not a full runnable file. Use as template inside Supabase Edge Function
import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE')!)

serve(async (req) => {
  // Query pending reminders
  const { data: reminders } = await supabase
    .from('reminders')
    .select('id,bill_id,notify_at,channel')
    .lte('notify_at', new Date().toISOString())
    .eq('status', 'pending')
    .limit(100)

  for (const r of reminders || []) {
    try {
      // load bill and household/user info
      const { data: bill } = await supabase.from('bills').select('*').eq('id', r.bill_id).single()
      // send email via SendGrid/smtp helper (not shown)
      // insert in-app notification into a notifications table (row-level secured)
      await supabase.from('reminders').update({ status: 'sent', sent_at: new Date().toISOString() }).eq('id', r.id)
    } catch (err) {
      await supabase.from('reminders').update({ attempts: supabase.raw('attempts + 1') }).eq('id', r.id)
    }
  }

  return new Response('OK')
})
```

Notes on concurrency & deduplication
- Use SELECT ... FOR UPDATE SKIP LOCKED pattern (Postgres) or rely on Supabase's row locking to avoid duplicate sends when the worker runs in parallel.
- Limit batch sizes (e.g., 100) per run to control runtime and avoid provider rate limits.

Notifications table (in-app)
- Consider a lightweight notifications table to hold in-app notifications, rather than overloading reminders:
  - id, user_id, household_id, bill_id, type, message, url, read_at, created_at

CSV import considerations
- Parsing and validation should happen server-side in an Edge Function using a robust CSV parser (fast-csv / papaparse server). Return per-row results to the UI for preview.
- Provide option to skip invalid rows; import valid rows in a transaction per batch of N rows to avoid locking the whole DB.

Calendar sync details
- OAuth: frontend triggers Google OAuth (with scope https://www.googleapis.com/auth/calendar.events). The edge function exchanges code for tokens and stores encrypted refresh tokens (use Supabase Secrets or a server-side KMS).
- Event format: create an event on generation_date with description including amount and a link to bill detail (deep link to web app). For recurring bills, create a single series event or materialize events for next 12 months.
- Token refresh & errors: detect expired tokens and surface re-auth flow to the user.

Security considerations
- Use RLS extensively. Do not expose service role keys to the frontend. Edge functions that need elevated privileges must use the service_role key stored in environment variables.
- Encrypt Google refresh tokens and any PII at rest per Supabase best practices.
- Validate attachments server-side: check content-type, verify size < 5MB, and scan filenames. Use signed URLs for downloads.

Observability & Ops
- Logs: Edge Functions should log attempts, failures, and key metrics (reminders sent, emails failed, calendar sync errors).
- Monitoring: set up simple alerts (email / Slack) for failed scheduled runs, high failure rates, or email provider bounces.
- Backfill & re-run: provide an admin edge function to re-run reminder cycles for a given date range for debugging.

Deployment checklist
- Create Supabase project and enable SMTP / configure SendGrid.
- Create Storage bucket `receipts`. Add policies to limit uploads and require auth checks.
- Add DB tables (use migration SQL below as a starting point).
- Configure OAuth providers (Google, Apple, GitHub) in Supabase Auth.
- Deploy Edge Functions and add a scheduled trigger for the reminder worker (hourly).
- Configure Vercel project for frontend with ENV vars: SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_CLIENT_ID (for OAuth consent via frontend), and optionally a backend endpoint URL for edge functions.

Minimal SQL migrations (example for core tables)
```sql
-- households
CREATE TABLE households (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  owner_user_id uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- bills
CREATE TABLE bills (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid REFERENCES households(id) ON DELETE CASCADE,
  created_by uuid REFERENCES auth.users(id),
  payee text NOT NULL,
  name text NOT NULL,
  amount_cents bigint NOT NULL,
  currency text NOT NULL DEFAULT 'INR',
  generation_date date NOT NULL,
  due_date date,
  recurrence text DEFAULT 'none',
  repeat_daily_after_generation boolean DEFAULT true,
  notes text,
  status text DEFAULT 'unpaid',
  last_generated_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

Acceptance criteria mapping (system)
- All data access is protected by RLS and verified in integration tests.
- Scheduled reminders run hourly and deliver reminders via email and in-app; retries and failure states handled.
- CSV import validates and allows skipping invalid rows as shown in the User Flow.
- Attachments stored in `receipts` bucket with 5 MB limit and private access; only household members can generate signed download URLs.

Next steps (implementation items)
1. Create DB migrations and apply to Supabase (tables above + policies).
2. Implement Supabase Edge Functions (TypeScript): reminder-worker, csv-import, calendar-sync, invite-accept, admin re-run.
3. Wire frontend to Supabase client for auth and basic CRUD; call Edge Functions for CSV import and calendar OAuth exchange.
4. Configure scheduled trigger for reminder-worker (hourly) in Supabase dashboard.
5. Add monitoring/alerts and test email deliverability.

Questions / open decisions
- How many calendar events should be materialized at once for recurrence? (Default: next 12 months.)
- Do you want a separate notifications table or reuse reminders as the source of truth for in-app notifications? (Recommendation: separate notifications table for UI convenience.)

If you want, I can now:
- Generate the full SQL migration file for the above schema including RLS policies, or
- Scaffold the TypeScript Edge Function for the reminder-worker (complete runnable example) and a small test harness.
