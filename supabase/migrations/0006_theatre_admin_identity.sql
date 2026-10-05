-- LiveScreen — Theatre Admin identity & multi-theatre ownership
--
-- Builds on 0001_init.sql / 0002_platform_admin_verification.sql /
-- 0003_show_booking_workflow.sql. Adds:
--   1. theatre_admins    — an operator/business identity, separate from a
--                           single theatre (a `profiles` row with role
--                           'theatre_admin' can log in and see the app, but
--                           had no business identity beyond that).
--   2. theatre_admin_theatres — the many-to-many "who may manage which
--                           theatre" relationship, with its OWN
--                           verification_status, kept distinct from
--                           theatres.verification_status (that one is
--                           "is this venue itself verified"; this one is
--                           "is this admin authorized to manage this
--                           specific theatre").
--   3. RLS: theatres/shows access is extended (not replaced) to also
--      accept a verified theatre_admin_theatres row, on top of the
--      existing owner_id = auth.uid() check — a malicious client changing
--      theatre_id client-side still can't get past this, since it's
--      enforced here, at the database, not in Flutter.
--
-- theatres.owner_id is NOT removed or renamed — every existing read/write
-- path (SupabaseTheatreRepository, Unity bridge, RLS elsewhere) keeps
-- working unchanged. It becomes "the admin who originally created this
-- theatre"; theatre_admin_theatres becomes the actual source of truth for
-- "who is authorized to manage it now", and this migration backfills a
-- verified relationship row for every existing owner_id so nothing that
-- currently works stops working.
--
-- Run this AFTER 0001/0002/0003, in the Supabase SQL Editor (or
-- `supabase db push`). Safe to run against a database that already has
-- real theatres/admins in it — nothing here deletes or recreates existing
-- rows.

-- =========================================================================
-- 1. theatre_admins — one row per operator/business identity. profile_id is
-- unique: exactly one admin identity per Supabase Auth user (a person with
-- multiple businesses registers multiple times with different accounts,
-- matching how the rest of this app already treats one profiles row as one
-- person). admin_code is system-generated (TA-0001, TA-0002, ...), never
-- client-chosen — see the sequence + trigger below.
-- =========================================================================

create sequence if not exists theatre_admin_code_seq start 1;

create table if not exists theatre_admins (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references profiles (id) on delete cascade,
  admin_code text not null unique,
  organization_name text not null,
  business_address text not null,
  city text not null,
  country text not null,
  phone text not null,
  -- Kept separate from theatre_admin_theatres.verification_status: this is
  -- account-level ("is this operator identity itself legitimate"), that
  -- one is per-relationship ("is this operator authorized for THIS
  -- theatre"). An admin can be account-verified and still have individual
  -- theatre relationships pending.
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'under_review', 'verified', 'rejected', 'suspended')),
  verification_reason text,
  reviewed_by uuid references profiles (id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists theatre_admins_profile_id_idx on theatre_admins (profile_id);
create index if not exists theatre_admins_verification_status_idx on theatre_admins (verification_status);

drop trigger if exists theatre_admins_set_updated_at on theatre_admins;
create trigger theatre_admins_set_updated_at
  before update on theatre_admins
  for each row execute function public.set_updated_at();

-- Generate 'TA-0001' style codes server-side on insert — never trust a
-- client-supplied admin_code, and never let two concurrent registrations
-- race onto the same code (nextval on a sequence is atomic).
create or replace function public.generate_theatre_admin_code()
returns trigger
language plpgsql
as $$
begin
  if new.admin_code is null or new.admin_code = '' then
    new.admin_code := 'TA-' || lpad(nextval('theatre_admin_code_seq')::text, 4, '0');
  end if;
  return new;
end;
$$;

drop trigger if exists theatre_admins_generate_code on theatre_admins;
create trigger theatre_admins_generate_code
  before insert on theatre_admins
  for each row execute function public.generate_theatre_admin_code();

alter table theatre_admins enable row level security;

create policy "theatre_admins_select_own"
  on theatre_admins for select
  using (auth.uid() = profile_id);

-- Registration: a signed-in theatre_admin creates exactly their own
-- identity row (profile_id must match the caller — this is what stops
-- someone registering an admin identity attached to a different account).
create policy "theatre_admins_insert_own"
  on theatre_admins for insert
  with check (
    auth.uid() = profile_id
    and exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'theatre_admin')
  );

-- An admin may update their own business info, but NOT their own
-- verification_status/reviewed_by/reviewed_at/verification_reason — those
-- are Platform-Admin-only, enforced below by trigger (belt-and-braces, same
-- pattern as theatres/movies/profiles in 0002).
create policy "theatre_admins_update_own"
  on theatre_admins for update
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

create policy "theatre_admins_select_platform_admin"
  on theatre_admins for select
  using (public.current_user_role() = 'platform_admin');

create policy "theatre_admins_update_platform_admin"
  on theatre_admins for update
  using (public.current_user_role() = 'platform_admin')
  with check (public.current_user_role() = 'platform_admin');

create or replace function public.enforce_theatre_admin_transition()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  actor_role text := public.current_user_role();
begin
  if actor_role is distinct from 'platform_admin' then
    if new.verification_status is distinct from old.verification_status then
      raise exception 'Only Platform Admin can change a Theatre Admin''s verification status.';
    end if;
    if new.reviewed_by is distinct from old.reviewed_by
        or new.reviewed_at is distinct from old.reviewed_at
        or new.verification_reason is distinct from old.verification_reason then
      raise exception 'Only Platform Admin can set Theatre Admin review metadata.';
    end if;
    if new.admin_code is distinct from old.admin_code then
      raise exception 'admin_code cannot be changed.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists theatre_admins_enforce_transition on theatre_admins;
create trigger theatre_admins_enforce_transition
  before update on theatre_admins
  for each row execute function public.enforce_theatre_admin_transition();

-- =========================================================================
-- 2. theatre_admin_theatres — the many-to-many authorization relationship.
-- This table, not theatres.owner_id, is the source of truth for "which
-- theatres may this admin manage" going forward (see section 3's RLS).
-- =========================================================================

create table if not exists theatre_admin_theatres (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references theatre_admins (id) on delete cascade,
  theatre_id uuid not null references theatres (id) on delete cascade,
  relationship_role text not null default 'owner' check (relationship_role in ('owner', 'manager')),
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'under_review', 'verified', 'rejected')),
  submitted_at timestamptz not null default now(),
  verified_at timestamptz,
  verified_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (admin_id, theatre_id)
);

