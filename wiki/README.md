---
title: Wiki Catatin
description: "Pintu masuk basis pengetahuan Catatin: daftar seluruh halaman per bagian dan cara kerja folder wiki."
tags:
  - indeks
---

Seluruh pengetahuan proyek Catatin ada di folder ini — satu tempat, bukan
tersebar antara README, komentar kode, dan ingatan orang.

Folder ini dikelola sebagai basis pengetahuan
[OpenKnowledge](https://openknowledge.ai): bisa disunting bersama secara
real-time, punya preview hidup, dan divalidasi otomatis untuk tautan mati serta
pelanggaran gaya markdown.

---

## Saya ingin…

| Kalau kamu ingin… | Baca |
| --- | --- |
| Menjalankan proyeknya sekarang | [Mulai cepat](panduan/mulai-cepat.md) |
| Tahu berkas mana yang boleh disunting | [Kontribusi](panduan/kontribusi.md) |
| Paham bentuk repo dan lapisan aplikasi | [Arsitektur](arsitektur/gambaran-umum.md) |
| Menyiapkan atau memakai Supabase | [Supabase](arsitektur/supabase.md) |
| Mengatur login Google atau kata sandi akun | [Supabase §5](arsitektur/supabase.md#5-pengaturan-auth) |
| Paham mode sumber data dan kontrak REST | [Backend & API](arsitektur/backend-dan-api.md) |
| Tahu dari mana angka pajaknya datang | [Aturan pajak](domain/aturan-pajak.md) |
| Paham arti PKP, PTKP, TER, HPP | [Glosarium](domain/glosarium.md) |
| Merilis atau melakukan rollback | [Rilis & deploy](panduan/rilis-dan-deploy.md) |
| Mengubah warna, tipografi, atau jarak | [Design tokens](desain/design-tokens.md) |
| Tahu apa yang sedang dikerjakan | [Linimasa](proyek/linimasa.md) |
| Cari utang teknis untuk dikerjakan | [Backlog teknis](proyek/backlog-teknis.md) |

---

## Seluruh halaman

### Panduan

- **[Mulai cepat](panduan/mulai-cepat.md)** — prasyarat, menjalankan aplikasi,
  memilih sumber data (`mock` / `hybrid` / `api` / `supabase`).
- **[Kontribusi](panduan/kontribusi.md)** — berkas mana yang boleh disunting dan
  mana yang digenerate, alur branch dan PR, gaya kode, penanganan rahasia.
- **[Rilis & deploy](panduan/rilis-dan-deploy.md)** — alur publikasi otomatis,
  build manual, menguji hasil build lokal, rollback, pindah domain.

### Arsitektur

- **[Gambaran umum](arsitektur/gambaran-umum.md)** — bentuk repo, lapisan
  aplikasi, isi `app/lib/`, tema, aset.
- **[Supabase](arsitektur/supabase.md)** — backend situs publik (proyek
  `catatin`): menyiapkan proyek, skema & RLS, pemetaan kontrak, pengaturan Auth
  (login Google, Confirm email, satu akun dua cara masuk), kunci mana yang boleh
  di-commit.
- **[Backend & API](arsitektur/backend-dan-api.md)** — empat mode sumber data,
  kontrak REST tiap endpoint dengan contoh JSON, CORS, cara menyalakan backend
  di situs publik.
- **[Aset](arsitektur/aset.md)** — font, gambar, ikon PWA, pertimbangan ukuran
  bundel web.

### Domain

- **[Aturan pajak](domain/aturan-pajak.md)** — PPh Final 0,5% (PP 23/2018),
  PPh 21 metode TER (PMK 168/2023), PTKP, PPN, kalender jatuh tempo, dan dua
  bug tarif yang sudah diketahui.
- **[Glosarium](domain/glosarium.md)** — istilah pajak dan istilah teknis khas
  repo ini.

### Desain

- **[Design tokens](desain/design-tokens.md)** — audit warna/tipografi/spasi
  yang ada sekarang, dan sistem token yang diusulkan.
- **[PRD redesain UI](desain/prd-redesain-ui.md)** — tujuan, inventaris layar,
  temuan, kebutuhan desain, kriteria penerimaan.
- **[Brief Claude Design](desain/brief-claude-design.md)** — brief kerja untuk
  eksekusi redesain.

### Proyek

- **[Linimasa](proyek/linimasa.md)** — jadwal Fase Dua, Minggu 1–9, milestone
  M1–M5.
- **[Backlog teknis](proyek/backlog-teknis.md)** — temuan T-1..T-20 beserta
  statusnya, dan risiko yang sudah diketahui.
- **[Log progres](proyek/log-progres.md)** — catatan kemajuan harian.

### Sumber

Salinan mentah atau kutipan pendek (`preservation: excerpt`) dokumen eksternal
yang dikutip halaman lain. Tidak diringkas dan tidak ditafsirkan — kalau
sumbernya berubah, simpan salinan baru.

- **[Supabase: API keys](sumber/supabase-api-keys.md)** — publishable key,
  secret key, dan Row Level Security.
- **[Supabase: custom SMTP](sumber/supabase-auth-smtp.md)** — batas SMTP bawaan
  dan risiko mematikan konfirmasi email.
- **[Supabase: harga & pausing](sumber/supabase-pricing-pausing.md)** — proyek
  Free dijeda setelah seminggu tidak aktif, batas paket Free.
- **[Supabase: login Google](sumber/supabase-auth-google.md)** — menyiapkan
  OAuth client, domain `supabase.co` di layar izin.
- **[Supabase: identity linking](sumber/supabase-identity-linking.md)** —
  penggabungan akun berdasarkan email dan kaitannya dengan Confirm email.
- **[Supabase Auth: pasang kata sandi](sumber/supabase-auth-update-password.md)**
  — verifikasi ulang 24 jam, kata sandi saat ini, identitas email eksperimental,
  syarat login kata sandi.
- **[GitHub: issue #149 & #16 (D-7)](sumber/github-issue-149-d7-stack-backend.md)**
  — keputusan stack backend BaaS (Supabase) bersama PO dan rationale lima
  barisnya.

---

## Cara kerja folder ini

**Mana yang hidup, mana yang arsip.** Halaman di *Panduan*, *Arsitektur*, dan
*Domain* menggambarkan keadaan sekarang — kalau kode berubah, halaman itu ikut
diperbarui. Halaman di *Desain* adalah dokumen keputusan yang dibekukan pada
waktunya; jangan ditulis ulang, tulis dokumen baru kalau keputusannya berubah.
*Log progres* adalah catatan sejarah dan sengaja tidak pernah dikoreksi ke
belakang.

**Nomor temuan dipakai di dua tempat.** Kode `T-1`, `T-2`, dan seterusnya muncul
di [backlog teknis](proyek/backlog-teknis.md) *dan* di komentar kode Dart. Itu
disengaja: `grep -rn "T-13" app/ wiki/` langsung memperlihatkan dokumen dan
kodenya sekaligus, jadi ketidakcocokan status ketahuan.

**Angka tidak disalin dari kode.** Tabel tarif dan konstanta tinggal di
`app/lib/core/constants/app_constants.dart`. Wiki menjelaskan aturannya dan
menunjuk ke sana. Alasannya ada di
[aturan pajak](domain/aturan-pajak.md#kenapa-halaman-ini-tidak-menyalin-tabel-ter)
— proyek ini sudah pernah kena akibatnya sekali.

**Folder ini terdaftar di daftar `KEEP`.** `tool/sync_build.sh` menghapus apa
pun di root repo yang bukan hasil build dan tidak terdaftar di allowlist-nya.
`wiki` dan `.ok` ada di sana. Kalau kamu menambah folder baru di root, daftarkan
— kalau tidak, ia hilang pada build berikutnya.
