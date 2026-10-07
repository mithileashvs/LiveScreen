-- =========================================================================
-- 0008_movie_trailer_dual_assets.sql
-- LiveScreen — Separate YouTube Trailer URL & Immersive 3D Trailer Asset
--
-- Separates movie trailer into two distinct assets:
--   1. trailer_url: YouTube URL for standard web playback.
--   2. immersive_trailer_url: Supabase Storage public URL or direct MP4/WebM
--      for playback on the physical cinema screen inside the Unity 3D venue.
--
-- Preserves backwards compatibility with existing trailer_path data.
-- =========================================================================

-- 1. Add columns to movies table
alter table movies add column if not exists trailer_url text;
alter table movies add column if not exists immersive_trailer_url text;

-- 2. Migrate existing trailer_path values to trailer_url
update movies
set trailer_url = trailer_path
where trailer_url is null and trailer_path is not null;

-- 3. Create or ensure 'trailers' storage bucket is public
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'trailers',
  'trailers',
  true,
  524288000, -- 500 MB max file size
  array['video/mp4', 'video/webm']
)
on conflict (id) do update set
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- 4. Set storage policies for 'trailers' bucket

-- Public read access: Required for Unity VideoPlayer (WebGL) and browser playback
drop policy if exists "trailers_public_select" on storage.objects;
create policy "trailers_public_select"
  on storage.objects for select
  using (bucket_id = 'trailers');

-- Authenticated producer write access: Only authenticated users with producer or
-- platform_admin role can upload into the 'trailers' bucket.
drop policy if exists "trailers_auth_insert" on storage.objects;
drop policy if exists "trailers_producer_insert" on storage.objects;
create policy "trailers_producer_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'trailers'
    and auth.role() = 'authenticated'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('producer', 'platform_admin')
    )
  );

drop policy if exists "trailers_auth_update" on storage.objects;
drop policy if exists "trailers_producer_update" on storage.objects;
create policy "trailers_producer_update"
  on storage.objects for update
  using (
    bucket_id = 'trailers'
    and auth.role() = 'authenticated'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('producer', 'platform_admin')
    )
  );

drop policy if exists "trailers_producer_delete" on storage.objects;
create policy "trailers_producer_delete"
  on storage.objects for delete
  using (
    bucket_id = 'trailers'
    and auth.role() = 'authenticated'
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('producer', 'platform_admin')
    )
  );
