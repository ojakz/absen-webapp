-- Presensi v2 — Supabase schema
-- Spek grill 2026-10-30: fase absen dulu (izin/HRIS nanti), tanpa GPS,
-- flextime 08:00-09:00 start, 8 jam kerja, Senin-Jumat,
-- selfie wajib masuk + pulang, role extensible (bukan boolean),
-- allowlist admin dulu, karyawan daftar sendiri via Google,
-- notif lupa pulang besoknya via app, pengajuan koreksi admin approve,
-- retensi data selamanya dulu (bisa diubah nanti).
-- Cara pakai: paste seluruh file ini di Supabase Dashboard > SQL Editor > New query > Run.
-- JANGAN paste service_role key atau database password ke file / chat manapun.

-- ============ Tabel ============

create table if not exists public.allowlist (
  email text primary key,
  full_name text not null,
  position text, -- jabatan (tampilan), mis. "Operator IPA"; hak akses tetap di kolom role
  role text not null default 'employee',
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  full_name text not null,
  position text, -- jabatan (tampilan), mis. "Operator IPA"; hak akses tetap di kolom role
  role text not null default 'employee',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.app_config (
  id int primary key default 1,
  office_name text not null default 'Mertoyudan, Magelang',
  work_start time not null default '08:00',
  start_window_end time not null default '09:00',
  required_hours numeric not null default 8,
  working_days int[] not null default array[1,2,3,4,5],
  constraint app_config_single_row check (id = 1)
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.profiles (id) on delete cascade,
  work_date date not null,
  clock_in timestamptz,
  clock_out timestamptz,
  clock_in_photo_path text,
  clock_out_photo_path text,
  clock_in_status text,
  total_hours numeric,
  day_status text not null default 'belum_pulang',
  corrected_via_request boolean not null default false,
  created_at timestamptz not null default now(),
  unique (employee_id, work_date)
);

create table if not exists public.correction_requests (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.profiles (id) on delete cascade,
  attendance_id uuid not null references public.attendance (id) on delete cascade,
  work_date date not null,
  actual_clock_out timestamptz not null,
  reason text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by uuid references public.profiles (id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.profiles (id) on delete cascade,
  attendance_id uuid references public.attendance (id) on delete set null,
  type text not null default 'forgot_clock_out',
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- Seed config (bukan data dummy karyawan / riwayat).
insert into public.app_config (id) values (1)
on conflict (id) do nothing;

-- ============ RLS ============
alter table public.allowlist enable row level security;
alter table public.profiles enable row level security;
alter table public.app_config enable row level security;
alter table public.attendance enable row level security;
alter table public.correction_requests enable row level security;
alter table public.notifications enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- allowlist: user login bisa cek emailnya sendiri; admin bisa kelola semua.
create policy "allowlist_self_read" on public.allowlist
  for select using (email = (auth.jwt() ->> 'email'));
create policy "allowlist_admin_all" on public.allowlist
  for all using (public.is_admin()) with check (public.is_admin());

-- profiles: user bisa baca/tulis profilnya sendiri; admin baca semua.
create policy "profiles_self" on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles_admin_read" on public.profiles
  for select using (public.is_admin());

-- app_config: semua user login bisa baca; admin bisa ubah.
create policy "config_read" on public.app_config
  for select using (auth.uid() is not null);
create policy "config_admin_write" on public.app_config
  for all using (public.is_admin()) with check (public.is_admin());

-- attendance: karyawan hanya miliknya; admin semua.
create policy "attendance_self" on public.attendance
  for all using (employee_id = auth.uid()) with check (employee_id = auth.uid());
create policy "attendance_admin" on public.attendance
  for all using (public.is_admin()) with check (public.is_admin());

-- correction_requests: karyawan hanya miliknya; admin semua.
create policy "correction_self" on public.correction_requests
  for all using (employee_id = auth.uid()) with check (employee_id = auth.uid());
create policy "correction_admin" on public.correction_requests
  for all using (public.is_admin()) with check (public.is_admin());

-- notifications: karyawan hanya miliknya; admin baca semua.
create policy "notifications_self" on public.notifications
  for all using (employee_id = auth.uid()) with check (employee_id = auth.uid());
create policy "notifications_admin_read" on public.notifications
  for select using (public.is_admin());

-- ============ Storage: bucket selfie (private) ============
-- Buat bucket di Dashboard > Storage > New bucket: nama "selfie", Private.
-- Path yang dipakai app: <employee_auth_id>/masuk-YYYY-MM-DD.jpg dan <employee_auth_id>/pulang-YYYY-MM-DD.jpg
-- Kebijakan storage (jalankan setelah bucket dibuat):
-- insert into storage.buckets (id, name, public) values ('selfie', 'selfie', false)
--   on conflict (id) do nothing;
-- Kebijakan RLS storage (diterapkan langsung 2026-10-31 via Supabase MCP,
-- setelah error upload selfie "new row violates row-level security policy":
-- versi lama file ini ternyata masih dikomentari, jadi tidak pernah jalan).
create policy "selfie_upload_own" on storage.objects for insert
  with check (bucket_id = 'selfie' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "selfie_update_own" on storage.objects for update
  using (bucket_id = 'selfie' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'selfie' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "selfie_read_own" on storage.objects for select
  using (bucket_id = 'selfie' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "selfie_admin_read" on storage.objects for select
  using (bucket_id = 'selfie' and public.is_admin());

-- ============ Catatan implementasi app ============
-- Flextime (dihitung di app, bukan di DB):
--   masuk <= 09:00 = tepat waktu, > 09:00 = terlambat
--   total jam = clock_out - clock_in; < 8 jam = jam kurang
--   hari Senin-Jumat saja; Sabtu-Minggu bukan hari absen, tidak dihitung alpa
-- Lupa pulang: app / job harian membuat notifications type forgot_clock_out
--   keesokan harinya untuk attendance yang day_status masih belum_pulang.
-- Pengajuan koreksi: tidak memblokir absen hari berikutnya; kalau admin
--   approve, update attendance.clock_out = actual_clock_out,
--   day_status = lengkap, corrected_via_request = true, dan isi
--   correction_requests.reviewed_by / reviewed_at (audit log).
-- Seed karyawan: JANGAN hardcode email di file ini. Setelah Jack kasih
--   email Google-nya, jalankan:
--   insert into public.allowlist (email, full_name, role)
--   values ('EMAIL_JACK', 'M. Zaki Izzuddin', 'admin');
-- Lalu Jack login pertama via Google, app membuat profiles dari allowlist.
-- Email+password tetap tersedia sebagai metode login alternatif (Q3),
-- tapi admin tidak pernah membuat / memegang password karyawan (Q15).
