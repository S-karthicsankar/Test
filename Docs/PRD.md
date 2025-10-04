Bills Reminder — Product Requirements Document (PRD)

Last updated: 2025-10-04

Core stack
- Frontend: React + Vite (mobile-first, plain CSS)
- Backend / Database: Supabase (Postgres)
- Hosting / Deployment: Vercel (frontend), Supabase (backend)
- Calendar integration: Google Calendar API (free tier)

Overview
--------
Problem statement
: Many users (individuals and households) forget to pay recurring or one-off utility bills and incur late fees or service interruptions.

Product vision
: A simple, mobile-first web app that lets users track bills, receive configurable reminders, store receipts, and share bill lists with household members. The MVP will focus on fast setup, reliable reminders (in-app + email), and an easy workflow to mark bills as paid.

High-level goals
- Reduce missed/late payments for users by providing early and ongoing reminders.
- Make it fast to add bills (manual entry + CSV import) and to mark them paid.
- Support simple household sharing so multiple people can view and act on shared bills.
- Keep the MVP small and deliverable in 1 week.

Target users / personas
- Single-user (personal): Someone managing their own utilities and subscriptions.
- Household manager: A person who shares a single account or invites household members to jointly manage bills (simple sharing: invite by email).

Success metrics (MVP)
- Primary metric: # of bills paid on time (tracked per user / household).
- Secondary metrics: % of reminders acknowledged, # of active users, retention after 7 and 30 days.

Scope & constraints (v1 / MVP)
- Auth: Supabase auth with email+password and social logins (Google, Apple, GitHub). No phone/OTP for v1.
- Notifications: In-app push and email notifications (no SMS in v1).
- Bill input: Manual entry and CSV import (recommended format defined below).
- Recurrence: Support for recurring bills (monthly, quarterly, yearly) and one-offs.
- Reminders: Default reminders 2 days before bill generation date; once a bill is generated and unpaid, send daily reminders until marked paid. Users can customize reminders per bill.
- Receipts: Allow attachments (images, PDFs) up to 5 MB.
- Calendar sync: Optional Google Calendar sync with write permission (events updated when bill status changes).
- Currency/timezone: INR and IST only for v1.
- Sharing: Simple invite-by-email household sharing with equal access (owner can invite; members can view and mark paid).
- Privacy: No bank credential storage; user data retained until user deletes account. Provide export and delete options.

Out of scope (v1)
- Bank connections / open banking / automatic bill detection.
- SMS notifications.
- Multi-currency and multi-timezone support.

User flows (short)
- Sign up / Sign in
  - Options: email/password, Google, Apple, GitHub via Supabase.
  - New users prompted to set timezone (default IST) and currency (INR).

- Add a bill (manual)
  - Fields: payee, bill name, amount (INR), due date (or generation date), recurrence (none/monthly/quarterly/yearly), reminder offsets (default: 2 days before; plus daily after generation), notes, optional attachment (receipt).

- Add bills (CSV import)
  - User uploads CSV in recommended format (see CSV spec). System validates rows and shows preview before import.

- Household sharing
  - Owner invites by email. Invitee accepts and joins household; then sees shared bills.

- Reminders & notifications
  - System schedules: 2 days before generation date -> email + in-app. After generation, if unpaid, schedule daily reminders until paid. Users may add extra pre-reminders.

- Mark bill as paid
  - Required fields: amount paid, payment date (default today), payment method (optional), upload receipt (optional). Changes update calendar events and stop scheduled reminders.

Detailed features
-----------------
1) Authentication & account
- Supabase-auth backed: email/password + OAuth providers (Google, Apple, GitHub).
- Session handling via secure cookies/JWT from Supabase.

2) Bills management
- Create, read, update, delete bills.
- Bill model supports recurrence rules (simple frequency + interval), generation date (date the bill becomes due), due date (optional explicit), amount, notes, tags.
- Per-bill custom reminder rules (pre-reminders and whether to repeat daily after generation).

3) Reminders & notifications
- In-app notifications (toast + notification center) and email notifications via Supabase or transactional email provider (e.g., SendGrid via Supabase SMTP integration).
- Default schedule: send email + in-app notification 2 days before the bill's generation_date. When the bill generation date passes and the bill remains unpaid, send daily reminders until paid.
- Email content: clear CTA linking to the bill details and a quick "Mark as paid" button.

4) Receipts & attachments
- Attachments allowed: images (jpg, png), PDF. Max size: 5 MB per file. Stored in Supabase Storage with access rules scoped to the owning household/user.

5) CSV import
- Recommended CSV columns:
  - payee,bill_name,amount,currency,generation_date,due_date,recurrence,reminder_offsets,notes
  - Example row: "Electricity,June Bill,1234.50,INR,2025-06-10,2025-06-20,monthly,2;1,Account number X"
- On import, show a preview with validation errors and allow mapping columns if the header differs.

6) Calendar sync
- Google Calendar OAuth flow. On sync, create events for upcoming due dates and keep events updated when bills change status (paid/unpaid) or dates change.

7) Sharing
- Simple household: owner creates household and invites via email. Invited users accept and gain equal access to bills. Owner role can revoke access and manage invites.

8) Settings & preferences
- Per-user preferences for notification frequency, default reminder offsets (default: 2 days before + daily after generation), time zone (fixed to IST for v1), and email notification toggle.

