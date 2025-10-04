Design Strategy — Bills Reminder

Last updated: 2025-10-04

Purpose
- This document captures the UX and frontend design strategy for the Bills Reminder MVP. It maps product requirements and user flows into concrete UI/UX principles, component patterns, accessibility goals, layout rules, CSS conventions, and testing guidelines.

Design principles
- Mobile-first: prioritize a clean, thumb-friendly mobile experience. Desktop should be responsive and functional, not just scaled up.
- Fast & focused: minimize friction for core tasks (add bill, mark paid, import CSV, accept invite). Default values and sensible presets (INR, IST, 2-day pre-reminder) speed onboarding.
- Clear affordances: primary CTAs must stand out. Use consistent spacing, labels, and iconography.
- Progressive disclosure: hide advanced options by default (detailed recurrence settings, multiple reminder offsets) but keep them reachable.
- Privacy by design: make attachments private by default and provide export/delete options in account settings.

Key user journeys & UI patterns
- Onboarding: single-screen signup + quick setup dialog to choose household or personal account and confirm timezone/currency.
- Dashboard: prioritized list of upcoming bills with summary tiles. Provide quick inline actions (Mark as paid, Snooze later — deferred to next phase) from each row.
- Add Bill form: step-reduced form with inline validation and optional advanced panel for recurrence and reminder customization.
- CSV import: drag-and-drop panel, header auto-mapping, row preview with single-click skip for invalid rows.
- Bill detail: timeline-style history (payments, reminders), attachments gallery, and the Mark as Paid modal.
- Notification center: bell icon with a small badge count; persistent list that supports quick actions (Mark as read, Mark paid link).

Visual language & components
- Colors: choose a single primary color for CTAs and 1-2 accent colors for status (paid = green, unpaid/overdue = red/orange).
- Typography: system font stack for performance; sizes tuned for mobile legibility (16px body base, 18-20px for CTAs).
- Spacing: 8px baseline grid; components use multiples of 8 for padding/margins.
- Icons: use an open icon set (Heroicons or similar) for clarity and small bundle size.

Component library (small set for MVP)
- Button (Primary, Secondary, Ghost)
- Input (text, number, date, textarea)
- Select / Autocomplete
- Modal / Bottom sheet (for Mark as paid and Add bill on mobile)
- Toast & Notification center
- File upload (with preview and progress)
- Table / List with inline actions (for CSV preview and dashboard list)

Layout & responsive rules
- Breakpoints: mobile-first with a max width container at 768px for tablet and 1024px+ for desktop layouts.
- Use CSS Grid for dashboard summary tiles and Flexbox for lists to keep layout predictable.
- Mobile interactions: use bottom-sheet modals for Add/Edit on small screens to avoid long vertical scrolling.

State management & data fetching
- Use React Query (or SWR) patterns for caching remote data with Supabase client: keep server state in sync and show optimistic UI for Mark as Paid and quick edits.
- Form handling: use React Hook Form for efficient form state and validation.
- Authentication: use Supabase JS SDK for session management; persist session across reloads.

CSS strategy
- Plain CSS as requested: use a small, well-organized stylesheet structure (CSS modules or BEM naming) to avoid global collisions.
- Keep styles atomic and reusable: variables for colors, spacing, and typography in a single file (variables.css).
- Avoid large utility frameworks for MVP; prefer hand-crafted small utilities.

Accessibility
- All form fields must have labels and aria descriptions where helpful.
- All interactive elements must be keyboard reachable and have focus-visible styling.
- Color contrast: ensure a 4.5:1 contrast for body text and 3:1 for large headings; status badges should remain readable.
- Provide alt text for attachments and aria-live announcements for key events (e.g., "Bill saved", "CSV import completed").

Performance
- Lazy-load heavy components (CSV parser, calendar connectors) only when used.
- Keep initial JS bundle small: avoid large UI libraries; use selective icons and code-splitting.
- Use Supabase realtime features selectively to avoid unnecessary websocket connections.

Testing strategy
- Unit tests: small snapshots and behavior tests for components (React Testing Library + Jest).
- Integration tests: simulate core flows (signup, add bill, mark paid, CSV import preview) with Playwright or Cypress.
- End-to-end: a minimal smoke test to run on every deploy (sign up, add a bill, ensure reminders scheduled row exists in DB).

Design deliverables for the 1-week MVP
- Day 1: Basic component library and mobile layout (Header, Dashboard list, Add Bill modal).
- Day 2: Forms and CSV import UI (preview and mapping).
- Day 3: Notification center, Mark-as-paid modal, and attachments UI.
- Day 4: Calendar sync UI and settings pages.
- Day 5–7: QA, polish, accessibility fixes, and deploy.

UX microcopy guidance
- Keep labels short and action-oriented: "Add bill", "Mark as paid", "Import CSV".
- Reminder emails should have a clear CTA that links to the bill and a single-action button to acknowledge or mark paid.

Open UI decisions / follow-ups
- Confirm primary CTA color and brand name to produce final mockups.
- Decide whether to use CSS modules vs global CSS variables file; my recommendation: CSS modules + a shared variables.css for colors and spacing.

Next steps
- I can scaffold the React component templates and CSS variables and wire up basic auth + dashboard using Supabase client.
- Or I can create quick PNG wireframes for the core screens if you prefer visual references before implementation.
