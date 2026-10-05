-- LiveScreen — Platform Admin verification & approval workflow
--
-- Adds a fourth role (platform_admin) plus the three separate concepts the
-- task calls out explicitly:
--   1. Account/entity verification  (theatres, producers)
--   2. Content approval             (movies)
--   3. Publishing                   (theatres.status / movies.status — unchanged columns)
--
-- These are kept as distinct columns/states on purpose, per the task's
-- "do NOT combine verification / approval / publishing" instruction, rather
-- than overloading the existing draft/published/archived `status` column.
--
-- Run this AFTER 0001_init.sql, in the Supabase SQL Editor (or
-- `supabase db push`). It only adds columns/policies/functions — nothing in
-- 0001_init.sql is modified or removed.

-- =========================================================================
-- 1. ROLE: add platform_admin to the existing role check constraint.
-- =========================================================================
alter table profiles drop constraint if exists profiles_role_check;
alter table profiles add constraint profiles_role_check
  check (role in ('user', 'theatre_admin', 'producer', 'platform_admin'));

-- =========================================================================
-- 2. Verification columns.
--
-- Theatre verification lives on `theatres` (per-theatre, matching the task's
-- "Theatre Admin must not be able to verify THEIR OWN THEATRE" wording and
-- the Theatre Verification list showing one row per theatre).
--
-- Producer verification lives on `profiles` (per-account, matching the
-- task's "Producer registers -> pending -> ... -> verified" account-level
-- flow, separate from any one piece of content).
--
-- Movie/content approval lives on `movies`, as `approval_status`, kept
-- distinct from the existing `status` (draft/published/archived) column
-- which continues to represent publish state only.
-- =========================================================================

alter table theatres
  add column if not exists verification_status text not null default 'pending'
    check (verification_status in ('pending', 'under_review', 'verified', 'rejected', 'suspended')),
  add column if not exists review_reason text,
  add column if not exists reviewed_by uuid references profiles (id),
  add column if not exists reviewed_at timestamptz;

create index if not exists theatres_verification_status_idx on theatres (verification_status);

alter table profiles
  add column if not exists verification_status text
    check (verification_status is null
      or verification_status in ('pending', 'under_review', 'verified', 'rejected', 'suspended')),
  add column if not exists verification_reason text,
  add column if not exists reviewed_by uuid references profiles (id),
  add column if not exists reviewed_at timestamptz;

create index if not exists profiles_verification_status_idx on profiles (verification_status);

alter table movies
  add column if not exists approval_status text not null default 'draft'
    check (approval_status in ('draft', 'submitted', 'under_review', 'approved', 'rejected')),
  add column if not exists review_reason text,
  add column if not exists reviewed_by uuid references profiles (id),
  add column if not exists reviewed_at timestamptz;

create index if not exists movies_approval_status_idx on movies (approval_status);

-- Backfill: preserve existing data's effective state instead of retroactively
-- hiding anything already live. New rows use the defaults above ('pending' /
-- 'draft') and go through the real workflow.
update theatres set verification_status = 'verified' where status = 'published';
update movies set approval_status = 'approved' where status = 'published';
update profiles set verification_status = 'pending'
  where role = 'producer' and verification_status is null;

-- handle_new_user() (from 0001_init.sql) already reads role from signup
-- metadata; extend it so a newly-created producer starts life 'pending'
-- (theatre_admin/user/platform_admin stay NULL — not applicable to them).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  new_role text := coalesce(new.raw_user_meta_data ->> 'role', 'user');
begin
  insert into public.profiles (id, email, display_name, role, verification_status)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'display_name', new.email),
    new_role,
    case when new_role = 'producer' then 'pending' else null end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- =========================================================================
-- 3. Audit log — one row per status change, whoever made it.
-- =========================================================================
create table if not exists verification_audit_log (
  id uuid primary key default gen_random_uuid(),
  entity text not null check (entity in ('theatre', 'producer', 'movie')),
  entity_id uuid not null,
  action text not null,
  previous_status text,
  new_status text,
  reviewer uuid references profiles (id),
  reason text,
  created_at timestamptz not null default now()
);

create index if not exists verification_audit_log_entity_idx
  on verification_audit_log (entity, entity_id);

alter table verification_audit_log enable row level security;

