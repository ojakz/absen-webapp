# Presensi — Aplikasi Absensi PDAM Tirta Ogan (Preview)

Aplikasi absensi karyawan berbasis web: login Google / email, selfie saat absen
masuk dan pulang, rekap admin, pengajuan koreksi, dan notifikasi lupa absen pulang.

**Status:** preview / prototipe. Live di https://tes-presensi-pdam.pages.dev
(dulu: https://presensi-8g1.pages.dev — masih aktif sebagai cadangan).

## Teknologi

- Satu file HTML/CSS/JS polos (`index.html`), tanpa framework, tanpa build step.
- Backend: Supabase (Postgres + Auth + Storage). Browser bicara langsung ke Supabase.
- Hosting: Cloudflare Pages (static).
- Kamera: `getUserMedia` + kompresi canvas. Foto selfie disimpan sementara di
  bucket Storage `selfie` (privat).

## Isi repo

| File | Keterangan |
|---|---|
| `index.html` | Seluruh aplikasi (UI + logika). Ini file yang di-deploy. |
| `favicon.png` | Ikon aplikasi (jam biru + centang). |
| `manifest.webmanifest` | Manifest PWA (belum diaktifkan). |
| `sw.js` | Service worker PWA (belum diaktifkan). |
| `supabase-schema.sql` | Skema database: `allowlist`, `profiles`, `app_config`, `attendance`, `correction_requests`, `notifications`, bucket `selfie`, dan RLS. |
| `docs/roles-draft.md` | Draft kasar role & hak akses PDAM (v0.1) — jabatan vs role vs unit. |

## Spek singkat

- Flextime 08:00–16:00, mulai 08:00–09:00, wajib 8 jam. Setelah 09:00
  terlambat; pulang lebih awal = jam kurang.
- **Mode preview saat ini:** `TEMP_FULL_FLEX = true` di `index.html` — absen
  hari apa saja, jam apa saja, tanpa status terlambat / jam kurang.
  Kembalikan ke aturan normal dengan mengubah flag itu jadi `false`
  (jangan deploy backup lama — backup itu dibuat sebelum favicon ada).
- Selfie wajib saat absen masuk DAN pulang.
- Lupa absen pulang: notifikasi di aplikasi keesokan harinya + pengajuan
  koreksi (tanggal, jam pulang sebenarnya, alasan). Admin menyetujui /
  menolak; yang disetujui ditandai `corrected_via_request`.
- **Tanpa GPS** — bukti absen hanya login + selfie. (GPS + geofence
  direncanakan nanti khusus untuk PDAM, lihat `docs/roles-draft.md`.)
- Role saat ini di aplikasi: `admin` dan `employee` (kolom `role`).
  Jabatan tampil terpisah di kolom `position` (mis. "Operator IPA") —
  jabatan hanya tampilan, hak akses tetap ikut `role`.
  Role PDAM yang direncanakan (5 role): lihat `docs/roles-draft.md`.

## Jalankan lokal

Tidak perlu install apa-apa. Dari folder repo:

```bash
python3 -m http.server 8000
```

Lalu buka http://localhost:8000 — tampilannya jalan, tapi **login Google
tidak akan bekerja dari localhost** sebelum `http://localhost:8000/**`
ditambahkan ke Redirect URLs di dashboard Supabase. Untuk sekadar cek
tampilan, cukup buka file-nya langsung di browser. Login selalu dites
di domain Pages yang sudah ter-deploy.

## Setup Supabase (sekali saja, sudah selesai untuk project ini)

1. Jalankan `supabase-schema.sql` di SQL Editor.
2. Isi `allowlist` dengan email + nama + jabatan + role karyawan.
3. Dashboard → Authentication → URL Configuration:
   - Site URL: `https://tes-presensi-pdam.pages.dev`
   - Redirect URLs: tambahkan `https://tes-presensi-pdam.pages.dev/**`
4. Google provider aktif; login mengandalkan Site URL di atas.

Project Supabase: `presensi-coba` (ap-northeast-1).
Free tier bisa pause sendiri kalau ~2 minggu tidak dipakai — restore dari
dashboard, data tetap utuh.

## Deploy

**Opsi A — lewat Carla (saat ini):** push ke GitHub, kabari Carla
(kirim link repo / file / zip), Carla yang deploy ke Cloudflare Pages.

**Opsi B — otomatis dari GitHub:** di dashboard Cloudflare → Pages →
project `tes-presensi-pdam` → Settings → Builds & deployments → sambungkan
repo GitHub ini. Setiap push ke branch utama langsung ter-deploy.
Build command dikosongkan saja (tidak ada build step); output directory `/`.

## Aturan keamanan — baca sebelum commit

- **Repo ini PRIVATE.** `index.html` berisi Supabase publishable key
  (memang dirancang untuk dipakai di client, tapi tetap jangan diumbar).
- **JANGAN PERNAH commit** `service_role` key, password database, token,
  atau file `.env`. Tidak ada yang seperti itu di repo ini — jaga supaya
  tetap begitu.
- Sebelum kerja besar: `git commit` dulu sebagai checkpoint.
- Jangan tempel isi `.env` / token / password ke prompt AI mana pun,
  termasuk Codex.

## Alur kerja dengan Codex (VS Code)

1. Buka folder ini di VS Code, buka terminal, jalankan `codex`.
2. Minta Codex mengerjakan satu tugas kecil (satu fitur / satu perbaikan).
3. Review diff-nya di VS Code sebelum menerima.
4. `git commit` + `git push` kalau sudah oke, lalu kabari Carla untuk deploy.

## Git — pertama kali

```bash
git init
git add .
git commit -m "Presensi preview: biru muda + kolom jabatan"
git branch -M main
git remote add origin https://github.com/<username>/<repo>.git
git push -u origin main
```

Ganti `<username>` dan `<repo>` dengan akun dan nama repo kamu.
Nama repo yang disarankan: `presensi-pdam`.
