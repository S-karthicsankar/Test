For AI coding assistants working on this repository (Bills Reminder MVP)

Keep this short, actionable and repository-specific. Use it to bootstrap changes and complete tasks with minimal back-and-forth.

Big picture (what this repo is)
- Frontend: React + Vite single-page app (mobile-first). Key files: `src/App.jsx`, `src/main.jsx`, styles in `src/*.css`.
- Backend & infra (design only in docs): Supabase (Postgres + Auth + Storage + Edge Functions). DB schema and RLS policies are documented under `Docs/DatabaseSchema.md` and `Docs/System_Architecture.md`.
- Docs: `Docs/PRD.md`, `Docs/UserFlow.md`, `Docs/System_Architecture.md`, `Docs/DatabaseSchema.md`, `Docs/DesignStrategy.md`, `Docs/tasklist.md` contain the product and tech decisions—read them before making architectural changes.

Where to make changes
- Frontend code lives in `src/`. Keep changes small and isolated: add new components under `src/components/`, pages under `src/pages/`, and wire routing in `src/main.jsx` or `src/App.jsx`.
- Backend code (Edge Functions) should be added under a `supabase/functions/` folder (not present yet). Use TypeScript for edge functions.
- DB migrations should go under `db/migrations/` (create this if missing) and follow the SQL shown in `Docs/DatabaseSchema.md`.

Developer workflows & commands (how to run and test locally)
- Start frontend dev server:
  - Install: `npm install`
  - Dev: `npm run dev` (uses Vite). Default shell is `cmd.exe` on Windows; adjust commands accordingly.
- Build for production: `npm run build` and preview with `npm run preview`.
- Lint: `npm run lint` (ESLint is configured in repo root).

Supabase & environment notes (critical)
- This repo expects a Supabase project. Key ENV variables (documented in `Docs/*`): `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE` (service role must never be embedded in frontend code). For Calendar OAuth: `GOOGLE_CLIENT_ID`.
- Edges/Server tasks (CSV parsing, reminder worker, calendar token exchange) must use server-side service role keys and be implemented as Supabase Edge Functions (TypeScript) and called by the frontend only when necessary.

Project-specific conventions & patterns
- Plain CSS: project uses plain CSS (see `src/App.css`), avoid introducing large CSS frameworks. Use small utility classes and component-level styles under `src/`.
- Money handling: amounts are stored as integer paise (amount_cents bigint in DB). Always convert on UI (divide by 100) when showing currency.
- Timezone/currency: v1 targets IST and INR only. Use `date-fns` in code for date operations and keep display in local IST.
- Recurrence & reminders: reminder scheduling is two-fold: pre-generation reminders (2 days prior) and daily reminders post-generation until marked paid. Implement server-side logic for scheduling or materialization; do not attempt to implement reliable scheduling in the browser.

Key files to read before coding
- `Docs/PRD.md` — Product scope, features, constraints.
- `Docs/UserFlow.md` — Step-by-step UI flows and acceptance criteria.
- `Docs/System_Architecture.md` — High level architecture, Edge function list, reminder worker design.
- `Docs/DatabaseSchema.md` — SQL for tables, indexes, and RLS policy examples.
- `package.json` — scripts and frontend dependencies.

Testing & validation expectations for AI-generated edits
- Make focused edits and run `npm run dev` locally to catch syntax/HMR errors. Fix lint errors from `npm run lint` where obvious.
- For any DB schema changes, produce migration SQL and add to `db/migrations/`. Mention the exact Supabase CLI command needed to apply (e.g., `supabase db push` or `supabase migrations deploy`) in your commit message.
- When adding Edge Functions, include a small TypeScript example and a brief README explaining how to deploy using Supabase CLI.

Examples & code patterns
- Converting amount for UI: show cents -> rupees: `const rupees = amount_cents / 100` and format with Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).
- RLS-aware DB calls: prefer Supabase client calls from frontend for CRUD when RLS is sufficient, otherwise use an Edge Function with service role key for elevated operations (CSV import, calendar token storage, reminder worker).
- CSV import preview: prefer server-side parsing (Edge function) for consistent validation (dates, currency); the preview endpoint should return per-row errors so the UI can show skip/fix options.

Commit & PR guidance for AI agents
- Keep PRs small and single-purpose. Each PR should reference the related task in `Docs/tasklist.md`.
- Include a brief README or snippet when adding infra code (Edge Functions, migrations) explaining deployment steps and any required env vars.
- When you complete a task listed in `Docs/tasklist.md`, update that file before opening the PR:
  - Mark the task as done using the markdown checkbox (`- [x] Task description`).
  - Add a one-line reference to the PR number or commit hash next to the task (example: `- [x] Create DB migrations — PR #12`).
  - In the PR description, include a short "tasklist delta" that lists which tasks were completed by the PR.
  This ensures the task list remains the single source of truth for progress.

When to ask for human review
- Any change to RLS policies, DB schema, or service role usage must be explicitly flagged for human review in the PR description.
- Any choice that affects user data retention or privacy (deleting user data, exporting data) must be reviewed.

If something is unclear
- Stop and ask: mention which Doc(s) you read and which part is ambiguous (e.g., "PRD says default reminders 2 days before — do you want 7 days too?"), include concrete options.

Maintainers & docs
- Primary docs live in `Docs/`. Keep them updated when you implement features. If you change a schema or API, update `Docs/DatabaseSchema.md` and `Docs/System_Architecture.md` accordingly.

Quick checklist for a typical task (e.g., add bill form + backend)
1. Read `Docs/UserFlow.md` > Add Bill section.
2. Implement UI component under `src/components/AddBill/` and page under `src/pages/`.
3. Add minimal DB migration if needed and place SQL in `db/migrations/`.
4. Wire Supabase client calls (ensure RLS policy covers the action) or create Edge Function if service role required.
5. Run `npm run dev` and `npm run lint`. Add tests if appropriate.
6. Open PR describing changes, updated docs, and any infra steps.

End of file