create index if not exists theatre_admin_theatres_admin_id_idx on theatre_admin_theatres (admin_id);
create index if not exists theatre_admin_theatres_theatre_id_idx on theatre_admin_theatres (theatre_id);
create index if not exists theatre_admin_theatres_verification_status_idx
  on theatre_admin_theatres (verification_status);

drop trigger if exists theatre_admin_theatres_set_updated_at on theatre_admin_theatres;
create trigger theatre_admin_theatres_set_updated_at
  before update on theatre_admin_theatres
  for each row execute function public.set_updated_at();

alter table theatre_admin_theatres enable row level security;

-- An admin sees only their own relationships — including pending/rejected
-- ones, so "My Theatres" can show a theatre as "Pending verification"
-- rather than it just silently not appearing.
create policy "theatre_admin_theatres_select_own"
  on theatre_admin_theatres for select
  using (
    exists (select 1 from theatre_admins a where a.id = theatre_admin_theatres.admin_id and a.profile_id = auth.uid())
  );

-- "Add Theatre" submission: an admin may create a PENDING relationship for
-- themselves. Cannot insert as 'verified' directly — enforced below.
create policy "theatre_admin_theatres_insert_own"
  on theatre_admin_theatres for insert
  with check (
    exists (select 1 from theatre_admins a where a.id = theatre_admin_theatres.admin_id and a.profile_id = auth.uid())
  );

create policy "theatre_admin_theatres_select_platform_admin"
  on theatre_admin_theatres for select
  using (public.current_user_role() = 'platform_admin');

create policy "theatre_admin_theatres_update_platform_admin"
  on theatre_admin_theatres for update
  using (public.current_user_role() = 'platform_admin')
  with check (public.current_user_role() = 'platform_admin');

create or replace function public.enforce_theatre_admin_theatre_transition()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  actor_role text := public.current_user_role();
begin
  if actor_role is distinct from 'platform_admin' then
    -- A brand new submission must start life pending, whoever inserts it.
    if tg_op = 'INSERT' and new.verification_status is distinct from 'pending' then
      raise exception 'A new theatre ownership submission must start as pending.';
    end if;
    if tg_op = 'UPDATE' and new.verification_status is distinct from old.verification_status then
      raise exception 'Only Platform Admin can approve or reject a theatre ownership submission.';
    end if;
    if tg_op = 'UPDATE' and (
        new.verified_by is distinct from old.verified_by
        or new.verified_at is distinct from old.verified_at
      ) then
      raise exception 'Only Platform Admin can set ownership review metadata.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists theatre_admin_theatres_enforce_transition on theatre_admin_theatres;
create trigger theatre_admin_theatres_enforce_transition
  before insert or update on theatre_admin_theatres
  for each row execute function public.enforce_theatre_admin_theatre_transition();

-- =========================================================================
-- 3. AUTHORIZATION HELPER — the single function every RLS policy below
-- calls. A theatre is manageable by the current user if EITHER:
--   a) legacy owner_id = auth.uid() (unchanged — nothing that already
--      works stops working), OR
--   b) there is a VERIFIED theatre_admin_theatres row linking this user's
--      admin identity to this theatre.
-- security definer + stable, same as current_user_role() in 0002, so RLS
-- policies can call it without needing their own access to the joined
-- tables, and the planner can reuse one evaluation per statement.
-- =========================================================================