-- =========================================================================
-- 4. Role helper — used by every policy/trigger below. security definer so
-- it can read `profiles` regardless of the caller's own row-level policies
-- (mirrors the pattern already used by handle_new_user()); STABLE so the
-- planner can reuse it within one statement.
-- =========================================================================
create or replace function public.current_user_role()
returns text
language sql
stable
security definer set search_path = public
as $$
  select role from profiles where id = auth.uid();
$$;

-- =========================================================================
-- 5. RLS — Platform Admin needs to see/act on every row of profiles,
-- theatres, and movies (not just their own), on top of the existing
-- owner-scoped policies from 0001_init.sql, which are left untouched.
-- =========================================================================

create policy "profiles_select_platform_admin"
  on profiles for select
  using (public.current_user_role() = 'platform_admin');

create policy "profiles_update_platform_admin"
  on profiles for update
  using (public.current_user_role() = 'platform_admin')
  with check (public.current_user_role() = 'platform_admin');

create policy "theatres_select_platform_admin"
  on theatres for select
  using (public.current_user_role() = 'platform_admin');

create policy "theatres_update_platform_admin"
  on theatres for update
  using (public.current_user_role() = 'platform_admin')
  with check (public.current_user_role() = 'platform_admin');

create policy "movies_select_platform_admin"
  on movies for select
  using (public.current_user_role() = 'platform_admin');

create policy "movies_update_platform_admin"
  on movies for update
  using (public.current_user_role() = 'platform_admin')
  with check (public.current_user_role() = 'platform_admin');

create policy "audit_select_platform_admin"
  on verification_audit_log for select
  using (public.current_user_role() = 'platform_admin');

-- Inserts into the audit log only ever happen from the trigger functions
-- below (security definer), never directly from client code, so no
-- client-facing insert policy is added — RLS defaults to deny.

-- =========================================================================
-- 6. USER VISIBILITY — a theatre/movie must be BOTH published AND verified/
-- approved to be visible to end users. Replaces the two "select_published"
-- policies from 0001_init.sql with the extra condition (everything else
-- about them — draft/archived stay hidden — is unchanged).
-- =========================================================================

drop policy if exists "theatres_select_published" on theatres;
create policy "theatres_select_published"
  on theatres for select
  using (status = 'published' and verification_status = 'verified');

drop policy if exists "movies_select_published" on movies;
create policy "movies_select_published"
  on movies for select
  using (status = 'published' and approval_status = 'approved');

-- =========================================================================
-- 7. ENFORCEMENT TRIGGERS — this is the part that must not be bypassable by
-- the Flutter UI. A Theatre Admin/Producer can still update their own
-- row (existing *_update_own policies), but these BEFORE UPDATE triggers
-- block the specific fields/transitions only Platform Admin may perform,
-- regardless of what the client sends.
-- =========================================================================

create or replace function public.enforce_theatre_transition()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  actor_role text := public.current_user_role();
begin
  if actor_role is distinct from 'platform_admin' then
    if new.verification_status is distinct from old.verification_status then
      raise exception 'Only Platform Admin can change a theatre''s verification status.';
    end if;
    if new.reviewed_by is distinct from old.reviewed_by
        or new.reviewed_at is distinct from old.reviewed_at
        or new.review_reason is distinct from old.review_reason then
      raise exception 'Only Platform Admin can set theatre review metadata.';
    end if;
  end if;

  -- Applies no matter who is making the change (belt-and-braces): a theatre
  -- can never become Published unless it is currently Verified. A Theatre
  -- Admin cannot satisfy this by only changing local Flutter state, since
  -- the write itself is rejected here at the database.
  if new.status = 'published' and old.status is distinct from new.status
      and new.verification_status is distinct from 'verified' then
    raise exception 'This theatre must be verified by Platform Admin before it can be published.';
  end if;

  return new;
end;
$$;

drop trigger if exists theatres_enforce_transition on theatres;
create trigger theatres_enforce_transition
  before update on theatres
  for each row execute function public.enforce_theatre_transition();

