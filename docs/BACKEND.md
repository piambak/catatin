# Menyambungkan Backend

Aplikasi ini sudah dirancang untuk hidup **dengan atau tanpa** backend. Halaman
ini menjelaskan cara memasangnya dan kontrak API yang diharapkan klien.

---

## 1. Tiga mode sumber data

Mode dipilih lewat `--dart-define`, tidak pernah dengan menyunting kode.

| Mode | Kapan dipakai | Perilaku |
| --- | --- | --- |
| `mock` | Demo publik, kontributor baru, tes | Nol request jaringan. Semua data dari `app/lib/core/data/mock_data.dart`. |
| `hybrid` | Backend sedang dibangun bertahap | Coba API dulu; kalau endpoint belum ada atau jaringan mati, jatuh ke data mock. |
| `api` | Produksi | Semua dari backend. Kegagalan naik ke UI sebagai `ApiException`. |

Tanpa `API_BASE_URL`, aplikasi otomatis jalan mode `mock` — jadi `flutter run`
polos selalu berhasil.

```bash
# Backend lokal, endpoint belum lengkap
cd app
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=DATA_SOURCE=hybrid \
  --dart-define=ENABLE_API_LOG=true
```

Kalau capek mengetik, salin `app/dart_define.example.json` menjadi
`app/dart_define.json` (sudah di-gitignore) lalu:

```bash
flutter run --dart-define-from-file=dart_define.json
```

| Define | Default | Arti |
| --- | --- | --- |
| `API_BASE_URL` | *(kosong)* | Root URL backend, mis. `https://api.catatin.id/api/v1` |
| `DATA_SOURCE` | `mock` bila URL kosong, selain itu `hybrid` | `mock` \| `hybrid` \| `api` |
| `ENABLE_API_LOG` | `false` | Cetak request/response ke konsol |
| `API_CONNECT_TIMEOUT_MS` | `15000` | Timeout koneksi |
| `API_RECEIVE_TIMEOUT_MS` | `15000` | Timeout baca respons |

---

## 2. Di mana kode HTTP-nya

```
screens/  →  core/services/  →  core/data/  →  api | hybrid | mock
             (fasad tipis)      (kontrak)
```

Satu-satunya file yang perlu kamu sunting saat menyambungkan backend:

| Berkas | Isi |
| --- | --- |
| `app/lib/core/data/api_repositories.dart` | **Semua** panggilan HTTP |
| `app/lib/core/constants/app_constants.dart` | Path endpoint (`ApiEndpoints`) |
| `app/lib/core/network/api_client.dart` | Konfigurasi Dio, header auth, refresh token |

Tidak ada satu pun `Dio` di `screens/` atau `widgets/`. Kalau kamu merasa perlu
memanggil HTTP dari layar, itu tanda kontraknya yang kurang — tambahkan method
di `repositories.dart`.

### Menambah endpoint baru

1. Tambah path di `ApiEndpoints`.
2. Tambah method di kelas abstrak yang sesuai di `core/data/repositories.dart`.
3. Implementasikan di `api_repositories.dart` **dan** `mock_repositories.dart`
   (analyzer akan menolak kalau salah satunya lupa).
4. Teruskan lewat fasad di `core/services/` supaya layar tidak menyentuh
   repository langsung.
5. Tambah bagiannya di dokumen ini.

---

## 3. Kontrak API

Semua path relatif terhadap `API_BASE_URL`. Semua body JSON.

### Autentikasi

Request selain login/register/refresh membawa:

```http
Authorization: Bearer <access_token>
```

Saat server membalas `401`, klien otomatis sekali memanggil `/auth/refresh`
dengan refresh token tersimpan, lalu mengulang request aslinya. Kalau refresh
ikut gagal, sesi lokal dihapus dan pengguna dikembalikan ke layar masuk.

#### `POST /auth/register`

```json
{ "name": "Rizal", "email": "rizal@contoh.id", "password": "rahasia123" }
```

Balas `201`. Klien langsung memanggil `/auth/login` setelahnya, jadi respons
register tidak dibaca.

#### `POST /auth/login`

```json
{ "email": "rizal@contoh.id", "password": "rahasia123" }
```

