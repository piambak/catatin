# Design tokens — Catatin

**Versi:** 0.1 (draf) · **Tanggal:** 8 September 2026
**Pasangan dokumen:** [`PRD-REDESAIN-UI.md`](PRD-REDESAIN-UI.md)

> Dokumen ini punya dua bagian. **Bagian A** mengaudit token yang dipakai
> sekarang — itu fakta dari `app/lib/core/theme/app_theme.dart` dan sebaran
> nilai di seluruh widget. **Bagian B** adalah sistem usulan penggantinya.
>
> Bagian B belum disepakati. Nilai warnanya sengaja diturunkan dari palet yang
> sudah ada, bukan palet baru — keputusan identitas merek ada di tangan
> desainer, bukan dokumen ini.

---

# Bagian A — Audit keadaan sekarang

## A.1 Warna

`AppColors` di `app_theme.dart` memakai *getter*, bukan konstanta, sehingga
seluruh aplikasi berganti mode gelap seketika lewat `themeNotifier`. Pola itu
bagus dan **dipertahankan**. Masalahnya jumlah token.

### Merek & aksen

| Token | Terang | Gelap |
| --- | --- | --- |
| `brand` | `#FFA400` | sama |
| `brandDark` | `#CC8300` | sama |
| `brandLight` | `#FFF3CC` | `#232528` |
| `brandSurface` | `#FFFAF0` | sama |
| `accent` | `#009FFD` | sama |
| `accentDark` | `#007ACC` | sama |
| `accentLight` | `#EAF6FF` | `#232528` |
| `dark` | `#2A2A72` | sama |
| `darkMid` | `#3D3D8F` | sama |
| `darkMuted` | `#8888BB` | sama |

### Semantik — 4 keluarga × 4 varian

| Keluarga | Dasar | Light (terang) | Light (gelap) | Border | Badge fg |
| --- | --- | --- | --- | --- | --- |
| income | `#1B8A4B` | `#E6F7EE` | `#232528` | `#9CDDB7` / `#1B8A4B` | `#27500A` / `#7AE8A6` |
| expense | `#D92B2B` | `#FCEBEB` | `#232528` | `#F7C1C1` / `#D92B2B` | `#791F1F` / `#FF9A9A` |
| warning | `#B07D2A` | `#FAEEDA` | `#232528` | `#FAC775` / `#B07D2A` | `#633806` / `#FFCC70` |
| navy | `#009FFD` | `#EAF6FF` | `#232528` | `#B3E0FE` / `#185FA5` | `#0C447C` / `#7DCFFF` |

### Netral

`stone50` → `stone900`, sembilan langkah, masing-masing dengan nilai terang dan
gelap terpisah. Ditambah `bgPage`, `bgCard`, `bgSecondary`.

### Masalah yang terlihat dari tabel di atas

1. **Lebih dari 30 token warna** untuk aplikasi 4 layar.
2. **`navy` sama persis dengan `accent`** (`#009FFD`) — dua nama untuk satu
   warna, dipakai bergantian tanpa aturan.
3. **Enam token berbeda runtuh jadi `#232528` di mode gelap** — semua varian
   `*Light`. Artinya pembeda semantik (hijau/merah/kuning/biru) yang jadi ciri
   khas di mode terang **hilang total** di mode gelap; yang tersisa cuma warna
   border dan teks.
4. **`brandSurface` dan `dark*` tidak punya nilai gelap sama sekali** — dipakai
   apa adanya di kedua mode.

## A.2 Tipografi

Tiga keluarga, dipanggil lewat fungsi pembantu (`serif(size)`, `sans(size)`,
`mono(size)`), sehingga ukurannya diteruskan sebagai argumen dan tidak ada
skala tetap.

| Keluarga | Dipakai untuk | `height` | Catatan |
| --- | --- | --- | --- |
| **DMSerif** | Judul, app bar (17px) | 1.2 | Hanya berat 400 |
| **DMSans** | Seluruh teks | 1.5 | Berat 400/500/600/700 |
| **monospace** | Angka & mata uang | — | `letterSpacing: -0.3`, berat 500 |
| DMSans (khusus) | Label huruf besar | — | 10px, `letterSpacing: 2.0` |

