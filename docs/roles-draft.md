# DRAFT KASAR — Role & Hak Akses Aplikasi Absensi PDAM Tirta Ogan

**Versi:** v0.1 — 23 November 2026
**Status:** draft untuk dikoreksi Jack, BUKAN keputusan final.
**Sumber:** Perda Kab. Ogan Ilir No. 28/2006 (struktur organisasi), Perda No. 1/2023 (perubahan jadi Perumda), data HRIS pendahulu (`hr_core.sql`: tabel `positions`, `units`, `work_locations`, `RolePermissionSeeder.php`), berita lokal, dan skripsi tentang PDAM Tirta Ogan (±101 pegawai).

> ⚠️ Catatan jujur: struktur di dump HRIS kelihatan parsial (cuma 5 jabatan, 4 unit) — kemungkinan data contoh / belum lengkap. Perda 2006 juga sudah lama dan sejak 2023 statusnya berubah jadi Perumda. Jadi daftar jabatan di bawah ini masih perlu dikonfirmasi ke struktur yang sekarang berlaku di PDAM.

---

## Prinsip dasar

1. **Jabatan ≠ Role.** Jabatan itu data master kepegawaian (Direktur, Kabag Teknik, Operator IPA, …). Role itu hak akses di aplikasi. Satu pegawai punya 1 jabatan + 1 role + 1 unit.
2. **Role sedikit, scope yang membedakan.** Jangan bikin 15 role — cukup 5 role, dan yang membedakan Kepala Bagian vs Kasubag adalah *unit yang dia pimpin*, bukan role baru.
3. **Atasan hanya melihat unitnya sendiri.** Kabag Teknik tidak bisa intip rekap Bagian Keuangan.
4. **Super Admin bukan atasan harian.** Dia pegang sistem, bukan approve absen orang tiap hari.

---

## 1. Daftar jabatan → role aplikasi (usulan)

| Jabatan | Unit induk | Role aplikasi |
|---|---|---|
| Direktur | Direksi | Direktur |
| Kepala Bagian Teknik | Bagian Teknik | Kepala Unit |
| Kepala Bagian Administrasi & Keuangan | Bagian Adm & Keuangan | Kepala Unit |
| Kepala Bagian Pelayanan | Bagian Pelayanan | Kepala Unit |
| Kepala Bagian Cabang | Cabang (wilayah) | Kepala Unit |
| Kepala Unit (wilayah, mis. Indralaya, Tanjung Raja) | Unit wilayah | Kepala Unit |
| Kasubag Keuangan / Langganan / Umum | Subbag di bawah Kabag Adm & Keu | Kepala Unit (scope = subbag-nya) |
| Kasubag Produksi / Distribusi & Pemeliharaan / Perencanaan | Subbag di bawah Kabag Teknik | Kepala Unit (scope = subbag-nya) |
| Kasubag Pelayanan | Subbag Pelayanan | Kepala Unit (scope = subbag-nya) |
| Staff HR / Kepegawaian Umum & SDM | Bagian Umum / SDM | Staff HR |
| Staff Keuangan, Staff Umum, Staff Administrasi | Unit masing-masing | Pegawai |
| Operator IPA, Petugas Lapangan, Petugas Inkaso | Subbag Operasional IPA / Seksi Inkaso | Pegawai |
| Admin IT / Super Admin (Jack + tim IT) | — | Super Admin |

Struktur unit (gabungan Perda 2006 + data HRIS):

- **Direksi**
  - **Bagian Teknik** → Subbag Produksi, Subbag Distribusi & Pemeliharaan, Subbag Perencanaan, Subbag Operasional IPA
  - **Bagian Administrasi & Keuangan** → Subbag Keuangan, Subbag Langganan, Subbag Umum
  - **Bagian Pelayanan** → Subbag Pelayanan
  - **Bagian Umum / SDM** → Kepegawaian Umum & SDM
  - **Cabang / Unit wilayah** (Indralaya, Tanjung Raja, …) → Seksi Inkaso, Seksi Umum, Seksi Perencanaan, Seksi Teknik

---

## 2. Lima role aplikasi

| Role | Siapa | Inti kewenangan |
|---|---|---|
| **Super Admin** | IT (Jack + yang ditunjuk) | Semua pengaturan sistem |
| **Direktur** | Direktur | Lihat semua, tanpa ubah data orang |
| **Kepala Unit** | Kabag, Kacab, Kepala Unit wilayah, Kasubag | Lihat + setujui koreksi di unitnya |
| **Staff HR** | Kepegawaian / SDM | Operasional kepegawaian harian |
| **Pegawai** | Semua staf & operator | Absen + lihat data sendiri |