```json
{
  "access_token": "eyJhbGciOi…",
  "refresh_token": "eyJhbGciOi…",
  "user": {
    "id": "usr_01",
    "name": "Rizal",
    "email": "rizal@contoh.id",
    "image": null,
    "created_at": "2026-01-15T08:30:00Z"
  }
}
```

#### `POST /auth/refresh`

```json
{ "refresh_token": "eyJhbGciOi…" }
```

```json
{ "access_token": "eyJhbGciOi…" }
```

#### `GET /auth/me`

```json
{ "user": { "id": "usr_01", "name": "Rizal", "email": "rizal@contoh.id", "image": null, "created_at": "2026-01-15T08:30:00Z" } }
```

---

### Profil usaha

#### `GET /business`

```json
{
  "profiles": [
    {
      "id": "biz_01",
      "user_id": "usr_01",
      "business_name": "Batik Kencana",
      "owner_name": "Rizal",
      "npwp": "12.345.678.9-012.000",
      "business_type": "DAGANG",
      "pkp_status": false,
      "employee_count": 3,
      "is_active": true,
      "created_at": "2026-01-15T08:30:00Z"
    }
  ]
}
```

Daftar kosong berarti pengguna belum menyiapkan profil usaha — klien
mengarahkannya ke layar onboarding.

#### `POST /business` dan `PATCH /business/{id}`

```json
{
  "business_name": "Batik Kencana",
  "owner_name": "Rizal",
  "npwp": "12.345.678.9-012.000",
  "business_type": "DAGANG",
  "pkp_status": false,
  "employee_count": 3
}
```

Balas `{ "profile": { …seperti di atas… } }`.

---

### Transaksi

#### `GET /transactions`

Query: `month`, `year`, `business_id`, `limit`.

```json
{
  "transactions": [
    {
      "id": "trx_01",
      "business_id": "biz_01",
      "date": "2026-08-05",
      "type": "INCOME",
      "amount": 5200000,
      "category": {
        "id": "ic1",
        "name": "Penjualan Produk",
        "type": "INCOME",
        "tax_relevant": true,
        "is_cogs": false,
        "icon": "🛍️",
        "color": "#059669"
      },
      "description": "Penjualan produk online",
      "payment_method": "QRIS",
      "receipt_note": null,
      "created_at": "2026-08-05T10:12:00Z"
    }
  ]
}
```

* `type`: `INCOME` | `EXPENSE`
* `amount`: rupiah penuh, bukan sen
* `date`: `YYYY-MM-DD`
* `payment_method`: `CASH` | `TRANSFER` | `QRIS` | `KARTU_DEBIT` | `KARTU_KREDIT` | `COD` | `OTHER`
* `category` disematkan penuh (bukan sekadar id) supaya daftar transaksi bisa
  dirender tanpa request kedua.

#### `GET /transactions/{id}` → `{ "transaction": { … } }`

#### `POST /transactions`

```json
{
  "business_id": "biz_01",
  "date": "2026-08-05",
  "type": "INCOME",
  "amount": 5200000,
  "category_id": "ic1",
  "description": "Penjualan produk online",
  "payment_method": "QRIS",
  "receipt_note": null
}
```

Balas `201`. Isi respons tidak dibaca klien.

#### `DELETE /transactions/{id}` → `204`

#### `GET /tx-categories`

```json
{
  "categories": [
    { "id": "ic1", "name": "Penjualan Produk", "type": "INCOME", "tax_relevant": true, "is_cogs": false, "icon": "🛍️", "color": "#059669" }
  ]
}
```

`color` wajib hex `#RRGGBB`; `icon` satu emoji.

---

### Dashboard

#### `GET /dashboard/summary?month=8&year=2026`

```json
{
  "monthly_income": 28500000,
  "monthly_expense": 18200000,
  "monthly_profit": 10300000,
  "ytd_omzet": 285000000,
  "tx_count": 12
}
```

Persentase ambang PKP dihitung di klien (`ytd_omzet / 4.800.000.000`), jadi
backend tidak perlu mengirimkannya.

#### `GET /dashboard/kpi-history?metric=income`

`metric`: `income` | `expense` | `profit` | `ytd`.

```json
{ "points": [ { "month": "Jan", "value": 19200000 }, { "month": "Feb", "value": 21500000 } ] }
```

`month` adalah label pendek Bahasa Indonesia yang langsung dipakai sebagai
label sumbu X.

