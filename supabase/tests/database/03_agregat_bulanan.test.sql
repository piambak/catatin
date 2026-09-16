-- supabase/tests/database/03_agregat_bulanan.test.sql
--
-- `monthly_totals` diisi penuh 12 bulan (issue #41 — bahan Simulator Minggu 5
-- dan kontrak GET /transactions/aggregate, wiki/arsitektur/backend-dan-api.md
-- §"GET /transactions/aggregate?year=2026"). 02_rls_isolasi.test.sql hanya
-- mengisi Januari–Februari; tes ini mengisi seluruh tahun untuk satu
-- pengguna, termasuk satu bulan kosong dan beberapa kategori HPP (is_cogs),
-- supaya "12 baris, bulan kosong nol" benar-benar teruji, bukan cuma
-- terasumsi dari generate_series di migrasi.
--
-- Jalankan: supabase test db

begin;
create extension if not exists pgtap with schema extensions;

select plan(3);

-- ── Data awal (sebagai postgres, melewati RLS) ──────────────────────────────

insert into auth.users (id, email) values
  ('44444444-4444-4444-8444-444444444444', 'c@contoh.test');

insert into public.business_profiles (id, user_id, business_name) values
  ('dddddddd-0000-4000-8000-00000000000d', '44444444-4444-4444-8444-444444444444', 'Usaha C');

-- Dua belas bulan 2026 untuk pengguna C. Juni sengaja dibiarkan kosong.
-- ec1/ec2 (Bahan Baku/Barang Dagangan) adalah kategori is_cogs dari migrasi;
-- ec5/ec6/ec7/ec8 bukan HPP — supaya kolom hpp bukan cuma total expense.
insert into public.transactions
  (id, user_id, business_id, date, type, amount, category_id)
values
  -- Januari: income + HPP
  ('d0000000-0000-4000-8000-000000000001', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-01-10', 'INCOME',  1000000, 'ic1'),
  ('d0000000-0000-4000-8000-000000000002', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-01-20', 'EXPENSE',  400000, 'ec1'),
  -- Februari: income + expense bukan HPP
  ('d0000000-0000-4000-8000-000000000003', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-02-05', 'INCOME',  2000000, 'ic2'),
  ('d0000000-0000-4000-8000-000000000004', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-02-15', 'EXPENSE',  500000, 'ec5'),
  -- Maret: income + HPP + expense bukan HPP (tiga transaksi)
  ('d0000000-0000-4000-8000-000000000005', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-03-08', 'INCOME',  3000000, 'ic1'),
  ('d0000000-0000-4000-8000-000000000006', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-03-12', 'EXPENSE',  600000, 'ec1'),
  ('d0000000-0000-4000-8000-000000000007', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-03-18', 'EXPENSE',  100000, 'ec5'),
  -- April: income + HPP (kategori HPP kedua, ec2)
  ('d0000000-0000-4000-8000-000000000008', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-04-02', 'INCOME',  4000000, 'ic3'),
  ('d0000000-0000-4000-8000-000000000009', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-04-22', 'EXPENSE',  800000, 'ec2'),
  -- Mei: income + expense bukan HPP
  ('d0000000-0000-4000-8000-00000000000a', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-05-11', 'INCOME',  5000000, 'ic4'),
  ('d0000000-0000-4000-8000-00000000000b', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-05-25', 'EXPENSE',  900000, 'ec6'),
  -- Juni: sengaja tidak ada transaksi — bulan kosong.
  -- Juli: income + HPP
  ('d0000000-0000-4000-8000-00000000000c', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-07-07', 'INCOME',  7000000, 'ic1'),
  ('d0000000-0000-4000-8000-00000000000d', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-07-19', 'EXPENSE', 1000000, 'ec1'),
  -- Agustus: income + expense bukan HPP
  ('d0000000-0000-4000-8000-00000000000e', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-08-04', 'INCOME',  8000000, 'ic2'),
  ('d0000000-0000-4000-8000-00000000000f', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-08-14', 'EXPENSE', 1100000, 'ec5'),
  -- September: income + HPP + expense bukan HPP (tiga transaksi)
  ('d0000000-0000-4000-8000-000000000010', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-09-03', 'INCOME',  9000000, 'ic3'),
  ('d0000000-0000-4000-8000-000000000011', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-09-16', 'EXPENSE', 1200000, 'ec2'),
  ('d0000000-0000-4000-8000-000000000012', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-09-27', 'EXPENSE',  300000, 'ec7'),
  -- Oktober: income + HPP
  ('d0000000-0000-4000-8000-000000000013', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-10-09', 'INCOME', 10000000, 'ic4'),
  ('d0000000-0000-4000-8000-000000000014', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-10-21', 'EXPENSE', 1300000, 'ec1'),
  -- November: income + expense bukan HPP
  ('d0000000-0000-4000-8000-000000000015', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-11-06', 'INCOME', 11000000, 'ic1'),
  ('d0000000-0000-4000-8000-000000000016', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-11-17', 'EXPENSE', 1400000, 'ec8'),
  -- Desember: income + HPP
  ('d0000000-0000-4000-8000-000000000017', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-12-05', 'INCOME', 12000000, 'ic2'),
  ('d0000000-0000-4000-8000-000000000018', '44444444-4444-4444-8444-444444444444',
   'dddddddd-0000-4000-8000-00000000000d', '2026-12-23', 'EXPENSE', 1500000, 'ec2');

-- ── Sebagai C ────────────────────────────────────────────────────────────────

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "44444444-4444-4444-8444-444444444444", "role": "authenticated"}', true);

select is((select count(*)::integer from public.monthly_totals(2026)), 12,
  'monthly_totals mengembalikan 12 baris walau tahun ini punya bulan kosong');

select results_eq(
  $$ select month, income, expense, hpp, tx_count
       from public.monthly_totals(2026) order by month $$,
  $$ values
      ( 1,  1000000::numeric,  400000::numeric,  400000::numeric, 2),
      ( 2,  2000000::numeric,  500000::numeric,       0::numeric, 2),
      ( 3,  3000000::numeric,  700000::numeric,  600000::numeric, 3),
      ( 4,  4000000::numeric,  800000::numeric,  800000::numeric, 2),
      ( 5,  5000000::numeric,  900000::numeric,       0::numeric, 2),
      ( 6,        0::numeric,       0::numeric,       0::numeric, 0),
      ( 7,  7000000::numeric, 1000000::numeric, 1000000::numeric, 2),
      ( 8,  8000000::numeric, 1100000::numeric,       0::numeric, 2),
      ( 9,  9000000::numeric, 1500000::numeric, 1200000::numeric, 3),
      (10, 10000000::numeric, 1300000::numeric, 1300000::numeric, 2),
      (11, 11000000::numeric, 1400000::numeric,       0::numeric, 2),
      (12, 12000000::numeric, 1500000::numeric, 1500000::numeric, 2) $$,
  'monthly_totals per bulan genap 12 baris: Juni nol, HPP hanya kategori is_cogs'
);

-- Total income setahun sama dengan ytd_omzet Desember yang dihitung klien
-- (monthAggregates() di app/lib/models/dashboard_model.dart) — angka inilah
-- yang dipakai Simulator dan kontrak GET /transactions/aggregate.
select is(
  (select sum(income)::bigint from public.monthly_totals(2026)),
  72000000::bigint,
  'jumlah income 12 bulan sama dengan omzet berjalan (ytd_omzet) Desember'
);

select * from finish();
rollback;