Font di-*bundle*, tidak diunduh saat runtime — bagus untuk offline dan privasi;
**dipertahankan**.

Ukuran yang muncul sebagai literal: 10, 11, 13, 14, 16, 17, 20 — tanpa rasio
yang konsisten.

## A.3 Spasi

Tidak ada skala. Nilai `SizedBox` yang benar-benar dipakai, diurut frekuensi:

| Nilai | Jumlah pemakaian |
| --- | --- |
| 10 | 71 |
| 8 | 65 |
| 14 | 55 |
| 6 | 28 |
| 12 | 25 |
| 4 | 24 |
| 2 | 17 |
| 20 | 14 |
| 16 | 14 |
| 5 | 9 |
| 3 | 8 |
| 24 | 5 |

**Dua belas nilai berbeda**, termasuk 3 dan 5 yang tidak masuk kelipatan apa
pun. `EdgeInsets.all()` menambah 13 dan 32.

## A.4 Radius sudut

Sepuluh nilai berbeda: 2, 3, 6, 7, 8, 9, 10, 12, 14, 20. Yang terbanyak 8 (32×)
dan 10 (20×), tapi 9 dipakai 14× dan 7 dipakai 9× — beda satu piksel dari
tetangganya, tidak mungkin disengaja.

## A.5 Elevasi

`elevation: 0` di seluruh tema (app bar, kartu, tombol, dialog). Hanya **3
`BoxShadow`** tersisa di seluruh `lib/`, dengan `blurRadius` 6, 8, dan 12.
Aplikasi ini praktis sudah flat — tinggal dituntaskan.

## A.6 Breakpoint

Tidak ada. Lima nilai literal tersebar di lima file: 480, 500, 600, 680, 700.
Di atas ~700px tidak ada penanganan.

---

# Bagian B — Sistem usulan

Semua target di bawah menjawab R-2 sampai R-4 dan R-10 di PRD.

## B.1 Warna — target ≤16 token

### Prinsip

- **Satu** warna merek, **satu** aksen, **tiga** semantik, sisanya netral.
- Setiap token punya nilai terang **dan** gelap yang diputuskan sengaja. Tidak
  boleh dua token semantik berbeda menghasilkan warna gelap yang sama (R-10).
- Warna tidak pernah jadi satu-satunya pembawa makna — selalu berpasangan
  dengan ikon atau teks (syarat aksesibilitas).

### Token inti

| Token | Terang | Gelap | Dipakai untuk |
| --- | --- | --- | --- |
| `brand` | `#FFA400` | `#FFB733` | Aksi utama, aksen aktif |
| `brandMuted` | `#FFF3CC` | `#3A3320` | Latar tenang bernuansa merek |
| `accent` | `#009FFD` | `#3DB5FF` | Tautan, info, grafik sekunder |
| `accentMuted` | `#EAF6FF` | `#1B2E3D` | Latar tenang bernuansa aksen |
| `income` | `#1B8A4B` | `#3FBF75` | Pemasukan |
| `incomeMuted` | `#E6F7EE` | `#16301F` | Latar pemasukan |
| `expense` | `#D92B2B` | `#FF6B6B` | Pengeluaran |
| `expenseMuted` | `#FCEBEB` | `#341A1A` | Latar pengeluaran |
| `warning` | `#B07D2A` | `#E0A845` | Peringatan ambang PKP, tenggat |
| `warningMuted` | `#FAEEDA` | `#332916` | Latar peringatan |

> Nilai `*Muted` mode gelap di atas adalah **usulan awal** — masing-masing perlu
> diverifikasi kontrasnya (lihat B.6), bukan diambil begitu saja.

### Netral — turun dari 9 langkah jadi 5

| Token | Terang | Gelap | Dipakai untuk |
| --- | --- | --- | --- |
| `surface` | `#FFFFFF` | `#2D3035` | Permukaan kartu |
| `surfaceSunken` | `#F4F9FF` | `#232528` | Latar halaman |
| `border` | `#CDD8E8` | `#454B55` | Garis pemisah, tepi kartu |
| `textMuted` | `#667788` | `#9AAABB` | Teks sekunder, label |
| `text` | `#1A2430` | `#EDF2F7` | Teks utama |

