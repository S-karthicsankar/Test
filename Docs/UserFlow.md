(This document describes the user flows for the Bills Reminder app. It is derived from the PRD and focuses on core flows, UI screens, success / failure states, edge cases, and acceptance criteria.)

Last updated: 2025-10-04

Scope
- High-level flows for all features.
- Step-by-step (screen-by-screen) flows for core features: Authentication & onboarding, Add bill (manual), CSV import (with preview/skip invalid rows), Mark as paid, Household invite/accept, Google Calendar sync, and reminders handling.
- Simple ASCII/annotated wireframes for core screens.

Goals for these flows
- Make it fast to set up an account and start tracking bills.
- Make adding bills (single or CSV import) reliable and forgiving; allow invalid rows to be skipped in the CSV preview.
- Ensure reminders are predictable: 2 days before generation date (email + in-app) and daily after generation until paid.
- Provide a clear path to mark bills paid and stop reminders; keep payment history.

Global UI primitives and conventions
- Mobile-first layouts; controls sized for thumb interaction.
- Primary CTA color for actions like Add bill, Mark paid, and Accept invite.
- Toasts: brief success/failure messages.
- Notification center: persistent list of unread and recent notifications.

High-level flows
- Authentication & Onboarding
- Dashboard / Home
- Add Bill (manual)
- Add Bills (CSV import)
- Bill Detail & Mark as Paid
- Household invite & membership
- Reminders & Notification center
- Google Calendar sync
- Settings & Preferences

Detailed core flows (step-by-step)

1) Authentication & Onboarding (core flow)

Purpose: let a user create an account quickly and set required defaults (timezone/currency, household).

Entry points
- /signup
- /login

Screens & steps
1. Signup screen
	- Elements: Email field, Password, Confirm password, Social buttons (Google, Apple, GitHub), CTA "Create account".
	- Validations: email format, password min length (8). Show inline errors.
	- Success: user is created in Supabase and session established.

2. Quick setup (only shown on first login)
	- Elements: "Create household" (name) or "Use personal account" toggle, timezone (default IST, non-editable but confirm), currency (INR), notification preferences (email on by default, in-app on by default), optional profile name.
	- Outcome: household created (if chosen) and user directed to Dashboard.

3. Email verification (optional depending on Supabase settings)
	- If email verification required, show a waiting screen with CTA to resend verification and an explanation.

Wireframe: Signup / Quick setup (mobile)

  [ Signup ]
  -------------------------------
  | Logo                          |
  | Email [__________]            |
  | Password [________]           |
  | [Create account] [Google]     |
  |                               |
  -------------------------------

Acceptance criteria
- New user can sign up using email/password or social providers and reach the dashboard after completing setup.

Edge cases
- Social login email matches existing account: show merge/choose flow.
- Network failure during signup: show retry and persist entered form values.

2) Dashboard / Home (core)

Purpose: show upcoming bills, quick status, and access to add/import.

Primary elements
- Upcoming list (sorted by next generation_date or due_date).
- Summary tiles: This week due, Overdue, Unpaid count.
- Quick actions: Add bill, Import CSV, Sync Calendar, Invite member.
- Notification bell (opens notification center).

Wireframe (compact)

  [Header: App name | bell(3)]
  [Summary tiles: Due this week | Overdue | Unpaid]
  [Upcoming list]
  - Electricity — 10 Jun — INR 1,234  [Details]
  - Internet — 12 Jun — INR 499      [Details]
  [FAB: + Add bill]  [Import CSV]

Acceptance criteria
- Dashboard loads within reasonable time (network dependent) and displays next 30 days of bills.

3) Add Bill — Manual (core)

Purpose: let users add a single bill quickly.

Entry
- Dashboard FAB or Add bill CTA.

