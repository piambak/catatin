-- Validasi transaksi di database (#40).
--
-- Dua celah yang sebelumnya lolos dari RLS maupun constraint:
--   1. Kategori tidak dicocokkan dengan jenis transaksi — kategori pemasukan
--      (mis. `ic1` Penjualan Produk) bisa dipakai transaksi EXPENSE, sehingga
--      agregat bulanan dan HPP salah hitung.
--   2. Tanggal tidak dibatasi — salah ketik tahun seperti 0026 atau 20026
--      tetap tersimpan dan menghilang dari semua layar yang menyaring per tahun.
--
-- Yang sudah dijaga skema awal dan tidak diubah di sini: nominal > 0, kategori
-- harus ada (FK), `type` dan `payment_method` dari daftar tetap, transaksi
-- hanya menempel ke usaha milik sendiri (RLS). Tanggal kalender yang tidak ada
-- (mis. 2026-02-30) sudah ditolak tipe `date` itu sendiri.
--
-- Nama constraint sengaja stabil: klien memetakan nama itu ke field form di
-- supabaseException() (app/lib/core/network/supabase_client.dart).

-- ── Kategori harus cocok dengan jenis transaksi ──────────────────────────────

-- `id` sudah primary key, jadi pasangan (id, type) pasti unik; constraint ini
-- hanya dibutuhkan sebagai target foreign key komposit di bawah.
alter table public.tx_categories
  add constraint tx_categories_id_type_key unique (id, type);

-- FK komposit: (category_id, type) harus ada sebagai (id, type) kategori.
-- Deklaratif, tanpa trigger. FK lama transactions_category_id_fkey tetap ada,
-- jadi kategori yang tidak ada sama sekali masih dilaporkan dengan nama FK lama
-- dan klien bisa membedakan "kategori tidak ada" dari "kategori salah jenis".
alter table public.transactions
  add constraint transactions_category_type_fkey
  foreign key (category_id, type)
  references public.tx_categories (id, type)
  on delete restrict;

-- ── Tanggal dalam rentang yang masuk akal ────────────────────────────────────

-- Batas tetap, bukan current_date: constraint CHECK harus immutable supaya
-- dump/restore dan replay migrasi memberi hasil yang sama.
alter table public.transactions
  add constraint transactions_date_range_check
  check (date between date '2000-01-01' and date '2099-12-31');

comment on constraint transactions_category_type_fkey on public.transactions is
  'Kategori harus sejenis dengan transaksi (INCOME/EXPENSE). Dipetakan klien ke field category_id.';
comment on constraint transactions_date_range_check on public.transactions is
  'Tanggal transaksi 2000-01-01 s.d. 2099-12-31. Dipetakan klien ke field date.';
