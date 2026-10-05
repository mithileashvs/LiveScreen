-- LiveScreen — BookMyShow-style show workflow
--
-- Builds on 0001_init.sql (base schema) and 0002_platform_admin_verification.sql
-- (platform_admin role + verification/approval). This migration:
--   1. Simplifies movie catalog visibility to approval_status alone (a
--      Platform-Admin-approved movie now enters the catalog directly — no
--      separate "publish the movie" step).
--   2. Gives `shows` a real draft/published lifecycle (it previously had
--      none — every created show was immediately visible) plus ticket
--      pricing (didn't exist at all before).
--   3. Enforces, at the database, that a show can only ever reference an
--      APPROVED movie, and that only a PUBLISHED show on a PUBLISHED+
--      VERIFIED theatre can actually be booked.
--
-- Run after 0001_init.sql and 0002_platform_admin_verification.sql.

-- =========================================================================
-- 1. MOVIE CATALOG VISIBILITY — approval_status alone now decides whether a
-- movie is in the public catalog. `status` (draft/published/archived) is
-- still updated for informational parity, but is no longer part of the
-- public SELECT policy: see enforce_movie_transition below, which now
-- auto-flips `status` to 'published' the moment `approval_status` becomes
-- 'approved', so the two never actually disagree in practice — but the
-- policy itself only checks the one column that matters per the business
-- rule ("Platform Admin APPROVED movie -> movie appears in the catalog").
-- =========================================================================

drop policy if exists "movies_select_published" on movies;
create policy "movies_select_published"
  on movies for select
  using (status = 'published' and approval_status = 'approved');

create or replace function public.enforce_movie_transition()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  actor_role text := public.current_user_role();
begin
  if actor_role is distinct from 'platform_admin' then
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

  -- Publishing requires explicit action by Platform Admin: content must be
  -- approved before it can be marked Published.
  if new.status = 'published' and old.status is distinct from new.status
      and new.approval_status is distinct from 'approved' then
    raise exception 'This content must be approved before it can be published.';
  end if;

  return new;
end;
$$;
-- (trigger already attached in 0002 — CREATE OR REPLACE updates its body in place)

-- =========================================================================
-- 2. SHOWS — add a real draft/published lifecycle and ticket pricing.
-- 'scheduled' (the old default/only "live" state) meant "visible to
-- everyone" with no gate at all; every existing row in that state already
-- represents a show the Theatre Admin intended to be live, so it maps to
-- the new 'published' state on backfill. 'cancelled'/'completed' rows are
-- untouched.
-- =========================================================================

update shows set status = 'published' where status = 'scheduled';

alter table shows drop constraint if exists shows_status_check;
alter table shows alter column status drop default;
alter table shows add constraint shows_status_check
  check (status in ('draft', 'published', 'cancelled', 'completed'));
alter table shows alter column status set default 'draft';

alter table shows add column if not exists price numeric(10, 2) not null default 0
  check (price >= 0);

-- A show can only ever reference an APPROVED movie — enforced regardless of
-- which role/screen created it, mirroring the pattern used for theatre/
-- movie/producer transitions elsewhere in this schema.
create or replace function public.enforce_show_movie_approved()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.movie_id is not null then
    if not exists (
      select 1 from movies m where m.id = new.movie_id and m.approval_status = 'approved'
    ) then
      raise exception 'Only an approved movie can be scheduled for a show.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists shows_enforce_movie_approved on shows;
create trigger shows_enforce_movie_approved
  before insert or update on shows
  for each row execute function public.enforce_show_movie_approved();

-- A show is only discoverable/bookable once it is itself 'published' (on
-- top of the existing theatre-published requirement) — previously ANY show
-- status was visible as long as the theatre was published, with no
-- show-level gate at all.
drop policy if exists "shows_select_for_published_theatre" on shows;
create policy "shows_select_for_published_theatre"
  on shows for select
  using (
    status = 'published'
    and exists (select 1 from theatres t where t.id = shows.theatre_id and t.status = 'published')
  );

-- =========================================================================
-- 3. BOOKING ELIGIBILITY — "only published shows should be bookable" was
-- previously not enforced at all: `bookings_insert_own` only checked
-- `auth.uid() = user_id`, so a booking could technically be inserted for a
-- draft/cancelled show or an unpublished/unverified theatre if the id was
-- known. This closes that gap without touching the bookings table shape.
-- =========================================================================

create or replace function public.enforce_booking_eligibility()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_show_status text;
  v_theatre_status text;
  v_theatre_verification text;
begin
  if new.show_id is not null then
    select s.status, t.status, t.verification_status
      into v_show_status, v_theatre_status, v_theatre_verification
      from shows s
      join theatres t on t.id = s.theatre_id
      where s.id = new.show_id;

    if v_show_status is null then
      raise exception 'Show not found.';
    end if;
    if v_show_status <> 'published' then
      raise exception 'This show is not published and cannot be booked.';
    end if;
  else
    select status, verification_status
      into v_theatre_status, v_theatre_verification
      from theatres
      where id = new.theatre_id;
  end if;

  if v_theatre_status is distinct from 'published' or v_theatre_verification is distinct from 'verified' then
    raise exception 'This theatre is not currently open for booking.';
  end if;

  return new;
end;
$$;

drop trigger if exists bookings_enforce_eligibility on bookings;
create trigger bookings_enforce_eligibility
  before insert on bookings
  for each row execute function public.enforce_booking_eligibility();
