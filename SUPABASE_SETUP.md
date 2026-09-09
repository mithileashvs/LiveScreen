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

Open your Supabase project's **SQL Editor** and run the entire contents of:

```
supabase/migrations/0001_init.sql
```

This creates: `profiles`, `theatres`, `movies`, `shows`, `bookings`, all
indexes, all Row Level Security policies, and two triggers (auto-create a
`profiles` row on signup, auto-update `updated_at`).

(If you use the Supabase CLI locally instead: `supabase db push` after
linking the project, from the same file.)

## 4. Create the three demo accounts

Supabase Auth requires an email address, so the demo IDs map to:

| Demo ID | Email used for Supabase Auth | Password | Role |
|---|---|---|---|
| `user_demo` | `user_demo@livescreen.local` | `User@123` | `user` |
| `theatre_demo` | `theatre_demo@livescreen.local` | `Theatre@123` | `theatre_admin` |
| `producer_demo` | `producer_demo@livescreen.local` | `Producer@123` | `producer` |

You still type `user_demo` / `theatre_demo` / `producer_demo` into the
LiveScreen login screen — the app maps that to the email above internally
(see `lib/auth/services/supabase_auth_service.dart`).

**Create the auth users** — Supabase Dashboard -> Authentication -> Users ->
"Add user" -> "Create new user":
- Email: `user_demo@livescreen.local`, Password: `User@123`, toggle **Auto
  Confirm User** on (so it doesn't need email verification).
- Repeat for `theatre_demo@livescreen.local` / `Theatre@123` and
  `producer_demo@livescreen.local` / `Producer@123`.

**Assign roles** — the migration's trigger auto-creates a `profiles` row on
signup, but defaults `role` to `'user'` unless metadata says otherwise (and
the dashboard's "Add user" form doesn't expose custom metadata). So after
creating the three users above, run this in the SQL Editor once to set the
correct roles:

```sql
update public.profiles set role = 'user', display_name = 'Demo User'
  where email = 'user_demo@livescreen.local';

update public.profiles set role = 'theatre_admin', display_name = 'Demo Theatre Admin'
  where email = 'theatre_demo@livescreen.local';

update public.profiles set role = 'producer', display_name = 'Demo Producer'
  where email = 'producer_demo@livescreen.local';
```

If a `profiles` row didn't get created automatically for some reason
(e.g. the trigger wasn't in place before you created the users), insert it
directly instead:

```sql
insert into public.profiles (id, email, display_name, role)
select id, email, 'Demo User', 'user' from auth.users where email = 'user_demo@livescreen.local'
on conflict (id) do update set role = excluded.role;
-- repeat for theatre_demo@livescreen.local -> 'theatre_admin'
-- and producer_demo@livescreen.local -> 'producer'
```

## 5. Required tables (created by the migration)

- `profiles` — one row per auth user; `role` is `user` | `theatre_admin` | `producer`.
- `theatres` — one row per theatre; `owner_id` -> `profiles`, `status` is
  `draft` | `published` | `archived`, full Room/Screen/Seating/Speakers/
  Acoustics/Movie configuration stored as a `config` jsonb column (reusing
  `TheatreConfiguration.toJson()`/`fromJson()` as-is).
- `movies` — one row per producer-owned movie; `producer_id` -> `profiles`,
  `status` is `draft` | `published` | `archived`.
- `shows` — theatre + optional movie + start/end time.
- `bookings` — user + theatre + optional show + seat, with two partial
  unique indexes preventing a seat from being double-booked.

## 6. Required RLS policies

All in the migration file already. Summary:
- **User**: read published theatres/movies/shows; read/create/update only
  their own bookings.
- **Theatre Admin**: read/create/update only theatres they own (`owner_id =
  auth.uid()`); read/create/update shows only for theatres they own.
- **Producer**: read/create/update only movies they own (`producer_id =
  auth.uid()`).
- Nobody can read another user's `profiles` row, another admin's draft
  theatre, or another producer's draft movie.

## 7. Run the app

```powershell
flutter pub get
flutter run -d chrome
```

Log in with any of the three demo accounts (also shown directly on the
login screen).

## Known limitation

`flutter_dotenv` reads `.env` as a Flutter **asset** (declared in
`pubspec.yaml`), which works for `flutter run`/`flutter build web` as
normal, but means the real Supabase URL/anon key do get bundled into the
compiled web output (same as any client-side Supabase app — the anon key is
designed to be public; RLS is what actually protects the data, not hiding
this key).
