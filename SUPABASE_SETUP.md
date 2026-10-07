# LiveScreen — Supabase Setup

LiveScreen now uses Supabase (Postgres + Auth) as its shared backend,
connecting the User, Theatre Admin, and Producer roles to the same data.
This file is everything needed to stand that up from scratch.

I could not perform any of these steps myself — this sandbox has no network
access to supabase.com and no Flutter/Dart SDK. Everything below needs to be
run by you, once, against your own Supabase project.

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) and create a new project
   (any name/region/database password).
2. Wait for provisioning to finish.
3. Project Settings -> API: copy the **Project URL** and the **anon /
   public** key. You will NOT need the `service_role` key anywhere in this
   app — never put it in the Flutter project.

## 2. Configure environment variables

In the project root (`livescreen/`, next to `pubspec.yaml`):

```powershell
copy .env.example .env
```

Edit `.env`:

```
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_PUBLIC_KEY
```

`.env` should already be excluded by `.gitignore` — double-check before
committing anything. Only `.env.example` (placeholders only) should ever be
committed.

## 3. Run the database migration

Open your Supabase project's **SQL Editor** and run, in order:

```
supabase/migrations/0001_init.sql
supabase/migrations/0002_platform_admin_verification.sql
supabase/migrations/0003_show_booking_workflow.sql
supabase/migrations/0004_shows_price_schema_repair.sql
supabase/migrations/0005_shows_status_schema_repair.sql
supabase/migrations/0006_theatre_admin_identity.sql
supabase/migrations/0007_dev_theatre_admin_demo_seed.sql
supabase/migrations/0008_movie_trailer_dual_assets.sql
supabase/migrations/0009_theatre_delete_protection.sql
```

(0004/0005 above are prior fixes to the shows table; 0008 adds dual-trailer assets; 0009 adds database-level delete protection triggers preventing permanent deletion of theatres that have active shows or bookings, alongside RLS delete authorization.)

