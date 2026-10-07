-- LiveScreen — repair: PGRST204 "Could not find the 'price' column of
-- 'shows' in the schema cache"
--
-- Root cause (found by inspection, not guessed): 0003_show_booking_workflow.sql
-- already adds shows.price (numeric(10,2) not null default 0, check price >= 0),
-- and the Flutter app (ShowModel, ShowRepository.createShow, and the Theatre
-- Admin scheduling screen) already reads/writes it correctly end to end — none
-- of that needed changing. The error means the LIVE Supabase project either
-- never actually had 0003 applied, or had it applied through a path that adds
-- the column without telling PostgREST to reload its schema cache (e.g. the
-- SQL was run by hand in the Dashboard's SQL Editor rather than through a
-- migration flow — `supabase db push` — that notifies PostgREST afterward).
--
-- This migration is deliberately idempotent and safe to run even if 0003
-- already fully succeeded: it only touches `shows` if the column/constraint
-- is still missing, and it always asks PostgREST to reload its cache so a
-- genuinely-already-applied-but-uncached column starts working immediately
-- instead of waiting on PostgREST's own next cache refresh.

alter table public.shows
  add column if not exists price numeric(10, 2) not null default 0;

-- Re-assert the "price must not be negative" rule too, in case an earlier
-- partial/manual application added the column without its check constraint.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'shows_price_check'
      and conrelid = 'public.shows'::regclass
  ) then
    alter table public.shows add constraint shows_price_check check (price >= 0);
  end if;
end $$;

-- Force PostgREST to pick up the schema change immediately, rather than
-- relying on its own polling / next-restart cache refresh. This is the
-- actual fix for a PGRST204 caused by a stale cache rather than a genuinely
-- missing column — harmless no-op if the cache was already correct.
notify pgrst, 'reload schema';
