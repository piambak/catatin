-- supabase/tests/database/04_validasi_transaksi.test.sql
--
-- Validasi transaksi di database (#40): nominal > 0, tanggal yang ada dan
-- dalam rentang 2000–2099, kategori yang ada DAN sejenis dengan transaksinya,
-- serta metode pembayaran dari daftar tetap.
--
-- Semua dijalankan sebagai pengguna `authenticated` — jalur yang sama dengan
-- klien Supabase — jadi RLS ikut berlaku. Pesan galat dicocokkan persis karena
-- nama constraint di dalamnya dipetakan klien ke field form
-- (supabaseException() di app/lib/core/network/supabase_client.dart).
--
-- Jalankan: supabase test db

begin;
create extension if not exists pgtap with schema extensions;

select plan(14);

-- ── Data awal (sebagai postgres, melewati RLS) ──────────────────────────────

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@contoh.test');

insert into public.business_profiles (id, user_id, business_name) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', '11111111-1111-4111-8111-111111111111', 'Usaha A');

-- ── Skema ────────────────────────────────────────────────────────────────────

select fk_ok(
  'public', 'transactions', array['category_id', 'type'],
  'public', 'tx_categories', array['id', 'type'],
  'transactions (category_id, type) merujuk tx_categories (id, type)'
);

-- ── Sebagai A ────────────────────────────────────────────────────────────────

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into public.transactions (id, business_id, date, type, amount, category_id)
     values ('a0000000-0000-4000-8000-000000000001',
             'aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-21', 'INCOME', 1000, 'ic1') $$,
  'transaksi valid tersimpan'
);

-- Nominal

select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-21', 'INCOME', 0, 'ic1') $$,
  '23514',
  'new row for relation "transactions" violates check constraint "transactions_amount_check"',
  'nominal 0 ditolak'
);
select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-21', 'EXPENSE', -5000, 'ec1') $$,
  '23514',
  'new row for relation "transactions" violates check constraint "transactions_amount_check"',
  'nominal negatif ditolak'
);

-- Kategori

select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-21', 'INCOME', 1000, 'zz9') $$,
  '23503',
  'insert or update on table "transactions" violates foreign key constraint "transactions_category_id_fkey"',
  'kategori yang tidak ada ditolak dengan FK lama — klien membacanya sebagai "tidak ditemukan"'
);
select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-21', 'EXPENSE', 1000, 'ic1') $$,
  '23503',
  'insert or update on table "transactions" violates foreign key constraint "transactions_category_type_fkey"',
  'kategori pemasukan pada transaksi EXPENSE ditolak'
);
select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-21', 'INCOME', 1000, 'ec1') $$,
  '23503',
  'insert or update on table "transactions" violates foreign key constraint "transactions_category_type_fkey"',
  'kategori pengeluaran pada transaksi INCOME ditolak'
);
select throws_ok(
  $$ update public.transactions set type = 'EXPENSE'
      where id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23503',
  'insert or update on table "transactions" violates foreign key constraint "transactions_category_type_fkey"',
  'mengganti jenis tanpa mengganti kategori ditolak'
);
select lives_ok(
  $$ update public.transactions set type = 'EXPENSE', category_id = 'ec1'
      where id = 'a0000000-0000-4000-8000-000000000001' $$,
  'mengganti jenis bersama kategorinya diterima'
);

-- Tanggal

select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '1999-12-31', 'INCOME', 1000, 'ic1') $$,
  '23514',
  'new row for relation "transactions" violates check constraint "transactions_date_range_check"',
  'tanggal sebelum 2000 ditolak'
);
select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2100-01-01', 'INCOME', 1000, 'ic1') $$,
  '23514',
  'new row for relation "transactions" violates check constraint "transactions_date_range_check"',
  'tanggal setelah 2099 ditolak'
);
select lives_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2000-01-01', 'INCOME', 1000, 'ic1'),
            ('aaaaaaaa-0000-4000-8000-00000000000a', '2099-12-31', 'INCOME', 1000, 'ic1') $$,
  'tanggal tepat di kedua batas diterima'
);
select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-02-30', 'INCOME', 1000, 'ic1') $$,
  '22008',
  'date/time field value out of range: "2026-02-30"',
  'tanggal kalender yang tidak ada ditolak tipe date'
);

-- Metode pembayaran

select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id, payment_method)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-21', 'INCOME', 1000, 'ic1', 'BITCOIN') $$,
  '23514',
  'new row for relation "transactions" violates check constraint "transactions_payment_method_check"',
  'metode pembayaran di luar daftar ditolak'
);

select * from finish();
rollback;
