Reminder Worker (Supabase Edge Function)

Purpose
-------
Hourly scheduled worker that materializes and sends reminders for due bills. The function is a scaffold and demonstrates how to query `reminders`, insert `notifications`, and mark reminders as sent.

Environment
-----------
- SUPABASE_URL: your Supabase project URL
- SUPABASE_SERVICE_ROLE: service role key (must be kept secret and used only by this Edge Function)

Deployment
----------
1. Install Supabase CLI and log in: `supabase login`.
2. From the repo root, deploy functions folder: `supabase functions deploy reminder-worker --project-ref <project-ref>`.
3. Schedule the function hourly in Supabase dashboard or using cron config in the Supabase CLI.

Notes
-----
- This is a scaffold. Implement actual sending logic (SendGrid/SMTP) and recipient resolution before enabling in production.
- Ensure the service role key is set in the function's environment and not exposed to the frontend.