create or replace function public.is_authorized_theatre_admin(p_theatre_id uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from theatres t where t.id = p_theatre_id and t.owner_id = auth.uid()
  ) or exists (
    select 1
    from theatre_admin_theatres tat
    join theatre_admins a on a.id = tat.admin_id
    where tat.theatre_id = p_theatre_id
      and a.profile_id = auth.uid()
      and tat.verification_status = 'verified'
  );
$$;

-- =========================================================================
-- 4. Extend theatres/shows RLS to use the helper. Existing *_select_own,
-- *_insert_own, *_update_own policies from 0001_init.sql are DROPPED and
-- RECREATED with the wider check — this is additive in effect (everything
-- owner_id already allowed still passes), never narrower.
-- =========================================================================

drop policy if exists "theatres_select_own" on theatres;
create policy "theatres_select_own"
  on theatres for select
  using (public.is_authorized_theatre_admin(id));

drop policy if exists "theatres_update_own" on theatres;
create policy "theatres_update_own"
  on theatres for update
  using (public.is_authorized_theatre_admin(id))
  with check (public.is_authorized_theatre_admin(id));

-- theatres_insert_own (creating a brand new theatre) is left untouched —
-- there is no theatre_id to check authorization against yet, and creation
-- still requires owner_id = auth.uid() + role = 'theatre_admin', exactly
-- as before. The Add Theatre flow separately submits a
-- theatre_admin_theatres row for Platform Admin to verify (section 5).

drop policy if exists "shows_select_own_theatre" on shows;
create policy "shows_select_own_theatre"
  on shows for select
  using (public.is_authorized_theatre_admin(theatre_id));

drop policy if exists "shows_insert_own_theatre" on shows;
create policy "shows_insert_own_theatre"
  on shows for insert
  with check (public.is_authorized_theatre_admin(theatre_id));

drop policy if exists "shows_update_own_theatre" on shows;
create policy "shows_update_own_theatre"
  on shows for update
  using (public.is_authorized_theatre_admin(theatre_id));

-- =========================================================================
-- 5. BACKFILL — every theatre that already exists keeps working exactly as
-- before (owner_id alone already grants access per the helper above), but
-- we also give each existing owner a first-class theatre_admins identity
-- and an already-verified theatre_admin_theatres row, so "My Theatres" /
-- the theatre switcher (which read theatre_admin_theatres, not owner_id,
-- for their LIST — see TheatreAdminRepository) show these theatres too,
-- not just newly-added ones. Nothing here changes owner_id, deletes a
-- theatre, or regenerates an id.
-- =========================================================================

insert into theatre_admins (profile_id, organization_name, business_address, city, country, phone)
select distinct
  t.owner_id,
  coalesce(p.display_name, p.email, 'Theatre Admin'),
  'Not provided — migrated from existing account',
  'Not provided',
  'Not provided',
  'Not provided'
from theatres t
join profiles p on p.id = t.owner_id
where not exists (select 1 from theatre_admins a where a.profile_id = t.owner_id);

-- The trigger installed in section 2 above (enforce_theatre_admin_theatre_transition)
-- is exactly what we want going forward: it requires every NEW ownership
-- relationship to start 'pending' unless the actor is a Platform Admin, and
-- inside this migration script there IS no authenticated actor (auth.uid()
-- is null in the SQL Editor / migration runner), so current_user_role() is
-- null and the trigger's "actor_role is distinct from 'platform_admin'"
-- branch always fires — which is exactly why the direct 'verified' backfill
-- insert below used to fail with "A new theatre ownership submission must
-- start as pending."
--
-- These rows are not a new submission, though — they are a one-time,
-- backend-verified grandfathering of relationships that already existed
-- for years as theatres.owner_id, done once, in this migration, by
-- whoever has the privileges to run migrations at all. So the trigger is
-- disabled for the width of this one backfill statement only, and
-- re-enabled immediately after, in the same transaction. Nothing about the
-- trigger's definition changes, no role gets a standing bypass, and any
-- ordinary INSERT/UPDATE against theatre_admin_theatres — including
-- 0007's demo seed and every real "Add Theatre" submission from here on —
-- is fully enforced again the instant this statement finishes.
alter table theatre_admin_theatres disable trigger theatre_admin_theatres_enforce_transition;

insert into theatre_admin_theatres (admin_id, theatre_id, relationship_role, verification_status, verified_at)
select a.id, t.id, 'owner', 'verified', now()
from theatres t
join theatre_admins a on a.profile_id = t.owner_id
where not exists (
  select 1 from theatre_admin_theatres tat where tat.admin_id = a.id and tat.theatre_id = t.id
);

alter table theatre_admin_theatres enable trigger theatre_admin_theatres_enforce_transition;
