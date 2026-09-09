-- LiveScreen — initial schema
-- Run this in Supabase Dashboard -> SQL Editor (or via the Supabase CLI:
-- `supabase db push`) against a fresh project. See SUPABASE_SETUP.md for
-- the full setup walkthrough including the three demo accounts.

create extension if not exists pgcrypto;

-- =========================================================================
-- profiles — one row per auth user, carries the app-level role.
-- The backend (not just the Flutter UI) is the source of truth for role,
-- per the task's explicit requirement.
-- =========================================================================
create table if not exists profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  display_name text,
  role text not null check (role in ('user', 'theatre_admin', 'producer')),
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

create policy "profiles_select_own"
  on profiles for select
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user signs up, reading the
-- intended role/display name from the signup call's user_metadata (see
-- SupabaseAuthService / SUPABASE_SETUP.md for how the three demo accounts
-- are created with this metadata already set).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'display_name', new.email),
    coalesce(new.raw_user_meta_data ->> 'role', 'user')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =========================================================================
-- theatres — one row per theatre a Theatre Admin manages. The full Room /
-- Screen / Seating / Speakers / Acoustics / Movie configuration already
-- has clean, nested Dart models with toJson/fromJson (TheatreConfiguration
-- in lib/admin/models) — rather than exploding that into half a dozen
-- normalized child tables, `config` stores that exact JSON. `status`,
-- `owner_id`, and the timestamps stay as real relational columns since
-- those are exactly what "getMyTheatres" / "getPublishedTheatres" /
-- ownership checks need to filter and index on.
-- =========================================================================
create table if not exists theatres (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles (id) on delete cascade,
  name text not null,
  hall_name text,
  description text,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  schema_version integer not null default 1,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists theatres_owner_id_idx on theatres (owner_id);
create index if not exists theatres_status_idx on theatres (status);

alter table theatres enable row level security;

create policy "theatres_select_published"
  on theatres for select
  using (status = 'published');

create policy "theatres_select_own"
  on theatres for select
  using (auth.uid() = owner_id);

create policy "theatres_insert_own"
  on theatres for insert
  with check (
    auth.uid() = owner_id
    and exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'theatre_admin')
  );

create policy "theatres_update_own"
  on theatres for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- =========================================================================
-- movies — producer-owned catalog. Trailer/thumbnail/duration live on the
-- same row rather than separate "trailers" tables, matching the existing
-- MovieContent model's shape 1:1 (it already conflates a movie and its
-- trailer into one record).
-- =========================================================================
create table if not exists movies (
  id uuid primary key default gen_random_uuid(),
  producer_id uuid not null references profiles (id) on delete cascade,
  title text not null,
  description text,
  trailer_path text,
  thumbnail text,
  duration_seconds integer not null default 0,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists movies_producer_id_idx on movies (producer_id);
create index if not exists movies_status_idx on movies (status);

alter table movies enable row level security;

create policy "movies_select_published"
  on movies for select
  using (status = 'published');

create policy "movies_select_own"
  on movies for select
  using (auth.uid() = producer_id);

create policy "movies_insert_own"
  on movies for insert
  with check (
    auth.uid() = producer_id
    and exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'producer')
  );

create policy "movies_update_own"
  on movies for update
  using (auth.uid() = producer_id)
  with check (auth.uid() = producer_id);

-- =========================================================================
-- shows — minimal theatre + movie + time slot. Deliberately thin per the
-- task's "do not overbuild scheduling yet" instruction.
-- =========================================================================
create table if not exists shows (
  id uuid primary key default gen_random_uuid(),
  theatre_id uuid not null references theatres (id) on delete cascade,
  movie_id uuid references movies (id) on delete set null,
  start_time timestamptz not null,
  end_time timestamptz,
  status text not null default 'scheduled' check (status in ('scheduled', 'cancelled', 'completed')),
  created_at timestamptz not null default now()
);

create index if not exists shows_theatre_id_idx on shows (theatre_id);

alter table shows enable row level security;

create policy "shows_select_for_published_theatre"
  on shows for select
  using (
    exists (select 1 from theatres t where t.id = shows.theatre_id and t.status = 'published')
  );

create policy "shows_select_own_theatre"
  on shows for select
  using (
    exists (select 1 from theatres t where t.id = shows.theatre_id and t.owner_id = auth.uid())
  );

create policy "shows_insert_own_theatre"
  on shows for insert
  with check (
    exists (select 1 from theatres t where t.id = shows.theatre_id and t.owner_id = auth.uid())
  );

create policy "shows_update_own_theatre"
  on shows for update
  using (
    exists (select 1 from theatres t where t.id = shows.theatre_id and t.owner_id = auth.uid())
  );

-- =========================================================================
-- bookings — minimal persistent booking record. theatre_id is always set;
-- show_id is nullable so a seat can be booked directly against a theatre's
-- configured seating even before the admin has scheduled an explicit show
-- (the critical cross-role test in this task doesn't require a show to
-- exist first). Two partial unique indexes prevent a double-booking of the
-- same seat, whichever path was used.
-- =========================================================================
create table if not exists bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  theatre_id uuid not null references theatres (id) on delete cascade,
  show_id uuid references shows (id) on delete cascade,
  seat_id text not null,
  status text not null default 'confirmed' check (status in ('confirmed', 'cancelled')),
  created_at timestamptz not null default now()
);

create unique index if not exists bookings_show_seat_unique
  on bookings (show_id, seat_id)
  where show_id is not null and status = 'confirmed';

create unique index if not exists bookings_theatre_seat_unique
  on bookings (theatre_id, seat_id)
  where show_id is null and status = 'confirmed';

create index if not exists bookings_user_id_idx on bookings (user_id);

alter table bookings enable row level security;

create policy "bookings_select_own"
  on bookings for select
  using (auth.uid() = user_id);

create policy "bookings_insert_own"
  on bookings for insert
  with check (auth.uid() = user_id);

create policy "bookings_update_own"
  on bookings for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =========================================================================
-- Keep updated_at current on theatres/movies without relying on the client.
-- =========================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists theatres_set_updated_at on theatres;
create trigger theatres_set_updated_at
  before update on theatres
  for each row execute function public.set_updated_at();

drop trigger if exists movies_set_updated_at on movies;
create trigger movies_set_updated_at
  before update on movies
  for each row execute function public.set_updated_at();