**Total: 15 token.** Memenuhi target ≤16.

### Yang dihapus

- `navy*` — duplikat `accent`, ganti semua pemakaiannya
- `dark`, `darkMid`, `darkMuted` — sisa sidebar yang tidak dipakai lagi
- `brandSurface`, `brandDark`, `accentDark` — bisa diturunkan saat dibutuhkan
- Seluruh `*BadgeFg` — turunkan dari pasangan `*`/`*Muted`
- Empat langkah netral tengah (`stone100`, `stone300`, `stone600`, `stone800`)

## B.2 Tipografi — dua keluarga

| Peran | Keluarga | Ukuran | Berat | Tinggi baris |
| --- | --- | --- | --- | --- |
| `display` | DMSerif | 28 | 400 | 1.2 |
| `title` | DMSerif | 20 | 400 | 1.25 |
| `heading` | DMSans | 16 | 600 | 1.4 |
| `body` | DMSans | 14 | 400 | 1.5 |
| `bodyStrong` | DMSans | 14 | 600 | 1.5 |
| `caption` | DMSans | 12 | 400 | 1.4 |
| `label` | DMSans | 11 | 600 | 1.3, `letterSpacing: 0.5` |
| `numeric` | DMSans | mengikuti konteks | 500 | — |

### `monospace` dihapus

Angka rupiah tidak butuh keluarga huruf terpisah — cukup **tabular figures**
dari DMSans, sehingga digit tetap sejajar di kolom tanpa mengganti font:

```dart
const TextStyle(
  fontFamily: 'DMSans',
  fontFeatures: [FontFeature.tabularFigures()],
)
```

> **Perlu diverifikasi:** pastikan berkas DMSans yang di-*bundle* memuat fitur
> `tnum`. Kalau tidak, pertahankan `monospace` khusus untuk tabel angka dan
> catat pengecualiannya di sini.

Skala turun dari 7+ ukuran acak ke **6 langkah**: 11, 12, 14, 16, 20, 28.

## B.3 Spasi — skala 4pt

| Token | Nilai | Dipakai untuk |
| --- | --- | --- |
| `space1` | 4 | Jarak antar-elemen rapat (ikon↔teks) |
| `space2` | 8 | Jarak dalam komponen |
| `space3` | 12 | Padding kartu kecil |
| `space4` | 16 | Padding kartu standar, jarak antar-bagian |
| `space5` | 24 | Jarak antar-blok besar |
| `space6` | 32 | Margin halaman di layar lebar |

**Enam nilai**, turun dari dua belas. Pemetaan dari nilai lama:

| Lama | Baru |
| --- | --- |
| 2, 3, 4, 5 | `space1` (4) |
| 6, 8 | `space2` (8) |
| 10, 12, 13 | `space3` (12) |
| 14, 16 | `space4` (16) |
| 20, 24 | `space5` (24) |
| 32 | `space6` (32) |

> Perhatikan: nilai 10 dan 14 adalah dua yang **paling sering** dipakai
> sekarang (71× dan 55×), dan keduanya naik/turun saat dipetakan. Perubahan
> ritme visualnya akan terasa — ini disengaja, tapi perlu dilihat langsung
> sebelum disetujui.

## B.4 Radius

| Token | Nilai | Dipakai untuk |
| --- | --- | --- |
| `radiusSm` | 8 | Tombol, input, badge |
| `radiusMd` | 12 | Kartu |
| `radiusLg` | 20 | Bottom sheet, dialog |
| `radiusFull` | 999 | Pil, avatar |

Empat nilai, turun dari sepuluh.

## B.5 Elevasi & garis

| Token | Nilai |
| --- | --- |
| Bayangan | **tidak ada** — nol `BoxShadow` (R-2) |
| Garis kartu | 1px `border` (naik dari 0,5px agar terlihat konsisten di layar non-retina) |
| Pemisah | 1px `border` |