Form fields
- Payee (required)
- Bill name (required)
- Amount (required) — validate numeric, store as cents
- Currency (fixed INR)
- Generation date (required) — date when the bill is generated or becomes due
- Due date (optional)
- Recurrence (none | monthly | quarterly | yearly)
- Reminder offsets (default prefilled with 2 — means 2 days before generation; allow adding more pre-reminders)
- Repeat daily after generation (toggle; default true for v1)
- Notes (optional)
- Attach receipt (optional) — accept jpg/png/pdf, max 5 MB

Validation & UX
- Inline validation: amount numeric, generation date present.
- Upload progress and size validation for attachments.
- CTA: Save (primary), Cancel.

Success path
- Save persists the bill to Supabase, schedules reminders (rows in reminders table or scheduled job will pick it up), and (if calendar sync enabled) creates or schedules a calendar event.
- Toast: "Bill saved — reminders scheduled."

Wireframe (Add Bill)

  [Add Bill]
  Payee: [Electricity]  
  Name:  [June bill]
  Amount: [1234.50] INR
  Generation: [2025-06-10]
  Recurrence: [monthly]
  Reminder offsets: [2] [+ add]
  Attach: [upload area]
  [Save]  [Cancel]

Acceptance criteria
- User can add a bill with required fields and optional attachment; reminders are scheduled; a calendar event is created if calendar sync is enabled.

Edge cases
- Attachment > 5MB: show error and reject upload.
- Missing required fields: block save and show inline errors.

4) Add Bills — CSV Import (core)

Purpose: allow bulk import with preview and per-row validation; let user skip invalid rows.

Entry
- Dashboard: Import CSV button.

Flow steps
1. Upload CSV file (drag/drop or file picker)
	- Show file size and brief guidance (expected columns: payee,bill_name,amount,currency,generation_date,due_date,recurrence,reminder_offsets,notes).

2. Parse & preview
	- Show header mapping UI (auto-map if headers match; allow user to map columns if not).
	- Show a preview table of the first N rows with per-row validation results (valid / invalid + error message).
	- For invalid rows, show the specific error (e.g., "amount not numeric", "invalid date format", "currency must be INR").

3. User action on preview
	- Options: "Skip invalid rows and import valid rows" (recommended), "Fix CSV and try again", or "Cancel import".
	- Also provide an "Export invalid rows" button to download a CSV of problematic rows for offline fixes.

4. Import execution
	- Import valid rows, create bills, and upload any attachments referenced (attachments in CSV not supported in v1).
	- Show progress and a final summary: imported X rows, skipped Y rows, failed Z rows.

5. Post-import
	- Link to newly created bills in the dashboard and show a toast summary.

Wireframe: CSV preview (simplified)

  [CSV Import]
  Map columns: payee -> payee, bill_name -> bill_name, amount -> amount
  Preview:
  Row | payee | bill_name | amount | status
  1   | Electricity | June | 1234.50 | Valid
  2   | Water       | May  | abc     | Invalid: amount not numeric

  [Skip invalid rows and import valid rows]  [Fix CSV]

Acceptance criteria
- CSV import allows mapping headers, validates rows, and imports valid rows while offering to skip invalid rows.

Edge cases
- Large CSV (> 5,000 rows): show warning and recommend smaller batches for MVP.
- Malformed CSV: surface parsing errors and instructions to fix.

5) Bill Detail & Mark as Paid (core)

Purpose: show full bill information, history, attachments, and allow marking as paid.

Primary elements
- Bill header: payee, bill name, amount, status (unpaid/paid), next generation date
- Reminder schedule and next notification
- Attachments (receipt thumbnails) with download/view
- History: list of payments and reminder sends
- Actions: Mark as paid, Edit, Delete, Share

Mark as paid flow
1. User taps "Mark as paid" on bill detail or a quick action in the list.
2. Show Mark-as-paid modal:
	- Fields: amount paid (prefill from bill amount), payment date (default today), payment method (text), upload receipt (optional)
	- CTA: Confirm payment
