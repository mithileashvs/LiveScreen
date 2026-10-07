-- LiveScreen — DEV/DEMO SEED ONLY. Do not run against a real production
-- database with real customers' theatres — this seed matches theatres BY
-- NAME ('Broadway', 'misri', 'tavi', 'MiVa Screens') and will attach to
-- any existing theatre with one of those names.
--
-- Run this ONLY after 0006_theatre_admin_identity.sql, and only in a
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
--   Email: theatre_demo2@livescreen.local   Password: Theatre2@123
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
--
-- profiles_enforce_transition (0002_platform_admin_verification.sql) blocks
-- any change to profiles.role unless the acting session's own role is
-- 'platform_admin' — this is what stops a normal signed-in user from
-- self-promoting via profiles_update_own. In the SQL Editor / migration
-- runner there is no authenticated session (auth.uid() is null), so
-- current_user_role() is null, which is "distinct from 'platform_admin'",
-- so that guard fires on this seed's own UPDATE.
--
-- This UPDATE is not a normal application-level role transition, though —
-- it is a one-time, server-side establishment of a brand-new demo
-- account's initial role, done once, in a DEV-ONLY seed migration, by
-- whoever has the privileges to run migrations at all. So the trigger is
-- disabled for exactly the width of these two UPDATEs (the only place in
-- this file that touches profiles.role) and re-enabled immediately after,
-- in the same transaction. The trigger's definition is untouched, no role
-- gets a standing bypass, and every ordinary UPDATE against profiles from
-- any authenticated session — including a real user trying to rewrite
-- their own role — is fully enforced again the instant this block finishes.
--
-- The "and role is distinct from" guards also mean this is a genuine no-op
-- (no row touched, trigger never evaluated a real change) if the demo
-- profiles already have the correct role from a previous run.
alter table profiles disable trigger profiles_enforce_transition;

update profiles set role = 'theatre_admin', display_name = 'Demo Theatre Admin 2'
  where email = 'theatre_demo2@livescreen.local' and role is distinct from 'theatre_admin';

update profiles set role = 'theatre_admin', display_name = 'Demo Theatre Admin 3'
  where email = 'theatre_demo_3@livescreen.local' and role is distinct from 'theatre_admin';

alter table profiles enable trigger profiles_enforce_transition;

-- ---------------------------------------------------------------------
-- theatre_admins — one identity per demo operator. theatre_demo (TA-0001)
-- may already have an identity row from 0006's backfill (if it already
-- owned Broadway); ON CONFLICT DO NOTHING keeps this idempotent either way.
-- ---------------------------------------------------------------------

insert into theatre_admins (profile_id, organization_name, business_address, city, country, phone, verification_status)
select p.id, 'Demo Admin 1 Cinemas', '1 Demo Street', 'Demo City', 'Demo Country', '+10000000001', 'verified'
from profiles p where p.email = 'theatre_demo@livescreen.local'
on conflict (profile_id) do nothing;

insert into theatre_admins (profile_id, organization_name, business_address, city, country, phone, verification_status)
select p.id, 'Demo Admin 2 Cinemas', '2 Demo Street', 'Demo City', 'Demo Country', '+10000000002', 'verified'
from profiles p where p.email = 'theatre_demo2@livescreen.local'
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

-- Same reasoning as 0006_theatre_admin_identity.sql's backfill: this file
-- also inserts/updates theatre_admin_theatres rows directly as 'verified'
-- (skipping the pending -> Platform-Admin-approval wait, since this is a
-- dev seed standing in for that approval), which the pending-only
-- transition trigger installed in 0006 would otherwise reject the same way
-- it rejected 0006's own backfill. Disabled for exactly the width of the
-- do-block below (the only place in this file that writes to
-- theatre_admin_theatres) and re-enabled immediately after, so the trigger
-- is back to fully enforcing 'pending'-only inserts for every real
-- Theatre Admin submission from this point on.
alter table theatre_admin_theatres disable trigger theatre_admin_theatres_enforce_transition;

do $$
declare
  admin1 uuid;
  admin2 uuid;
  admin3 uuid;
  broadway uuid;
  misri uuid;
  tavi uuid;
  miva uuid;
  existing_owner uuid;
