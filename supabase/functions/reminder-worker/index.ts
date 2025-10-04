// Reminder worker scaffold (no external deps)
// This file intentionally avoids static imports so the repo linter/typechecker
// doesn't require external packages at this stage. Replace with a full
// implementation that uses the Supabase service role key and a mailer (SendGrid)
// when ready to deploy.

export default async function handler(_req: any) {
  console.log('Reminder worker scaffold invoked')
  // TODO: implement:
  // - Initialize Supabase client with service role key
  // - Query `reminders` table for due reminders
  // - Send emails (SendGrid/SMTP) and insert `notifications`
  // - Update `reminders` rows with sent=true or increment attempts on failure

  return new Response(JSON.stringify({ processed: 0 }), { status: 200 })
}