3. On confirm:
	- Create payment record, store optional receipt (Supabase storage), update bill status to paid, cancel scheduled reminders for that bill, update related calendar event (mark as done or remove), and show success toast.

Acceptance criteria
- Marking a bill paid records a payment and stops further reminders for that bill; calendar events are updated accordingly.

Edge cases
- Partial payment: accept amount less than bill amount; leave bill status as unpaid if partial (or optionally allow user to mark fully paid). For MVP, encourage full payment but accept partial amounts and record them.

6) Household invite & membership (core)

Purpose: let a household owner invite members by email and allow invitees to accept and share bills.

Invite flow (owner)
1. Owner opens Household > Invite member.
2. Enter email, optional note, click Send invite.
3. System creates invite row and sends email with invite link and token.

Accept flow (invitee)
1. Invitee clicks link in email, arrives at app. If not authenticated, user is asked to sign in / sign up.
2. After authentication, the app validates the token and shows an "Accept invite" screen with household name and permissions summary.
3. On accept, link user to household (create household_member row) and redirect to household Dashboard.

Edge cases
- Invite link expired: show ability to request a new invite.
- Email already a member: show message and list household.

7) Reminders & Notification center

Behavior
- Pre-generation: email + in-app notification 2 days before generation_date.
- Post-generation: if bill is unpaid, send daily email + in-app reminders until paid.
- In-app toast for immediate feedback; notification center stores a timeline of recent notifications with links to bill details.

Notification center screens/UX
- List notifications with status (unread/read), timestamp, short message, and quick actions (Mark as read, Mark paid link).

Edge cases
- Duplicate notifications: the scheduler checks reminders table and sent_at to avoid duplicates.

8) Google Calendar sync

Purpose: create calendar events for upcoming bills and keep them in sync when bills change.

Flow
1. User clicks "Sync Calendar" and is taken through Google OAuth flow requesting write access.
2. After consent, the user chooses which calendar to use (primary or list of calendars).
3. System creates events for upcoming generation_dates (next 12 months or based on recurrence rule) with a link to the bill detail in the app.
4. When a bill is marked paid or dates change, update or delete the corresponding calendar events.

Acceptance criteria
- Calendar sync requests write permission, creates events, and updates or cancels events when bills change.

Edge cases
- Revoked OAuth token: handle refresh errors gracefully and surface a re-auth request in Settings.

9) Settings & Preferences

Key items
- Notification preferences (email toggle, in-app toggle)
- Default reminder offsets (default 2 days, daily after generation enabled)
- Calendar sync management (connect/disconnect, select calendar)
- Account: export data (CSV), delete account

Acceptance criteria
- Users can update preferences and see immediate effect for new reminders; they can export account data and delete account.

Acceptance criteria summary (core flows)
- Users can sign up / sign in and complete onboarding.
- Users can add a single bill and receive scheduled reminders (2 days before and daily after generation until paid).
- Users can import CSV files, map columns, preview rows, skip invalid rows, and import valid rows.
- Users can mark bills as paid, which records payments, stores optional receipts, stops reminders, and updates calendar events.
- Owners can invite household members by email and invitees can accept and see shared bills.
- Users can connect Google Calendar and choose a calendar to sync events; events update on status changes.

Quality & edge-case notes
- Rate limiting and background job retries: scheduler will mark attempts and avoid infinite retries.
- Export of invalid CSV rows for user debugging.
- RLS and permission checks: every UI action that reads/writes data assumes the backend enforces row-level security.

Appendix: short UI keyboard / accessibility notes
- All form fields must be reachable via keyboard and have clear labels for screen readers.
- Provide sufficient color contrast for CTAs and status badges (paid/unpaid).

Next steps after this file
- I can implement a compact task list from these flows (tickets for UI screens, API endpoints, migrations, and cron jobs).
- I can also generate UI mockups (Figma/PNG) or scaffold component templates in the React app.

