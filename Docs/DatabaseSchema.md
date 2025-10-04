Database Schema — Bills Reminder

Last updated: 2025-10-04

This document contains the database schema, important constraints, indexes, and Row-Level Security (RLS) policies designed for the v1 MVP using Supabase (Postgres).

Notes
- User accounts are managed by Supabase Auth (auth.users). All user IDs referenced here are UUIDs produced by Supabase Auth.
- Currency for v1 is fixed to INR; amounts are stored as integer paise (amount_cents bigint).

Tables and migrations

1) households
SQL:
```sql
CREATE TABLE households (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  owner_user_id uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);
```

2) household_members
SQL:
```sql
CREATE TABLE household_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid REFERENCES households(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id),
  role text NOT NULL CHECK (role IN ('owner','member')) DEFAULT 'member',
  invited_at timestamptz,
  accepted_at timestamptz
);
CREATE INDEX idx_household_members_household_id ON household_members(household_id);
```

3) bills
SQL:
```sql
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
  recurrence text NOT NULL DEFAULT 'none',
  repeat_daily_after_generation boolean DEFAULT true,
  notes text,
  status text NOT NULL DEFAULT 'unpaid',
  last_generated_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX idx_bills_household_generation ON bills(household_id, generation_date);
```

4) reminders
SQL:
```sql
CREATE TABLE reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid REFERENCES bills(id) ON DELETE CASCADE,
  notify_at timestamptz NOT NULL,
  channel text NOT NULL CHECK (channel IN ('email','inapp')),
  sent_at timestamptz,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sent','failed')),
  attempts int DEFAULT 0
);
CREATE INDEX idx_reminders_notify_status ON reminders(notify_at, status);
```

5) payments
SQL:
```sql
CREATE TABLE payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid REFERENCES bills(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id),
  amount_cents bigint NOT NULL,
  paid_at timestamptz NOT NULL,
  method text,
  receipt_url text,
  created_at timestamptz DEFAULT now()
);
```

6) attachments
SQL:
```sql
CREATE TABLE attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid REFERENCES bills(id) ON DELETE CASCADE,
  uploaded_by uuid REFERENCES auth.users(id),
  file_path text NOT NULL,
  file_size int NOT NULL,
  content_type text,
  uploaded_at timestamptz DEFAULT now()
);
```

7) invites
SQL:
```sql
CREATE TABLE invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid REFERENCES households(id) ON DELETE CASCADE,
  email text NOT NULL,
  token text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','revoked')),
  invited_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  accepted_at timestamptz
);
```

Optional: notifications (in-app)
```sql
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  household_id uuid REFERENCES households(id),
  bill_id uuid REFERENCES bills(id),
  type text,
  message text,
  url text,
  read_at timestamptz,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
```

RLS Policies (examples)
General guidance: enable RLS on tables that contain household-scoped data and create policies that check membership in `household_members`.

Enable RLS
```sql
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

Example policy: allow household members to SELECT bills
```sql
CREATE POLICY "select_bills_if_member" ON bills
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM household_members hm
      WHERE hm.household_id = bills.household_id
        AND hm.user_id = auth.uid()
    )
  );
```

Example policy: allow household members to INSERT bills (must set household_id to a household they belong to)
```sql
CREATE POLICY "insert_bills_if_member" ON bills
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM household_members hm
      WHERE hm.household_id = NEW.household_id
        AND hm.user_id = auth.uid()
    )
  );
```

Invite policy notes
- Invite creation should be limited to household owners or members depending on the product decision. For v1, limit to owners only.

Example policy: only owner can insert invites
```sql
CREATE POLICY "owners_only_insert_invites" ON invites
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM household_members hm
      WHERE hm.household_id = NEW.household_id
        AND hm.user_id = auth.uid()
        AND hm.role = 'owner'
    )
  );
```

Attachments & Storage integration notes
- Attachments are stored in Supabase Storage `receipts` bucket. Keep files private and use signed URLs for download.
- Use triggers or server-side checks during upload to validate file size and content type. For example, verify content_type in an Edge Function before storing metadata.

Indexes & maintenance
- Consider a scheduled VACUUM / ANALYZE for large tables; monitor indexes and query plans for the reminders worker to ensure it remains performant.

Backfilling & recurring bills
- Recurring bills: implement a materialization process that runs daily (edge function) to create new bill instances or reminders when recurrence triggers. Track `last_generated_at` on `bills` to avoid duplicates.

Testing & verification
- Integration tests should create temporary households and users (via Supabase test project) and validate RLS policies by attempting reads/writes as different users.

Migration hints
- Use a migrations tool compatible with Postgres (pg-migrate, Flyway, or Supabase CLI migrations) and store migrations under `db/migrations/`.

Next steps
- I can generate a full SQL migration file with the above tables and RLS policies and place it in `db/migrations/`.
- I can also scaffold minimal integration tests that verify RLS policies using the Supabase test instance.