(Opsional, belum diputuskan: **Dewan Pengawas** — akses baca rekap saja, tanpa login harian. Perlu konfirmasi apakah mereka butuh akun.)

---

## 3. Matriks akses

| Fitur | Super Admin | Direktur | Kepala Unit | Staff HR | Pegawai |
|---|---|---|---|---|---|
| Absen masuk / pulang + selfie | ✓ | ✓ | ✓ | ✓ | ✓ |
| Lihat riwayat absen sendiri | ✓ | ✓ | ✓ | ✓ | ✓ |
| Ajukan koreksi (lupa absen pulang, dsb.) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Setujui / tolak koreksi | — (bukan tugasnya) | — | ✓ unitnya sendiri | ✓ semua (backup) | — |
| Rekap kehadiran unit sendiri | ✓ | ✓ | ✓ | ✓ | — |
| Rekap kehadiran SEMUA unit | ✓ | ✓ | — | ✓ | — |
| Export rekap (Excel/CSV) | ✓ | ✓ | ✓ (unitnya) | ✓ | — |
| Daftarkan pegawai baru (allowlist) | ✓ | — | — (usulkan ke HR) | ✓ | — |
| Ubah data pegawai / jabatan / unit | ✓ | — | — | ✓ | — |
| Atur role & hak akses | ✓ | — | — | — | — |
| Atur jam kerja, hari libur, pengaturan aplikasi | ✓ | — | — | — | — |
| Lihat audit log (siapa ubah apa) | ✓ | ✓ (baca) | — | — | — |
| Kelola lokasi kerja / radius GPS (nanti) | ✓ | — | — | — | — |

Keterangan:
- **Kepala Unit** melihat unitnya + semua sub-unit di bawahnya. Misal Kabag Teknik melihat Bagian Teknik termasuk Subbag Operasional IPA; Kasubag Produksi hanya melihat Subbag Produksi.
- **Approve koreksi:** usulan alur baru — yang menyetujui adalah **atasan langsung** (Kepala Unit), Staff HR jadi backup kalau atasan berhalangan. Ini beda dengan Presensi v2 sekarang yang approval-nya di admin. Perlu diputuskan.
- **Direktur** tidak bisa mengubah data pegawai — hanya memantau. Kalau direktur mau koreksi sesuatu, lewat HR.
- **Super Admin** sengaja TIDAK menyetujui koreksi harian, supaya tidak jadi bottleneck dan tidak campur urusan operasional.

---

## 4. GPS & batas lokasi — NANTI, bukan sekarang

Sesuai permintaan Jack: absen nanti pakai GPS dan terbatas di area PDAM. Dicatat di sini supaya tidak hilang, tapi **tidak dibangun sekarang**.

Data lokasi sudah ada di HRIS pendahulu (`work_locations` di `hr_core.sql`):

| Lokasi | Koordinat | Radius |
|---|---|---|
| Kantor Pusat PDAM | −3.2410460, 104.6831366 | 50 m |
| IPA Indralaya | −3.2305000, 104.7052000 | 80 m |
| IPA Tanjung Raja | −3.1804000, 104.6501000 | 80 m |

Rancangan kasar untuk nanti:
- Setiap unit punya `default_location_id` (lokasi kerja utama).
- Absen dinyatakan valid hanya kalau posisi GPS pegawai di dalam radius lokasi unitnya.
- Di luar radius → ditolak, atau diterima tapi di-flag untuk diverifikasi (prinsip "accept-but-flag" dari aplikasi Redigma — diputuskan nanti).
- Lokasi cabang/unit lain perlu ditambah — daftar di atas baru 3 titik.

Catatan: ini **membalik sebagian prinsip Presensi v2** (yang NO GPS, login + selfie saja). Itu tidak masalah — Presensi v2 itu prototipe/portofolio Jack, sedangkan ini aplikasi PDAM yang memang butuh GPS. Dua-duanya jalan sendiri-sendiri.

---

## 5. Yang perlu dikonfirmasi Jack

1. **Struktur terbaru pasca-Perumda 2023** — apakah Bagian Pelayanan memang ada? Cabang/unit wilayah apa saja yang aktif sekarang (Indralaya, Tanjung Raja, …)?
2. **Siapa Super Admin** — Jack sendiri? Ada admin IT lain?
3. **Dewan Pengawas** perlu akun baca-rekap atau tidak?
4. **Approver koreksi:** atasan langsung, atau tetap HR saja?
5. **Jam kerja PDAM** — apakah sama 08:00–16:00 seperti prototipe, atau ada shift (khususnya Operator IPA yang mungkin jaga instalasi)?
6. **Cuti / izin / sakit** — ditunda ke fase HRIS (sesuai spek v2), dicatat saja di sini.
7. Jumlah pegawai aktif sekarang (skripsi lama menyebut ±101 orang).
