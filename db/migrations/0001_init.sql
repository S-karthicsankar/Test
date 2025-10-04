-- Initial migration for Bills Reminder MVP
-- Creates core tables: households, household_members, bills, reminders, payments, attachments, invites, notifications

BEGIN;

-- Households
CREATE TABLE IF NOT EXISTS households (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  owner uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- Household members
CREATE TABLE IF NOT EXISTS household_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text DEFAULT 'member',
  created_at timestamptz DEFAULT now(),
  UNIQUE (household_id, user_id)
);

-- Bills
CREATE TABLE IF NOT EXISTS bills (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  amount_cents bigint NOT NULL,
  currency text NOT NULL DEFAULT 'INR',
  due_date date NOT NULL,
  recurrence jsonb,
  status text NOT NULL DEFAULT 'open', -- open | paid | cancelled
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Reminders (materialized reminders to be processed by worker)
CREATE TABLE IF NOT EXISTS reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
  remind_at timestamptz NOT NULL,
  sent boolean DEFAULT false,
  sent_at timestamptz,
  attempts int DEFAULT 0,
  last_error text,
  created_at timestamptz DEFAULT now()
);

-- Payments (mark-as-paid records)
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
  amount_cents bigint NOT NULL,
  paid_by uuid REFERENCES auth.users(id),
  paid_at timestamptz DEFAULT now(),
  method text,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Attachments / receipts metadata
CREATE TABLE IF NOT EXISTS attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid REFERENCES bills(id) ON DELETE CASCADE,
  uploaded_by uuid REFERENCES auth.users(id),
  storage_path text NOT NULL,
  filename text,
  content_type text,
  size_bytes int,
  created_at timestamptz DEFAULT now()
);

-- Invites for household sharing
CREATE TABLE IF NOT EXISTS invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  email text NOT NULL,
  token text NOT NULL,
  role text DEFAULT 'member',
  created_by uuid REFERENCES auth.users(id),
  accepted boolean DEFAULT false,
  accepted_by uuid REFERENCES auth.users(id),
  accepted_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- In-app notifications
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  household_id uuid REFERENCES households(id),
  type text,
  payload jsonb,
  read boolean DEFAULT false,
  delivered boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_bills_household_id ON bills(household_id);
CREATE INDEX IF NOT EXISTS idx_reminders_remind_at ON reminders(remind_at);
CREATE INDEX IF NOT EXISTS idx_payments_paid_at ON payments(paid_at);
CREATE INDEX IF NOT EXISTS idx_attachments_bill_id ON attachments(bill_id);
CREATE INDEX IF NOT EXISTS idx_invites_token ON invites(token);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

COMMIT;

-- NOTES:
-- - Amounts are stored in integer cents (paise) as required by project conventions.
-- - RLS policies should be applied after migrations are created. See Docs/DatabaseSchema.md for recommended policies.