Data model (Supabase tables - simplified)
- users (managed by Supabase auth)
  - id (uuid), email, name, created_at

- households
  - id (uuid), name, owner_user_id (uuid), created_at

- household_members
  - id, household_id, user_id, role (owner/member), invited_at, accepted_at

- bills
  - id, household_id, created_by (user_id), payee, name, amount_cents, currency (INR), generation_date, due_date, recurrence (none/monthly/quarterly/yearly), notes, status (unpaid/paid), last_generated_at, created_at, updated_at

- reminders
  - id, bill_id, notify_at (timestamp), channel (email,inapp), sent_at, status (pending/sent/failed), attempts

- payments
  - id, bill_id, user_id, amount_cents, paid_at, method, receipt_url, created_at

- attachments
  - id, bill_id, uploaded_by, file_path, file_size, content_type, uploaded_at

- invites
  - id, household_id, email, token, status, invited_by, created_at, accepted_at

Key API/Backend responsibilities
- Auth: handled by Supabase; frontend calls Supabase SDK for sign-in/up and social providers.
- Bills CRUD and payments: use Supabase REST or serverless functions (edge functions) for complex operations and scheduled jobs.
- Scheduling reminders: a small serverless job (Supabase edge function or cron) that runs hourly to enqueue/send reminders according to the reminders table and user preferences.
- Email delivery: via Supabase SMTP or third-party transactional provider (SendGrid) configured in Supabase.

Reminder scheduling rules (v1)
- Pre-generation: schedule a notification 2 days before the bill's generation_date (email + in-app).
- Post-generation: if generation_date <= today and bill.status == unpaid, schedule daily reminders at the user's preferred hour until paid.

CSV import specification
- Required columns: payee, bill_name, amount, currency, generation_date
- Optional columns: due_date, recurrence (none|monthly|quarterly|yearly), reminder_offsets (semicolon-separated integers in days before generation), notes
- Validation rules: amount must be numeric, generation_date and due_date must be ISO date strings (YYYY-MM-DD), currency must be INR for v1.

Wireframes / Screens (descriptions)
- Onboarding: sign-up/sign-in screen with social buttons and email form. Quick setup asks for timezone (default IST) and household creation.
- Home / Dashboard: upcoming bills list (sorted by next due/generation date), quick "Add bill" CTA, summary tile (bills due this week, bills overdue).
- Bill detail: full bill info, reminder schedule, attachments, history (payments and reminders), Mark as paid button.
- Add / Edit bill: form with fields above, upload receipt button, recurrence controls, per-bill reminder controls.
- Household management: invite member modal and member list.

Acceptance criteria (MVP)
- Users can sign up and sign in via email and the listed social providers.
- Users can create a household and invite at least one other member via email; invitees can accept and see shared bills.
- Users can add bills manually and via CSV import (validated) and attach receipts up to 5 MB.
- The system sends a reminder email and in-app notification 2 days before generation date and daily after generation until paid.
- Users can mark a bill as paid and optionally add payment details and receipt; reminders stop for that bill and calendar events update.
- Google Calendar sync can create calendar events and reflect status changes.

Timeline & milestones (1-week MVP delivery)
Day 1: Project setup, Supabase project, auth providers configured, Vercel project created. Basic React app scaffold and mobile-first layout.
Day 2: Bills CRUD, database schema applied, CSV import UI and validation.
Day 3: Reminder scheduling job, in-app notification center, email sending setup.
Day 4: Receipts (Supabase storage) and mark-as-paid flow.
Day 5: Household invites and permissions, Google Calendar sync implementation.
Day 6: QA, acceptance tests, address bugs.
Day 7: Deploy to production (Vercel), monitor, and handoff.

Risks & mitigations
- Risk: Email deliverability issues. Mitigation: use reputable transactional email provider and include unsubscribe / opt-out options.
- Risk: Scheduling delays or duplicate reminders. Mitigation: store reminder status, limit retries, and dedupe by bill+date.
- Risk: File storage costs or abuse. Mitigation: limit attachment sizes (5 MB), restrict file types, and scan/validate uploads.

Privacy & Security
- No bank credentials or financial account scraping in v1.
- Use Supabase Row-Level Security (RLS) to ensure households only access their data.
- Encrypt attachments at rest via Supabase storage defaults and restrict public URLs.
- Provide data export (CSV) and account deletion flow.

QA checklist (short)
- Signup/Login flows (email + each social provider)
- Add/Edit/Delete bill
- CSV import edge cases: missing columns, malformed dates, invalid amounts
- Attachment upload size/type enforcement
- Reminder scheduling: pre- and post-generation daily reminders
- Mark-as-paid stops reminders and updates calendar
- Household invite flow and permission checks

Open questions / future roadmap
- SMS notifications (next phase) and phone OTP login.
- Bank/provider integrations for automatic bill detection.
- Multi-currency and timezone support.
- Advanced recurrence rules (cron-like scheduling).

Appendix: example CSV (header + one row)

payee,bill_name,amount,currency,generation_date,due_date,recurrence,reminder_offsets,notes
Electricity,June Bill,1234.50,INR,2025-06-10,2025-06-20,monthly,2;1,"Account 1234"

---

Next steps available (pick any):
- I can generate a prioritized task list (GitHub issues) and a checklist for the 1-week plan.
- I can produce a minimal DB migration SQL for Supabase and a starter React scaffold (pages, components, and example forms) wired to the Supabase client.

