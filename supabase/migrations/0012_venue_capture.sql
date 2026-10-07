-- LiveScreen — AI Venue Capture Foundation
--
-- Migration 0012:
-- Creates private, theatre-scoped tables for AI venue capture sessions, media evidence,
-- observations, targeted evidence requests, and asynchronous reconstruction jobs.
--
-- Security:
-- - All capture tables are strictly private and theatre-scoped.
-- - Capture evidence is NEVER stored in the public theatre configuration JSONB.
-- - RLS enforces that only authorized theatre admins (via public.is_authorized_theatre_admin)
--   or platform admins can access capture sessions and evidence.
-- - Dedicated private storage bucket for capture media with restricted RLS.

-- =========================================================================
-- 1. venue_capture_sessions
-- =========================================================================
create table if not exists public.venue_capture_sessions (
  id uuid primary key default gen_random_uuid(),
  theatre_id uuid not null references public.theatres(id) on delete cascade,
  state text not null default 'initial' check (
    state in (
      'initial',
      'analyzing',
      'reconstructing',
      'needs_photo',
      'needs_measurement',
      'ready_for_review',
      'reviewing',
      'confirmed',
      'failed',
      'cancelled'
    )
  ),
  reconstruction_draft jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  confirmed_at timestamptz
);

create index if not exists idx_venue_capture_sessions_theatre
  on public.venue_capture_sessions(theatre_id);
create index if not exists idx_venue_capture_sessions_state
  on public.venue_capture_sessions(state);

