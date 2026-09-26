SKILLLINK FINAL PRODUCTION PACKAGE

1) Supabase
- Open your current Supabase project.
- Run skilllink_final_production.sql in SQL Editor. It is designed to be re-runnable, but review any existing custom data before replacing a production schema.
- Create users in Authentication > Users.
- Assign CEO role with the SQL shown at the end of the SQL file.

2) Frontend
- index.html already contains the current Supabase URL and PUBLISHABLE key.
- Never put a service_role/secret key in this file or GitHub.

3) GitHub
- Upload/replace the repository root index.html and skilllink_final_production.sql.
- Do not upload any .env containing secrets.

4) Vercel
- Keep the GitHub repository connected.
- Redeploy after commit.

5) Auth redirect
- In Supabase Authentication > URL Configuration, set Site URL to your exact Vercel URL.
- Add your Vercel URL and / ** redirect if required.

6) Role tests
- CEO -> CEO management dashboard
- Admin -> operations dashboard + own earnings/withdrawal only
- Partner -> learning, projects, referrals, own earnings/withdrawal, levels/rewards
- Client -> projects and client workflow

7) Final SkillLink flow
Package -> Course -> Videos/Lessons -> Test -> Pass -> Certificate.
CEO publishes daily Masterclass -> it appears to all roles.
Partner/Admin request only their own withdrawal -> CEO approves.

NOTE
This package is the consolidated deploy foundation. Some advanced CRUD workflows (full visual course editor, complete client messaging/disputes, automated commission/referral attribution, and PDF certificate generation) require additional implementation beyond this single-file deploy core. The database tables and role structure for these areas are included so they can be built without changing the core architecture.
