-- supabase/staging/data_contoh.test.sql
--
-- Skrip data contoh staging (supabase/staging/data_contoh.sql) harus
-- menghasilkan persis angka contoh kontrak di wiki/arsitektur/backend-dan-api.md.
-- Dengan begitu contoh di wiki, data di staging, dan hasil fungsi database
-- tidak bisa menyimpang diam-diam.
--
-- Sengaja di luar supabase/tests/: `supabase test db` hanya me-mount folder berkas
-- tes, jadi tes ini harus bersebelahan dengan skrip yang di-include-nya.
--
-- Jalankan: supabase test db supabase/staging/data_contoh.test.sql

begin;
create extension if not exists pgtap with schema extensions;

\ir data_contoh.sql

select plan(10);

-- Akun fiktif, hanya hidup di transaksi ini. Huruf besar disengaja: email
-- dicocokkan tanpa peduli kapitalisasi.
insert into auth.users (id, email)
values ('33333333-3333-4333-8333-333333333333', 'Rizal@Contoh.test');

-- ── Perilaku skrip ───────────────────────────────────────────────────────────

select is(
  pg_temp.isi_data_contoh('rizal@contoh.test'),
  'Data contoh terisi untuk rizal@contoh.test: 1 profil usaha, 60 transaksi.',
  'mengisi 1 profil usaha dan 60 transaksi'
);
select throws_ok(
  $$ select pg_temp.isi_data_contoh('rizal@contoh.test') $$,
  'P0001', null,
  'menolak menimpa akun yang sudah punya profil usaha tanpa p_timpa'
);
select is(
  pg_temp.isi_data_contoh('rizal@contoh.test', p_timpa => true),
  'Data contoh terisi untuk rizal@contoh.test: 1 profil usaha, 60 transaksi.',
  'p_timpa mengisi ulang tanpa menggandakan transaksi'
);
select throws_ok(
  $$ select pg_temp.isi_data_contoh('belum-daftar@contoh.test') $$,
  'P0001', null,
  'akun yang belum terdaftar ditolak'
);

-- ── Hasil yang dilihat pemilik akun (lewat RLS) = contoh kontrak ─────────────

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "33333333-3333-4333-8333-333333333333", "role": "authenticated"}', true);

select is((select count(*)::integer from public.transactions), 60,
  'pemilik akun melihat 60 transaksi');

select results_eq(
  $$ select business_name, owner_name, npwp, business_type, pkp_status, employee_count
       from public.business_profiles $$,
  $$ values ('Batik Kencana'::text, 'Rizal'::text, '12.345.678.9-012.000'::text,
             'DAGANG'::text, false, 3) $$,
  'profil usaha = contoh GET /business'
);

select results_eq(
  $$ select date, type, amount::numeric, category_id, description, payment_method, receipt_note
       from public.transactions where date = '2026-08-05' $$,
  $$ values ('2026-08-05'::date, 'INCOME'::text, 5200000::numeric, 'ic1'::text,
             'Penjualan produk online'::text, 'QRIS'::text, null::text) $$,
  'transaksi contoh GET /transactions ada apa adanya'
);

select results_eq(
  $$ select income, expense, tx_count from public.monthly_totals(2026) where month = 8 $$,
  $$ values (28500000::numeric, 18200000::numeric, 12) $$,
  'Agustus = contoh GET /dashboard/summary?month=8&year=2026'
);

select is(
  (select sum(income) from public.monthly_totals(2026) where month <= 8),
  285000000::numeric,
  'omzet YTD sampai Agustus = contoh ytd_omzet 285.000.000'
);

select results_eq(
  $$ select month, income from public.monthly_totals(2026) where month <= 2 $$,
  $$ values (1, 19200000::numeric), (2, 21500000::numeric) $$,
  'Januari & Februari = contoh GET /dashboard/kpi-history?metric=income'
);

select * from finish();
rollback;
