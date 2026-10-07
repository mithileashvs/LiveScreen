-- LiveScreen — Safe Theatre Lifecycle & Dependency-Protected Deletion
--
-- Migration 0009:
-- 1. Adds a database-level BEFORE DELETE trigger on `theatres` to prevent
--    permanent deletion of any theatre that has dependent shows or bookings.
--    This ensures that even if a client bypasses UI checks or calls the
--    Supabase REST API directly, historical records cannot be cascade-deleted.
-- 2. Adds the missing RLS DELETE policy on `theatres` so authorized theatre
--    admins can permanently delete their own zero-dependency theatres.

-- =========================================================================
-- 1. Database trigger function: prevent deletion if shows or bookings exist
-- =========================================================================

create or replace function public.prevent_theatre_delete_with_dependencies()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_show_count integer := 0;
  v_booking_count integer := 0;
begin
  -- Check for existing shows associated with this theatre
  select count(*) into v_show_count
  from public.shows
  where theatre_id = old.id;

  -- Check for existing bookings associated with this theatre
  select count(*) into v_booking_count
  from public.bookings
  where theatre_id = old.id;

  if v_show_count > 0 or v_booking_count > 0 then
    raise exception 'Cannot delete theatre "%" (%): active dependencies exist (% show(s), % booking(s)). Please deactivate the theatre instead.',
      old.name, old.id, v_show_count, v_booking_count
      using errcode = '23503'; -- foreign_key_violation error code
  end if;

  return old;
end;
$$;

drop trigger if exists trg_prevent_theatre_delete_with_dependencies on public.theatres;
create trigger trg_prevent_theatre_delete_with_dependencies
  before delete on public.theatres
  for each row
  execute function public.prevent_theatre_delete_with_dependencies();

-- =========================================================================
-- 2. RLS policy for DELETE on theatres
-- Only authorized theatre admins (or owners) can delete a theatre.
-- The trigger above guarantees deletion only succeeds if dependencies = 0.
-- =========================================================================

drop policy if exists "theatres_delete_own" on public.theatres;
create policy "theatres_delete_own"
  on public.theatres for delete
  using (public.is_authorized_theatre_admin(id));
