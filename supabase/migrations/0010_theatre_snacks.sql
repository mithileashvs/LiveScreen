-- =========================================================================
-- 0010_theatre_snacks.sql
-- LiveScreen — Theatre-Specific Concession & Snack Catalog Architecture
--
-- Enables Theatre Admins to configure and manage snacks uniquely per theatre.
-- Snacks are strictly scoped by theatre_id, isolating catalogs across venues.
--
-- Tables:
--   - theatre_snacks: Snack items belonging to a theatre.
--
-- Storage:
--   - snack-images bucket: Public read, theatre_admin upload.
-- =========================================================================

-- 1. Create theatre_snacks table
create table if not exists public.theatre_snacks (
  id uuid primary key default gen_random_uuid(),
  theatre_id uuid not null references public.theatres(id) on delete restrict,
  name text not null,
  description text not null default '',
  category text not null default 'Snacks',
  price numeric(10, 2) not null check (price >= 0),
  image_url text,
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Indexes for efficient lookup
create index if not exists theatre_snacks_theatre_id_idx on public.theatre_snacks (theatre_id);
create index if not exists theatre_snacks_category_idx on public.theatre_snacks (theatre_id, category);
create index if not exists theatre_snacks_available_idx on public.theatre_snacks (theatre_id, is_available);

-- 3. Trigger for updated_at
drop trigger if exists theatre_snacks_set_updated_at on public.theatre_snacks;
create trigger theatre_snacks_set_updated_at
  before update on public.theatre_snacks
  for each row execute function public.set_updated_at();

-- 4. Enable Row Level Security
alter table public.theatre_snacks enable row level security;

-- 5. RLS Policies

-- Public / Customer: View available snacks for any theatre
-- Theatre Admin: View all snacks (available or unavailable) for authorized theatres
drop policy if exists "theatre_snacks_select" on public.theatre_snacks;
create policy "theatre_snacks_select"
  on public.theatre_snacks for select
  using (
    is_available = true
    or public.is_authorized_theatre_admin(theatre_id)
    or public.current_user_role() = 'platform_admin'
  );

-- Insert: Authorized theatre admin for that specific theatre
drop policy if exists "theatre_snacks_insert" on public.theatre_snacks;
create policy "theatre_snacks_insert"
  on public.theatre_snacks for insert
  with check (
    public.is_authorized_theatre_admin(theatre_id)
    or public.current_user_role() = 'platform_admin'
  );

-- Update: Authorized theatre admin for that specific theatre
drop policy if exists "theatre_snacks_update" on public.theatre_snacks;
create policy "theatre_snacks_update"
  on public.theatre_snacks for update
  using (
    public.is_authorized_theatre_admin(theatre_id)
    or public.current_user_role() = 'platform_admin'
  )
  with check (
    public.is_authorized_theatre_admin(theatre_id)
    or public.current_user_role() = 'platform_admin'
  );

-- Delete: Authorized theatre admin for that specific theatre
drop policy if exists "theatre_snacks_delete" on public.theatre_snacks;
create policy "theatre_snacks_delete"
  on public.theatre_snacks for delete
  using (
    public.is_authorized_theatre_admin(theatre_id)
    or public.current_user_role() = 'platform_admin'
  );

-- =========================================================================
-- 6. Storage Bucket for Snack Images
-- =========================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'snack-images',
  'snack-images',
  true,
  5242880, -- 5 MB max
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update set
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Public read access: Anyone can load snack images
drop policy if exists "snack_images_public_select" on storage.objects;
create policy "snack_images_public_select"
  on storage.objects for select
  using (bucket_id = 'snack-images');

-- Authenticated upload access: theatre_admin and platform_admin
drop policy if exists "snack_images_auth_insert" on storage.objects;
create policy "snack_images_auth_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'snack-images'
    and auth.role() = 'authenticated'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('theatre_admin', 'platform_admin')
    )
  );

drop policy if exists "snack_images_auth_update" on storage.objects;
create policy "snack_images_auth_update"
  on storage.objects for update
  using (
    bucket_id = 'snack-images'
    and auth.role() = 'authenticated'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('theatre_admin', 'platform_admin')
    )
  );

drop policy if exists "snack_images_auth_delete" on storage.objects;
create policy "snack_images_auth_delete"
  on storage.objects for delete
  using (
    bucket_id = 'snack-images'
    and auth.role() = 'authenticated'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('theatre_admin', 'platform_admin')
    )
  );