-- =========================================================================
-- 2. venue_capture_media (private evidence)
-- =========================================================================
create table if not exists public.venue_capture_media (
  id text primary key default gen_random_uuid()::text,
  session_id uuid not null references public.venue_capture_sessions(id) on delete cascade,
  theatre_id uuid not null references public.theatres(id) on delete cascade,
  media_type text not null check (media_type in ('photo', 'video', 'measurement')),
  storage_path text not null,
  filename text not null,
  mime_type text,
  byte_size bigint,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_venue_capture_media_session
  on public.venue_capture_media(session_id);
create index if not exists idx_venue_capture_media_theatre
  on public.venue_capture_media(theatre_id);

-- =========================================================================
-- 3. venue_capture_observations
-- =========================================================================
create table if not exists public.venue_capture_observations (
  id text primary key default gen_random_uuid()::text,
  session_id uuid not null references public.venue_capture_sessions(id) on delete cascade,
  theatre_id uuid not null references public.theatres(id) on delete cascade,
  feature_type text not null,
  description text,
  confidence double precision check (confidence is null or (confidence >= 0.0 and confidence <= 1.0)),
  evidence_ids jsonb not null default '[]'::jsonb,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_venue_capture_observations_session
  on public.venue_capture_observations(session_id);
create index if not exists idx_venue_capture_observations_theatre
  on public.venue_capture_observations(theatre_id);

-- =========================================================================
-- 4. venue_capture_requests (targeted evidence requests)
-- =========================================================================
create table if not exists public.venue_capture_requests (
  id text primary key default gen_random_uuid()::text,
  session_id uuid not null references public.venue_capture_sessions(id) on delete cascade,
  theatre_id uuid not null references public.theatres(id) on delete cascade,
  target text not null,
  reason text not null,
  required_evidence_type text not null check (required_evidence_type in ('photo', 'video', 'measurement')),
  instruction text not null,
  related_observation_ids jsonb not null default '[]'::jsonb,
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high', 'critical')),
  status text not null default 'pending' check (status in ('pending', 'fulfilled', 'dismissed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index if not exists idx_venue_capture_requests_session
  on public.venue_capture_requests(session_id);
create index if not exists idx_venue_capture_requests_theatre
  on public.venue_capture_requests(theatre_id);
create index if not exists idx_venue_capture_requests_status
  on public.venue_capture_requests(status);

-- =========================================================================
-- 5. venue_capture_jobs (async reconstruction jobs)
-- =========================================================================
create table if not exists public.venue_capture_jobs (
  id text primary key default gen_random_uuid()::text,
  session_id uuid not null references public.venue_capture_sessions(id) on delete cascade,
  theatre_id uuid not null references public.theatres(id) on delete cascade,
  job_type text not null,
  status text not null default 'pending' check (status in ('pending', 'running', 'completed', 'failed', 'cancelled')),
  progress double precision not null default 0.0 check (progress >= 0.0 and progress <= 1.0),
  error_message text,
  worker_id text,
  payload jsonb not null default '{}'::jsonb,
  result_summary jsonb,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_venue_capture_jobs_session
  on public.venue_capture_jobs(session_id);
create index if not exists idx_venue_capture_jobs_theatre
  on public.venue_capture_jobs(theatre_id);
create index if not exists idx_venue_capture_jobs_status
  on public.venue_capture_jobs(status);

-- =========================================================================
-- 6. Row Level Security (RLS)
-- =========================================================================
alter table public.venue_capture_sessions enable row level security;
alter table public.venue_capture_media enable row level security;
alter table public.venue_capture_observations enable row level security;
alter table public.venue_capture_requests enable row level security;
alter table public.venue_capture_jobs enable row level security;

-- Helper check for RLS policies
-- Evaluates true if current auth user is authorized admin of theatre_id OR platform admin
create or replace function public.is_authorized_capture_operator(p_theatre_id uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select public.is_authorized_theatre_admin(p_theatre_id)
      or public.current_user_role() = 'platform_admin';
$$;

-- Policies: venue_capture_sessions
drop policy if exists "capture_sessions_select" on public.venue_capture_sessions;
create policy "capture_sessions_select"
  on public.venue_capture_sessions for select
  using (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_sessions_insert" on public.venue_capture_sessions;
create policy "capture_sessions_insert"
  on public.venue_capture_sessions for insert
  with check (public.is_authorized_theatre_admin(theatre_id));

drop policy if exists "capture_sessions_update" on public.venue_capture_sessions;
create policy "capture_sessions_update"
  on public.venue_capture_sessions for update
  using (public.is_authorized_capture_operator(theatre_id))
  with check (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_sessions_delete" on public.venue_capture_sessions;
create policy "capture_sessions_delete"
  on public.venue_capture_sessions for delete
  using (public.is_authorized_theatre_admin(theatre_id));

-- Policies: venue_capture_media
drop policy if exists "capture_media_select" on public.venue_capture_media;
create policy "capture_media_select"
  on public.venue_capture_media for select
  using (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_media_insert" on public.venue_capture_media;
create policy "capture_media_insert"
  on public.venue_capture_media for insert
  with check (public.is_authorized_theatre_admin(theatre_id));

drop policy if exists "capture_media_update" on public.venue_capture_media;
create policy "capture_media_update"
  on public.venue_capture_media for update
  using (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_media_delete" on public.venue_capture_media;
create policy "capture_media_delete"
  on public.venue_capture_media for delete
  using (public.is_authorized_theatre_admin(theatre_id));

-- Policies: venue_capture_observations
drop policy if exists "capture_observations_select" on public.venue_capture_observations;
create policy "capture_observations_select"
  on public.venue_capture_observations for select
  using (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_observations_insert" on public.venue_capture_observations;
create policy "capture_observations_insert"
  on public.venue_capture_observations for insert
  with check (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_observations_update" on public.venue_capture_observations;
create policy "capture_observations_update"
  on public.venue_capture_observations for update
  using (public.is_authorized_capture_operator(theatre_id));

-- Policies: venue_capture_requests
drop policy if exists "capture_requests_select" on public.venue_capture_requests;
create policy "capture_requests_select"
  on public.venue_capture_requests for select
  using (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_requests_insert" on public.venue_capture_requests;
create policy "capture_requests_insert"
  on public.venue_capture_requests for insert
  with check (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_requests_update" on public.venue_capture_requests;
create policy "capture_requests_update"
  on public.venue_capture_requests for update
  using (public.is_authorized_capture_operator(theatre_id));

-- Policies: venue_capture_jobs
drop policy if exists "capture_jobs_select" on public.venue_capture_jobs;
create policy "capture_jobs_select"
  on public.venue_capture_jobs for select
  using (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_jobs_insert" on public.venue_capture_jobs;
create policy "capture_jobs_insert"
  on public.venue_capture_jobs for insert
  with check (public.is_authorized_capture_operator(theatre_id));

drop policy if exists "capture_jobs_update" on public.venue_capture_jobs;
create policy "capture_jobs_update"
  on public.venue_capture_jobs for update
  using (public.is_authorized_capture_operator(theatre_id));

-- =========================================================================
-- 7. DB-Level State Transition Protection & Worker Isolation (Fix 3)
-- =========================================================================

-- Helper determining if current caller is an authenticated external worker
-- (running with service_role) or a platform administrator.
create or replace function public.is_capture_worker_or_platform_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select coalesce(current_setting('role', true), '') = 'service_role'
      or coalesce(auth.role(), '') = 'service_role'
      or public.current_user_role() = 'platform_admin';
$$;

-- Trigger function guarding venue_capture_sessions transitions
create or replace function public.enforce_capture_session_transition()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  is_worker boolean := public.is_capture_worker_or_platform_admin();
begin
  -- 1. Terminal states (confirmed, cancelled) cannot be modified
  if old.state in ('confirmed', 'cancelled') and new.state is distinct from old.state then
    raise exception 'Cannot transition out of terminal capture state "%".', old.state;
  end if;

  -- 2. External workers and Platform Admins can perform all pipeline transitions
  if is_worker then
    return new;
  end if;

  -- 3. Authenticated Theatre Admin safeguards:
  -- Workers own deep reconstruction and intermediate pipeline states
  if new.state in ('reconstructing', 'ready_for_review', 'failed') and new.state is distinct from old.state then
    raise exception 'Only external AI reconstruction workers can set state to "%".', new.state;
  end if;

  -- Admin confirmation guard:
  -- Theatre admin can only confirm if session is actively in review, has a draft,
  -- and that draft was explicitly reviewed.
  if new.state = 'confirmed' and old.state is distinct from 'confirmed' then
    if old.state not in ('ready_for_review', 'reviewing') then
      raise exception 'A capture session can only be confirmed from ready_for_review or reviewing state (current: "%").', old.state;
    end if;
    if new.reconstruction_draft is null then
      raise exception 'Cannot confirm a capture session without a reconstruction draft.';
    end if;
    if coalesce((new.reconstruction_draft ->> 'isReviewed')::boolean, false) is not true then
      raise exception 'Cannot confirm an unreviewed reconstruction draft.';
    end if;
    if new.confirmed_at is null then
      raise exception 'Capture confirmation requires confirmed_at timestamp.';
    end if;
  end if;

  -- Admin initiating analysis when uploading evidence
  if new.state = 'analyzing' and old.state is distinct from 'analyzing' then
    if old.state not in ('initial', 'needs_photo', 'needs_measurement') then
      raise exception 'Theatre admin can only initiate analysis from initial, needs_photo, or needs_measurement.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists capture_sessions_enforce_transition on public.venue_capture_sessions;
create trigger capture_sessions_enforce_transition
  before update on public.venue_capture_sessions
  for each row execute function public.enforce_capture_session_transition();

-- Trigger function guarding venue_capture_jobs transitions
create or replace function public.enforce_capture_job_transition()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  is_worker boolean := public.is_capture_worker_or_platform_admin();
begin
  -- Normal authenticated theatre admin cannot arbitrarily set worker execution status
  if not is_worker then
    if new.status in ('running', 'completed', 'failed') and new.status is distinct from old.status then
      raise exception 'Only background AI workers can update capture job execution status to "%".', new.status;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists capture_jobs_enforce_transition on public.venue_capture_jobs;
create trigger capture_jobs_enforce_transition
  before update on public.venue_capture_jobs
  for each row execute function public.enforce_capture_job_transition();

-- =========================================================================
-- 8. Private Storage Bucket & Storage RLS Policies (Fix 2)
-- =========================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'venue_capture_private',
  'venue_capture_private',
  false,
  104857600, -- 100 MB max per evidence item
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'video/mp4',
    'video/quicktime',
    'application/json'
  ]
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Helper extracting theatre UUID from standard storage paths:
-- Supports "theatres/<theatre_id>/evidence/<filename>" and "<theatre_id>/<filename>"
create or replace function public.extract_theatre_id_from_storage_path(p_path text)
returns uuid
language plpgsql
immutable
as $$
declare
  parts text[] := string_to_array(p_path, '/');
  candidate text;
begin
  if parts[1] = 'theatres' and array_length(parts, 1) >= 2 then
    candidate := parts[2];
  else
    candidate := parts[1];
  end if;
  return candidate::uuid;
exception when others then
  return null;
end;
$$;

-- Storage Policy: SELECT
-- Only authorized theatre admin for that theatre, platform admin, or worker
drop policy if exists "capture_storage_select" on storage.objects;
create policy "capture_storage_select"
  on storage.objects for select
  using (
    bucket_id = 'venue_capture_private'
    and (
      public.is_capture_worker_or_platform_admin()
      or (
        auth.role() = 'authenticated'
        and public.is_authorized_theatre_admin(
          public.extract_theatre_id_from_storage_path(name)
        )
      )
    )
  );

-- Storage Policy: INSERT
-- Theatre admin can upload only into their authorized theatre path
drop policy if exists "capture_storage_insert" on storage.objects;
create policy "capture_storage_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'venue_capture_private'
    and (
      public.is_capture_worker_or_platform_admin()
      or (
        auth.role() = 'authenticated'
        and public.is_authorized_theatre_admin(
          public.extract_theatre_id_from_storage_path(name)
        )
      )
    )
  );

-- Storage Policy: UPDATE
drop policy if exists "capture_storage_update" on storage.objects;
create policy "capture_storage_update"
  on storage.objects for update
  using (
    bucket_id = 'venue_capture_private'
    and (
      public.is_capture_worker_or_platform_admin()
      or (
        auth.role() = 'authenticated'
        and public.is_authorized_theatre_admin(
          public.extract_theatre_id_from_storage_path(name)
        )
      )
    )
  );

-- Storage Policy: DELETE
drop policy if exists "capture_storage_delete" on storage.objects;
create policy "capture_storage_delete"
  on storage.objects for delete
  using (
    bucket_id = 'venue_capture_private'
    and (
      public.is_capture_worker_or_platform_admin()
      or (
        auth.role() = 'authenticated'
        and public.is_authorized_theatre_admin(
          public.extract_theatre_id_from_storage_path(name)
        )
      )
    )
  );

-- =========================================================================
-- 9. Automated Verification Checks (Self-Testing SQL Block)
--
-- Validates:
-- 1. Path parsing function extracts theatre_id correctly for both formats.
-- 2. is_authorized_capture_operator and is_capture_worker_or_platform_admin exist.
-- 3. Bucket venue_capture_private exists with public = false.
-- 4. Triggers capture_sessions_enforce_transition and capture_jobs_enforce_transition exist.
-- =========================================================================
do $$
declare
  test_uuid uuid := '12345678-1234-1234-1234-123456789abc'::uuid;
  parsed_uuid_1 uuid;
  parsed_uuid_2 uuid;
  parsed_uuid_invalid uuid;
  bucket_is_public boolean;
begin
  -- Check 1: Path parsing
  parsed_uuid_1 := public.extract_theatre_id_from_storage_path('theatres/12345678-1234-1234-1234-123456789abc/evidence/photo1.jpg');
  parsed_uuid_2 := public.extract_theatre_id_from_storage_path('12345678-1234-1234-1234-123456789abc/photo1.jpg');
  parsed_uuid_invalid := public.extract_theatre_id_from_storage_path('invalid/path/without/uuid');

  if parsed_uuid_1 is distinct from test_uuid then
    raise exception 'Self-test failure: extract_theatre_id_from_storage_path failed for standard path';
  end if;
  if parsed_uuid_2 is distinct from test_uuid then
    raise exception 'Self-test failure: extract_theatre_id_from_storage_path failed for short path';
  end if;
  if parsed_uuid_invalid is not null then
    raise exception 'Self-test failure: extract_theatre_id_from_storage_path should return null for invalid path';
  end if;

  -- Check 2: Bucket is strictly private
  select public into bucket_is_public from storage.buckets where id = 'venue_capture_private';
  if bucket_is_public is distinct from false then
    raise exception 'Self-test failure: venue_capture_private bucket must be private (public = false)';
  end if;
end;
$$;