`0006_theatre_admin_identity.sql` adds the Theatre Admin identity/multi-theatre
ownership model: `theatre_admins` (operator/business identity, one per
account, with a server-generated `TA-0001`-style admin code) and
`theatre_admin_theatres` (the many-to-many "who may manage which theatre"
relationship, with its own pending/verified workflow, reviewed by Platform
Admin — separate from a theatre's own venue verification). It also
backfills a verified relationship for every theatre that already exists,
so nothing currently working stops working. See that file's header comment
for full detail.

If you want the three demo Theatre Admin accounts described in the task
(one admin managing two theatres, a second and third admin each managing
one), also run `supabase/migrations/0007_dev_theatre_admin_demo_seed.sql` —
it is dev/demo-only (matches theatres by name) and its own header explains
the one manual step it needs first (creating two more Supabase Auth users,
same as step 4 below). Run it after 0006, never before.

(If you use the Supabase CLI locally instead: `supabase db push` after
linking the project, applies both files in order.)

## 4. Create the four demo accounts

Supabase Auth requires an email address, so the demo IDs map to:

| Demo ID | Email used for Supabase Auth | Password | Role |
|---|---|---|---|
| `user_demo` | `user_demo@livescreen.local` | `User@123` | `user` |
| `theatre_demo` | `theatre_demo@livescreen.local` | `Theatre@123` | `theatre_admin` |
| `producer_demo` | `producer_demo@livescreen.local` | `Producer@123` | `producer` |
| `platform_admin_demo` | `platform_admin_demo@livescreen.local` | `Platform@123` | `platform_admin` |

Two more Theatre Admin accounts, only needed if you're also running
`0007_dev_theatre_admin_demo_seed.sql` (see above):

| Demo ID | Email used for Supabase Auth | Password | Role |
|---|---|---|---|
| `theatre_demo_2` | `theatre_demo_2@livescreen.local` | `Theatre2@123` | `theatre_admin` |
| `theatre_demo_3` | `theatre_demo_3@livescreen.local` | `Theatre3@123` | `theatre_admin` |

You still type `user_demo` / `theatre_demo` / `producer_demo` /
`platform_admin_demo` into the LiveScreen login screen — the app maps that
to the email above internally (see
`lib/auth/services/supabase_auth_service.dart`).

**Create the auth users** — Supabase Dashboard -> Authentication -> Users ->
"Add user" -> "Create new user":
- Email: `user_demo@livescreen.local`, Password: `User@123`, toggle **Auto
  Confirm User** on (so it doesn't need email verification).
- Repeat for `theatre_demo@livescreen.local` / `Theatre@123`,
  `producer_demo@livescreen.local` / `Producer@123`, and
  `platform_admin_demo@livescreen.local` / `Platform@123`.

**Assign roles** — the migration's trigger auto-creates a `profiles` row on
signup, but defaults `role` to `'user'` unless metadata says otherwise (and
the dashboard's "Add user" form doesn't expose custom metadata). So after
creating the four users above, run this in the SQL Editor once to set the
correct roles:

```sql
update public.profiles set role = 'user', display_name = 'Demo User'
  where email = 'user_demo@livescreen.local';

update public.profiles set role = 'theatre_admin', display_name = 'Demo Theatre Admin'
  where email = 'theatre_demo@livescreen.local';

update public.profiles set role = 'producer', display_name = 'Demo Producer',
    verification_status = 'verified'
  where email = 'producer_demo@livescreen.local';

update public.profiles set role = 'platform_admin', display_name = 'Demo Platform Admin'
  where email = 'platform_admin_demo@livescreen.local';
```

(`producer_demo` is set straight to `verified` here purely so the existing
demo walkthrough isn't blocked on a manual approval step — a real new
producer signup still starts at `pending`, per the verification workflow in
section 6.)

If a `profiles` row didn't get created automatically for some reason
(e.g. the trigger wasn't in place before you created the users), insert it
directly instead:

```sql
insert into public.profiles (id, email, display_name, role)
select id, email, 'Demo User', 'user' from auth.users where email = 'user_demo@livescreen.local'
on conflict (id) do update set role = excluded.role;
-- repeat for theatre_demo@livescreen.local -> 'theatre_admin',
-- producer_demo@livescreen.local -> 'producer',
-- and platform_admin_demo@livescreen.local -> 'platform_admin'
```

## 5. Required tables (created by the migration)

- `profiles` — one row per auth user; `role` is `user` | `theatre_admin` |
  `producer` | `platform_admin`. `verification_status` (producer accounts
  only) is `pending` | `under_review` | `verified` | `rejected` | `suspended`.
- `theatres` — one row per theatre; `owner_id` -> `profiles`, `status` is
  `draft` | `published` | `archived`, full Room/Screen/Seating/Speakers/
  Acoustics/Movie configuration stored as a `config` jsonb column (reusing
  `TheatreConfiguration.toJson()`/`fromJson()` as-is). `verification_status`
  is the separate `pending` | `under_review` | `verified` | `rejected` |
  `suspended` Platform Admin decision for this theatre — a theatre can only
  become `published` once it is `verified`.
- `movies` — one row per producer-owned movie; `producer_id` -> `profiles`,
  `status` is `draft` | `published` | `archived`. `approval_status` is the
  separate `draft` | `submitted` | `under_review` | `approved` | `rejected`
  Platform Admin decision — a movie can only become `published` once it is
  `approved`.
- `shows` — theatre + optional movie + start/end time.
- `bookings` — user + theatre + optional show + seat, with two partial
  unique indexes preventing a seat from being double-booked.
- `verification_audit_log` — one row per verification/approval/publish
  status change, whoever made it (Platform Admin only for select).

## 6. Required RLS policies

All in the migration files already. Summary:
- **User**: read published-and-verified theatres, published-and-approved
  movies, and shows; read/create/update only their own bookings. Cannot
  verify, approve, or publish anything.
- **Theatre Admin**: read/create/update only theatres they own (`owner_id =
  auth.uid()`); read/create/update shows only for theatres they own. Cannot
  change their own theatre's `verification_status` (rejected by the
  `enforce_theatre_transition` trigger, not just hidden by the UI), and
  cannot publish a theatre that isn't `verified`.
- **Producer**: read/create/update only movies they own (`producer_id =
  auth.uid()`). Can move a movie between `draft`/`submitted`
  (`approval_status`) themselves; cannot set `under_review`/`approved`/
  `rejected`, and cannot publish — both rejected by the
  `enforce_movie_transition` trigger.
- **Platform Admin**: can read and update every theatre, producer profile,
  and movie regardless of owner (`*_select_platform_admin` /
  `*_update_platform_admin` policies), and is the only role the
  `enforce_*_transition` triggers allow to set `verification_status` /
  `approval_status` / review metadata, or a producer's `role`.
- Nobody can read another user's `profiles` row, another admin's draft
  theatre, or another producer's draft movie — except Platform Admin.

## 7. Run the app

```powershell
flutter pub get
flutter run -d chrome
```

Log in with any of the four demo accounts (also shown directly on the
login screen).

## Known limitation

`flutter_dotenv` reads `.env` as a Flutter **asset** (declared in
`pubspec.yaml`), which works for `flutter run`/`flutter build web` as
normal, but means the real Supabase URL/anon key do get bundled into the
compiled web output (same as any client-side Supabase app — the anon key is
designed to be public; RLS is what actually protects the data, not hiding
this key).
