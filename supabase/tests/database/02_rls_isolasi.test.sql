-- supabase/tests/database/02_rls_isolasi.test.sql
--
-- Isolasi data antar-akun — versi otomatis dari uji manual 13 Sep 2026 di
-- proyek produksi (wiki/proyek/log-progres.md). Dua pengguna fiktif, A dan B,
-- hanya hidup di dalam transaksi ini dan hilang saat rollback.
--
-- Klien Supabase bicara langsung ke Postgres, jadi yang diuji di sini adalah
-- satu-satunya penjaga data pengguna: kebijakan RLS di migrasi.
--
-- Jalankan: supabase test db

begin;
create extension if not exists pgtap with schema extensions;

select plan(17);

-- ── Data awal (sebagai postgres, melewati RLS) ──────────────────────────────

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@contoh.test'),
  ('22222222-2222-4222-8222-222222222222', 'b@contoh.test');

-- A punya kata sandi, B tidak (mis. akun yang daftar lewat Google).
update auth.users set encrypted_password = 'hash-fiktif'
 where id = '11111111-1111-4111-8111-111111111111';

insert into public.business_profiles (id, user_id, business_name) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', '11111111-1111-4111-8111-111111111111', 'Usaha A'),
  ('bbbbbbbb-0000-4000-8000-00000000000b', '22222222-2222-4222-8222-222222222222', 'Usaha B');

insert into public.transactions
  (id, user_id, business_id, date, type, amount, category_id)
values
  -- Januari: pemasukan + pengeluaran HPP (ec1 Bahan Baku, is_cogs)
  ('a0000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111',
   'aaaaaaaa-0000-4000-8000-00000000000a', '2026-01-10', 'INCOME', 1000000, 'ic1'),
  ('a0000000-0000-4000-8000-000000000002', '11111111-1111-4111-8111-111111111111',
   'aaaaaaaa-0000-4000-8000-00000000000a', '2026-01-20', 'EXPENSE', 400000, 'ec1'),
  -- Februari: pengeluaran bukan HPP (ec5 Listrik & Air)
  ('a0000000-0000-4000-8000-000000000003', '11111111-1111-4111-8111-111111111111',
   'aaaaaaaa-0000-4000-8000-00000000000a', '2026-02-05', 'EXPENSE', 250000, 'ec5'),
  -- Tahun lain: tidak boleh ikut agregat 2026
  ('a0000000-0000-4000-8000-000000000004', '11111111-1111-4111-8111-111111111111',
   'aaaaaaaa-0000-4000-8000-00000000000a', '2025-12-31', 'INCOME', 999000, 'ic1');

-- ── Sebagai B ────────────────────────────────────────────────────────────────

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-4222-8222-222222222222", "role": "authenticated"}', true);

select is((select count(*)::integer from public.transactions), 0,
  'B tidak melihat satu pun transaksi A');
select is((select count(*)::integer from public.business_profiles), 1,
  'B hanya melihat profil usahanya sendiri');

select is_empty(
  $$ update public.transactions set amount = 1
      where id = 'a0000000-0000-4000-8000-000000000001' returning id $$,
  'ubah transaksi A oleh B tidak mengenai baris apa pun'
);
select is_empty(
  $$ delete from public.transactions
      where id = 'a0000000-0000-4000-8000-000000000001' returning id $$,
  'hapus transaksi A oleh B tidak mengenai baris apa pun'
);

select throws_ok(
  $$ insert into public.transactions (user_id, business_id, date, type, amount, category_id)
     values ('22222222-2222-4222-8222-222222222222',
             'aaaaaaaa-0000-4000-8000-00000000000a', '2026-03-01', 'INCOME', 1, 'ic1') $$,
  '42501', null,
  'B tidak bisa mencatat transaksi ke usaha A'
);
select throws_ok(
  $$ insert into public.transactions (user_id, business_id, date, type, amount, category_id)
     values ('11111111-1111-4111-8111-111111111111',
             'aaaaaaaa-0000-4000-8000-00000000000a', '2026-03-01', 'INCOME', 1, 'ic1') $$,
  '42501', null,
  'B tidak bisa mencatat transaksi dengan menyamar sebagai A'
);
select throws_ok(
  $$ insert into public.business_profiles (user_id, business_name)
     values ('11111111-1111-4111-8111-111111111111', 'Usaha palsu') $$,
  '42501', null,
  'B tidak bisa membuat profil usaha atas nama A'
);

select is(
  (select sum(income + expense + hpp)::bigint from public.monthly_totals(2026)),
  0::bigint,
  'monthly_totals milik B nol — transaksi A tidak ikut terhitung'
);
select is(public.has_password(), false,
  'has_password() B false (tanpa kata sandi)');

-- ── Sebagai A ────────────────────────────────────────────────────────────────

select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select is((select count(*)::integer from public.transactions), 4,
  'A melihat keempat transaksinya, termasuk yang tadi coba diubah/dihapus B');
select is(
  (select amount from public.transactions
    where id = 'a0000000-0000-4000-8000-000000000001'),
  1000000::numeric,
  'nominal transaksi A tidak berubah oleh percobaan B'
);

select is((select count(*)::integer from public.monthly_totals(2026)), 12,
  'monthly_totals selalu 12 baris');
select results_eq(
  $$ select month, income, expense, hpp, tx_count
       from public.monthly_totals(2026) where month <= 3 $$,
  $$ values (1, 1000000::numeric, 400000::numeric, 400000::numeric, 2),
            (2, 0::numeric,       250000::numeric, 0::numeric,      1),
            (3, 0::numeric,       0::numeric,      0::numeric,      0) $$,
  'monthly_totals A per bulan: HPP hanya kategori is_cogs, tahun lain tidak ikut'
);

select throws_ok(
  $$ update public.transactions
        set business_id = 'bbbbbbbb-0000-4000-8000-00000000000b'
      where id = 'a0000000-0000-4000-8000-000000000001' $$,
  '42501', null,
  'A tidak bisa memindahkan transaksinya ke usaha B'
);
select is(public.has_password(), true,
  'has_password() A true (punya kata sandi)');

-- ── Sebagai anon (publishable key tanpa sesi) ───────────────────────────────

select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok(
  'select count(*) from public.transactions',
  '42501', null,
  'anon ditolak membaca transactions'
);
select throws_ok(
  'select * from public.monthly_totals(2026)',
  '42501', null,
  'anon ditolak memanggil monthly_totals'
);

select * from finish();
rollback;
