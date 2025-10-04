# React + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/create-vite/template-react-ts) uses [SWC](https://swc.rs/) for Fast Refresh

## React Compiler

The React Compiler is not enabled on this template. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.

---

Project-specific notes (Bills Reminder MVP)
-----------------------------------------

Environment variables required for local development:

- SUPABASE_URL - your Supabase project URL
- SUPABASE_ANON_KEY - anon/public key for frontend
- SUPABASE_SERVICE_ROLE - service role key (do NOT expose to frontend; used only by Edge Functions)
- GOOGLE_CLIENT_ID - for Calendar OAuth (optional for initial setup)

Local dev
---------

Install and run the frontend dev server:

```cmd
npm install
npm run dev
```

Edge Functions & Migrations
---------------------------

- Migrations are located under `db/migrations/`. Apply them with the Supabase CLI or your preferred method. Example using Supabase CLI (requires login and project-ref):

```cmd
supabase db push --project-ref <project-ref>
```

- Edge Functions scaffolds are under `supabase/functions/`. Deploy and schedule the `reminder-worker` function as described in `supabase/functions/reminder-worker/README.md`.

Docs
----
See the `Docs/` folder for architecture, database schema, and the project tasklist.
