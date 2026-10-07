-- LiveScreen — DEV/DEMO SEED ONLY. Do not run against a real production
-- database with real customers' theatres — this seed matches theatres BY
-- NAME ('Broadway', 'misri', 'tavi', 'MiVa Screens') and will attach to
-- any existing theatre with one of those names.
--
-- Run this ONLY after 0004_theatre_admin_identity.sql, and only in a
-- dev/demo Supabase project. It does not touch RLS, and does not weaken
-- anything — it only INSERTs rows through the same policies every other
-- admin goes through (it runs as whatever role executes it in the SQL
-- Editor, which bypasses RLS there, but the rows it creates are shaped
-- exactly like ones a real registration + Platform Admin approval would
-- produce).
--
-- ---------------------------------------------------------------------
-- STEP 1 — MANUAL, in Supabase Dashboard -> Authentication -> Users
-- (same as the four existing demo accounts in SUPABASE_SETUP.md; Supabase
-- Auth users cannot be created from plain SQL in the editor). theatre_demo
-- (TA-0001) already exists from the original setup — only create these two
-- new ones:
--
--   Email: theatre_demo_2@livescreen.local   Password: Theatre2@123
--   Email: theatre_demo_3@livescreen.local   Password: Theatre3@123
--   (toggle "Auto Confirm User" on for both, same as the existing four)
--
-- LiveScreen's login screen still takes a short id — SupabaseAuthService's
-- _demoEmails map needs these two new entries added (see the Dart change
-- alongside this migration): 'theatre_demo_2' -> that email, and
-- 'theatre_demo_3' -> that email.
--
-- STEP 2 — run this file in the SQL Editor.
-- ---------------------------------------------------------------------

-- Ensure the roles are correct (mirrors SUPABASE_SETUP.md section 4 — the
-- auto-created profiles row defaults role to 'user' unless signup metadata
-- said otherwise, which the dashboard's "Add user" form doesn't set).
update profiles set role = 'theatre_admin', display_name = 'Demo Theatre Admin 2'
  where email = 'theatre_demo_2@livescreen.local';

update profiles set role = 'theatre_admin', display_name = 'Demo Theatre Admin 3'
  where email = 'theatre_demo_3@livescreen.local';

-- ---------------------------------------------------------------------
-- theatre_admins — one identity per demo operator. theatre_demo (TA-0001)
-- may already have an identity row from 0004's backfill (if it already
-- owned Broadway); ON CONFLICT DO NOTHING keeps this idempotent either way.
-- ---------------------------------------------------------------------

insert into theatre_admins (profile_id, organization_name, business_address, city, country, phone, verification_status)
select p.id, 'Demo Admin 1 Cinemas', '1 Demo Street', 'Demo City', 'Demo Country', '+10000000001', 'verified'
from profiles p where p.email = 'theatre_demo@livescreen.local'
on conflict (profile_id) do nothing;

insert into theatre_admins (profile_id, organization_name, business_address, city, country, phone, verification_status)
select p.id, 'Demo Admin 2 Cinemas', '2 Demo Street', 'Demo City', 'Demo Country', '+10000000002', 'verified'
from profiles p where p.email = 'theatre_demo_2@livescreen.local'
on conflict (profile_id) do nothing;

insert into theatre_admins (profile_id, organization_name, business_address, city, country, phone, verification_status)
select p.id, 'Demo Admin 3 Cinemas', '3 Demo Street', 'Demo City', 'Demo Country', '+10000000003', 'verified'
from profiles p where p.email = 'theatre_demo_3@livescreen.local'
on conflict (profile_id) do nothing;

-- ---------------------------------------------------------------------
-- Theatres — reuse by name if they already exist (e.g. 'Broadway' from the
-- original single-admin setup); otherwise create a minimal draft record so
-- the demo has something to select. A theatre created here starts in the
-- same state CreateTheatreScreen would leave it in (draft, empty config,
-- owner_id set to the demo admin who "created" it) — an admin can open it
-- and configure Room/Screen/Seating/Speakers/Acoustics normally afterward.
-- ---------------------------------------------------------------------