Perbedaan permukaan dinyatakan lewat `surface` vs `surfaceSunken`, bukan
bayangan.

## B.6 Kontras — syarat, bukan saran

| Pasangan | Rasio minimum |
| --- | --- |
| `text` di atas `surface` / `surfaceSunken` | 4,5:1 |
| `textMuted` di atas `surface` | 4,5:1 |
| Teks di atas `*Muted` | 4,5:1 |
| Ikon & batas komponen | 3:1 |
| Teks besar (≥20px berat 600) | 3:1 |

Setiap pasangan wajib diperiksa **di kedua mode** sebelum token disahkan.
Nilai gelap di B.1 adalah usulan yang belum diukur.

## B.7 Breakpoint

Satu file, mis. `app/lib/core/theme/breakpoints.dart`:

| Nama | Rentang | Navigasi | Kolom | Margin |
| --- | --- | --- | --- | --- |
| `compact` | <600 | Bottom nav | 1 | `space4` |
| `medium` | 600–1023 | Bottom nav | 2 | `space5` |
| `expanded` | ≥1024 | Navigation rail | 3 | `space6`, konten dibatasi 1200px |

Menggantikan lima nilai literal 480/500/600/680/700. Angka breakpoint tidak
boleh muncul di luar file ini (R-4).

---

## B.8 Komponen inti

Dibuat publik di `lib/widgets/common/` supaya bisa dipakai ulang (R-7).

| Komponen | Spesifikasi |
| --- | --- |
| `AppCard` | `surface`, `radiusMd`, border 1px, padding `space4`. **Tidak boleh bersarang** (R-1) |
| `AppButton` | Tinggi 48 (target sentuh), `radiusSm`, varian: primary/secondary/ghost/danger |
| `AppField` | Tinggi 48, `radiusSm`, label di atas (bukan *floating*), teks galat di bawah |
| `AppBadge` | `radiusFull`, padding `space1`/`space2`, varian income/expense/warning/neutral |
| `AppSectionHeader` | `label` huruf kecil + aksi opsional di kanan |
| `AppEmptyState` | Ikon + judul + penjelasan + satu aksi |
| `AppErrorState` | Sama, plus tombol coba lagi |
| `AppSkeleton` | Pengganti `shimmer` untuk keadaan memuat |
| `AppDatePicker` | **Satu** komponen tanggal/bulan bersama — menggantikan `month_picker.dart` (497 baris) dan 3 `showDatePicker` (R-6) |
| `AppCalendar` | **Satu** komponen kalender untuk kelima tampilan (R-8) |

Empat yang pertama sebagian sudah ada di `app_widgets.dart` (`AppCard`,
`SectionLabel`, `StatusBadge`, `ShimmerBox`, `EmptyState`, `ErrorState`,
`LabelDivider`) — jadi titik awalnya bukan dari nol.

---

## Urutan penerapan yang disarankan

Tiap langkah bisa jadi satu PR terpisah, sesuai aturan satu-topik-satu-PR:

1. **Token dulu, tanpa perubahan tampilan.** Buat file token & breakpoint,
   petakan nama lama ke baru lewat alias. Belum ada yang berubah secara visual.
2. **Bersihkan `withOpacity`** (T-6, 66 pemakaian) — mekanis, PR sendiri.
3. **Terapkan skala spasi & radius.** Di sinilah tampilan mulai berubah.
4. **Pangkas palet.** Hapus `navy*`, `dark*`, badge fg; perbaiki mode gelap.
5. **Pecah `accounting_screen.dart`** (1731 baris) dan angkat komponen bersama.
6. **Satukan kalender & date picker.**
7. **Tata letak responsif** — navigation rail, batas lebar konten, buka portrait lock.
8. **Aksesibilitas** — label semantik, target sentuh, verifikasi kontras.

Langkah 1–2 aman dan tidak mengubah tampilan; keduanya bisa jalan sekarang
tanpa menunggu keputusan desainer. Langkah 3 ke atas butuh persetujuan arah
visual lebih dulu.