create or replace function public.enforce_movie_transition()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  actor_role text := public.current_user_role();
begin
  if actor_role is distinct from 'platform_admin' then
    -- A Producer may only move their own movie between draft <-> submitted
    -- (submit for review / withdraw). Moving to under_review, approved, or
    -- rejected is a Platform Admin-only action.
    if new.approval_status is distinct from old.approval_status
        and not (old.approval_status in ('draft', 'submitted')
                 and new.approval_status in ('draft', 'submitted')) then
      raise exception 'Only Platform Admin can approve, reject, or review content.';
    end if;
    if new.reviewed_by is distinct from old.reviewed_by
        or new.reviewed_at is distinct from old.reviewed_at
        or new.review_reason is distinct from old.review_reason then
      raise exception 'Only Platform Admin can set content review metadata.';
    end if;
    if new.status = 'published' and old.status is distinct from new.status then
      raise exception 'Only Platform Admin can publish content.';
    end if;
  end if;

  -- Belt-and-braces, applies even to Platform Admin: content can never be
  -- marked Published without first being Approved.
  if new.status = 'published' and old.status is distinct from new.status
      and new.approval_status is distinct from 'approved' then
    raise exception 'This content must be approved before it can be published.';
  end if;

  return new;
end;
$$;

drop trigger if exists movies_enforce_transition on movies;
create trigger movies_enforce_transition
  before update on movies
  for each row execute function public.enforce_movie_transition();

create or replace function public.enforce_profile_transition()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  actor_role text := public.current_user_role();
begin
  if actor_role is distinct from 'platform_admin' then
    -- Closes an existing hole: without this, `profiles_update_own` (from
    -- 0001_init.sql) let any signed-in user rewrite their own `role` column
    -- directly, self-promoting to theatre_admin/producer/platform_admin.
    if new.role is distinct from old.role then
      raise exception 'Only Platform Admin can change a user''s role.';
    end if;
    if new.verification_status is distinct from old.verification_status then
      raise exception 'Only Platform Admin can change a producer''s verification status.';
    end if;
    if new.reviewed_by is distinct from old.reviewed_by
        or new.reviewed_at is distinct from old.reviewed_at
        or new.verification_reason is distinct from old.verification_reason then
      raise exception 'Only Platform Admin can set producer review metadata.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_enforce_transition on profiles;
create trigger profiles_enforce_transition
  before update on profiles
  for each row execute function public.enforce_profile_transition();

-- =========================================================================
-- 8. AUDIT TRIGGERS — log every verification/approval/status change, after
-- it has passed the enforcement trigger above, whoever performed it.
-- =========================================================================

create or replace function public.log_theatre_status_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.verification_status is distinct from old.verification_status then
    insert into verification_audit_log (entity, entity_id, action, previous_status, new_status, reviewer, reason)
    values ('theatre', new.id, 'verification_status_change', old.verification_status, new.verification_status, auth.uid(), new.review_reason);
  end if;
  if new.status is distinct from old.status then
    insert into verification_audit_log (entity, entity_id, action, previous_status, new_status, reviewer, reason)
    values ('theatre', new.id, 'status_change', old.status, new.status, auth.uid(), null);
  end if;
  return new;
end;
$$;

drop trigger if exists theatres_log_status_change on theatres;
create trigger theatres_log_status_change
  after update on theatres
  for each row execute function public.log_theatre_status_change();

create or replace function public.log_movie_status_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.approval_status is distinct from old.approval_status then
    insert into verification_audit_log (entity, entity_id, action, previous_status, new_status, reviewer, reason)
    values ('movie', new.id, 'approval_status_change', old.approval_status, new.approval_status, auth.uid(), new.review_reason);
  end if;
  if new.status is distinct from old.status then
    insert into verification_audit_log (entity, entity_id, action, previous_status, new_status, reviewer, reason)
    values ('movie', new.id, 'status_change', old.status, new.status, auth.uid(), null);
  end if;
  return new;
end;
$$;

drop trigger if exists movies_log_status_change on movies;
create trigger movies_log_status_change
  after update on movies
  for each row execute function public.log_movie_status_change();

create or replace function public.log_producer_status_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.role = 'producer' and new.verification_status is distinct from old.verification_status then
    insert into verification_audit_log (entity, entity_id, action, previous_status, new_status, reviewer, reason)
    values ('producer', new.id, 'verification_status_change', old.verification_status, new.verification_status, auth.uid(), new.verification_reason);
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_log_status_change on profiles;
create trigger profiles_log_status_change
  after update on profiles
  for each row execute function public.log_producer_status_change();