do $$
declare
  admin1 uuid;
  admin2 uuid;
  admin3 uuid;
  broadway uuid;
  misri uuid;
  tavi uuid;
  miva uuid;
begin
  select id into admin1 from theatre_admins a join profiles p on p.id = a.profile_id
    where p.email = 'theatre_demo@livescreen.local';
  select id into admin2 from theatre_admins a join profiles p on p.id = a.profile_id
    where p.email = 'theatre_demo_2@livescreen.local';
  select id into admin3 from theatre_admins a join profiles p on p.id = a.profile_id
    where p.email = 'theatre_demo_3@livescreen.local';

  -- Broadway — Admin 1. Reuse the existing row if present (do not touch its
  -- config/status/id); only create one if this is a genuinely fresh project.
  select id into broadway from theatres where name = 'Broadway' limit 1;
  if broadway is null then
    insert into theatres (owner_id, name, status, config)
    select p.id, 'Broadway', 'draft', '{}'::jsonb
    from profiles p where p.email = 'theatre_demo@livescreen.local'
    returning id into broadway;
  end if;

  -- misri — also Admin 1 (this is the "one admin, multiple theatres" case).
  select id into misri from theatres where name = 'misri' limit 1;
  if misri is null then
    insert into theatres (owner_id, name, status, config)
    select p.id, 'misri', 'draft', '{}'::jsonb
    from profiles p where p.email = 'theatre_demo@livescreen.local'
    returning id into misri;
  end if;

  -- tavi — Admin 2 (a different admin managing a different theatre).
  select id into tavi from theatres where name = 'tavi' limit 1;
  if tavi is null then
    insert into theatres (owner_id, name, status, config)
    select p.id, 'tavi', 'draft', '{}'::jsonb
    from profiles p where p.email = 'theatre_demo_2@livescreen.local'
    returning id into tavi;
  end if;

  -- MiVa Screens — Admin 3.
  select id into miva from theatres where name = 'MiVa Screens' limit 1;
  if miva is null then
    insert into theatres (owner_id, name, status, config)
    select p.id, 'MiVa Screens', 'draft', '{}'::jsonb
    from profiles p where p.email = 'theatre_demo_3@livescreen.local'
    returning id into miva;
  end if;

  -- Verified relationships — this is the part the task specifically asks
  -- for: "mark ONLY these demo relationships as verified" without
  -- weakening RLS for anyone else. Every relationship inserted below goes
  -- through the same columns/constraints a real Platform Admin approval
  -- would set (verification_status, verified_at) — it just skips the
  -- waiting.
  insert into theatre_admin_theatres (admin_id, theatre_id, relationship_role, verification_status, verified_at)
    values (admin1, broadway, 'owner', 'verified', now())
    on conflict (admin_id, theatre_id) do update set verification_status = 'verified', verified_at = now();

  insert into theatre_admin_theatres (admin_id, theatre_id, relationship_role, verification_status, verified_at)
    values (admin1, misri, 'owner', 'verified', now())
    on conflict (admin_id, theatre_id) do update set verification_status = 'verified', verified_at = now();

  insert into theatre_admin_theatres (admin_id, theatre_id, relationship_role, verification_status, verified_at)
    values (admin2, tavi, 'owner', 'verified', now())
    on conflict (admin_id, theatre_id) do update set verification_status = 'verified', verified_at = now();

  insert into theatre_admin_theatres (admin_id, theatre_id, relationship_role, verification_status, verified_at)
    values (admin3, miva, 'owner', 'verified', now())
    on conflict (admin_id, theatre_id) do update set verification_status = 'verified', verified_at = now();
end $$;

-- Note: this does NOT publish any of these theatres (status stays whatever
-- it already was, or 'draft' for a newly-created one) and does NOT set
-- theatres.verification_status to 'verified' — that is still a separate,
-- real Platform Admin review of the venue itself (section 5 of the task),
-- distinct from the ownership relationship this seed grants. A newly
-- created demo theatre still needs Room/Screen/Seating configured and
-- published normally before it shows up on the public Explore Theatres page.