#### `GET /tax-calendar?limit=3`

```json
{
  "deadlines": [
    { "id": "dl_01", "label": "PPh Final Masa Oktober", "tax_type": "PPH_FINAL", "deadline": "2026-11-15T00:00:00Z", "status": "PENDING" }
  ]
}
```

`tax_type`: `PPH_FINAL` | `PPH21` | `SPT` | `PPN`. `status`: `PENDING` | `PAID` | `LATE`.

---

### Pustaka peraturan

> ⚠️ Daftarkan rute `/documents/categories` **sebelum** `/documents/{id}` di
> router backend. Kalau terbalik, `categories` akan ditangkap sebagai id.

#### `GET /documents/categories`

```json
{ "categories": [ { "id": "c1", "name": "PPh Final UMKM", "slug": "pph-final", "icon": "📊", "color": "#B85C38" } ] }
```

#### `GET /documents?q=&category=&type=`

```json
{
  "documents": [
    {
      "id": "d1",
      "title": "PP 23 Tahun 2018 — PPh Final UMKM",
      "type": "PP",
      "category_id": "c1",
      "summary": "Mengatur tarif PPh Final 0,5% dari peredaran bruto…",
      "effective_date": "2018-07-01",
      "status": "ACTIVE",
      "tags": ["UMKM", "Tarif 0.5%"],
      "body_html": null
    }
  ]
}
```

* `type`: `UU` | `PP` | `PMK` | `PER_DJP` | `SE` | `KEP` | `PANDUAN`
* `status`: `ACTIVE` berarti masih berlaku; nilai lain ditandai "tidak berlaku"
* `tags` boleh berupa daftar string atau daftar objek `{ "label": "…" }`
* `body_html` hanya perlu diisi pada endpoint detail

#### `GET /documents/{id}` → `{ "document": { …termasuk `body_html`… } }`

---

### Bentuk error

Semua status non-2xx memakai bentuk yang sama:

```json
{
  "error": "Email sudah terdaftar",
  "details": { "email": "sudah dipakai akun lain" }
}
```

`message` diterima sebagai alias `error`. Klien memetakan status ke pesan
Bahasa Indonesia di `ApiException.userMessage`:

| Status | Ditampilkan ke pengguna |
| --- | --- |
| 400 | isi `details` pertama, atau "Data tidak valid." |
| 401 | "Sesi Anda telah berakhir. Silakan masuk kembali." |
| 403 | "Anda tidak memiliki akses ke fitur ini." |
| 404 | "Data tidak ditemukan." |
| 409 | isi `error` apa adanya |
| 422 | "Data yang dikirim tidak valid." |
| 500 | "Terjadi kesalahan server. Coba lagi nanti." |
| gagal jaringan | "Terjadi kesalahan. Periksa koneksi internet Anda." |

---

## 4. Yang **tidak** butuh backend

* **Simulator pajak** (`core/services/simulator_service.dart`) — murni hitungan
  lokal berdasarkan PP 23/2018 dan PMK 168/2023. Tarif dan tabel TER ada di
  `AppConstants`.
* **Bookmark peraturan** — disimpan di SharedPreferences. Pindahkan ke backend
  hanya kalau bookmark perlu sinkron antar-perangkat.
* **Preferensi tema** — lokal.

---

## 5. CORS (khusus web)

Situs tayang dari `https://piambak.github.io`, jadi backend harus mengizinkan
origin itu:

```
Access-Control-Allow-Origin: https://piambak.github.io
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS
```

Tambahkan `http://localhost:*` untuk pengembangan. Tanpa ini aplikasi web akan
gagal total meski backend sehat — dan pesannya di konsol peramban, bukan di UI.

## 6. Menyalakan backend di situs publik

Setelah backend tayang, sunting `.github/workflows/publish-web.yml`:

```yaml
run: |
  flutter build web --release --base-href "/catatin/" \
    --dart-define=API_BASE_URL=${{ vars.API_BASE_URL }} \
    --dart-define=DATA_SOURCE=api
```

Simpan URL-nya sebagai **Variable** repo (bukan Secret) — nilainya ikut
ter-compile ke bundel JS publik, jadi memang bukan rahasia. Jangan pernah
menaruh API key di `--dart-define`: apa pun yang masuk build web bisa dibaca
siapa saja.