begin
  select a.id into admin1 from theatre_admins a join profiles p on p.id = a.profile_id
    where p.email = 'theatre_demo@livescreen.local';
  select a.id into admin2 from theatre_admins a join profiles p on p.id = a.profile_id
    where p.email = 'theatre_demo2@livescreen.local';
  select a.id into admin3 from theatre_admins a join profiles p on p.id = a.profile_id
    where p.email = 'theatre_demo_3@livescreen.local';

  if admin1 is null or admin2 is null or admin3 is null then
    raise exception
      'One or more demo admin identities are missing — run 0006 first, and complete STEP 1 above '
      '(create theatre_demo_2 / theatre_demo_3 in Supabase Auth) before running this file.';
  end if;

  -- Broadway — Admin 1. Reuse the existing row if present, but ONLY if it
  -- is actually owned by theatre_demo already — a same-named theatre
  -- belonging to someone else must NOT be silently granted to this demo
  -- admin as "verified" just because the name matches (this is exactly
  -- the auto-verification risk to guard against: name collisions are not
  -- proof of ownership). If it belongs to a different owner, this theatre
  -- is skipped entirely rather than guessed at.
  select id, owner_id into broadway, existing_owner from theatres where name = 'Broadway' limit 1;
  if broadway is not null then
    if existing_owner <> (select p.id from profiles p where p.email = 'theatre_demo@livescreen.local') then
      raise notice
        'A theatre named "Broadway" already exists but is NOT owned by theatre_demo — skipping it '
        'for this demo seed rather than granting theatre_demo access to it. Resolve manually if '
        'this is unexpected.';
      broadway := null;
    end if;
  else
    insert into theatres (owner_id, name, status, config)
    select p.id, 'Broadway', 'draft', '{}'::jsonb
    from profiles p where p.email = 'theatre_demo@livescreen.local'
    returning id into broadway;
  end if;

  -- misri — also Admin 1 (the "one admin, multiple theatres" case). Same
  -- ownership-match guard as Broadway above.
  select id, owner_id into misri, existing_owner from theatres where name = 'misri' limit 1;
  if misri is not null then
    if existing_owner <> (select p.id from profiles p where p.email = 'theatre_demo@livescreen.local') then
      raise notice
        'A theatre named "misri" already exists but is NOT owned by theatre_demo — skipping it.';
      misri := null;
    end if;
  else
    insert into theatres (owner_id, name, status, config)
    select p.id, 'misri', 'draft', '{}'::jsonb
    from profiles p where p.email = 'theatre_demo@livescreen.local'
    returning id into misri;
  end if;

  -- tavi — Admin 2 (a different admin managing a different theatre). Same guard.
  select id, owner_id into tavi, existing_owner from theatres where name = 'tavi' limit 1;
  if tavi is not null then
    if existing_owner <> (select p.id from profiles p where p.email = 'theatre_demo2@livescreen.local') then
      raise notice 'A theatre named "tavi" already exists but is NOT owned by theatre_demo_2 — skipping it.';
      tavi := null;
    end if;
  else
    insert into theatres (owner_id, name, status, config)
    select p.id, 'tavi', 'draft', '{}'::jsonb
    from profiles p where p.email = 'theatre_demo2@livescreen.local'
    returning id into tavi;
  end if;

  -- MiVa Screens — Admin 3. Same guard.
  select id, owner_id into miva, existing_owner from theatres where name = 'MiVa Screens' limit 1;
  if miva is not null then
    if existing_owner <> (select p.id from profiles p where p.email = 'theatre_demo_3@livescreen.local') then
      raise notice
        'A theatre named "MiVa Screens" already exists but is NOT owned by theatre_demo_3 — skipping it.';
      miva := null;
    end if;
  else
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
  -- waiting. Each is conditional on the theatre having survived the
  -- ownership-match guard above (not null) — a skipped theatre gets no
  -- relationship at all rather than a guessed-at one.
  if broadway is not null then
    insert into theatre_admin_theatres (admin_id, theatre_id, relationship_role, verification_status, verified_at)
      values (admin1, broadway, 'owner', 'verified', now())
      on conflict (admin_id, theatre_id) do update set verification_status = 'verified', verified_at = now();
  end if;

  if misri is not null then
    insert into theatre_admin_theatres (admin_id, theatre_id, relationship_role, verification_status, verified_at)
      values (admin1, misri, 'owner', 'verified', now())
      on conflict (admin_id, theatre_id) do update set verification_status = 'verified', verified_at = now();
  end if;

  if tavi is not null then
    insert into theatre_admin_theatres (admin_id, theatre_id, relationship_role, verification_status, verified_at)
      values (admin2, tavi, 'owner', 'verified', now())
      on conflict (admin_id, theatre_id) do update set verification_status = 'verified', verified_at = now();
  end if;

  if miva is not null then
    insert into theatre_admin_theatres (admin_id, theatre_id, relationship_role, verification_status, verified_at)
      values (admin3, miva, 'owner', 'verified', now())
      on conflict (admin_id, theatre_id) do update set verification_status = 'verified', verified_at = now();
  end if;
end $$;

alter table theatre_admin_theatres enable trigger theatre_admin_theatres_enforce_transition;

-- Note: this does NOT publish any of these theatres (status stays whatever
-- it already was, or 'draft' for a newly-created one) and does NOT set
-- theatres.verification_status to 'verified' — that is still a separate,
-- real Platform Admin review of the venue itself (section 5 of the task),
-- distinct from the ownership relationship this seed grants. A newly
-- created demo theatre still needs Room/Screen/Seating configured and
-- published normally before it shows up on the public Explore Theatres page.
