-- supabase/staging/data_contoh.sql
--
-- HANYA UNTUK PROYEK STAGING (catatin-staging). Mengisi satu akun dengan data
-- yang angkanya persis contoh kontrak di wiki/arsitektur/backend-dan-api.md,
-- supaya setiap method repository di mode Supabase mengembalikan contohnya:
--
--   GET /business                               → Batik Kencana, non-PKP, 3 karyawan
--   GET /transactions                           → termasuk transaksi contoh 5 Agu 2026
--   GET /dashboard/summary?month=8&year=2026    → 28.500.000 / 18.200.000 / YTD 285.000.000 / 12 transaksi
--   GET /dashboard/kpi-history?metric=income    → Jan 19.200.000, Feb 21.500.000
--   GET /transactions/aggregate?year=2026       → 12 bulan, dari data yang sama
--
-- Tenggat pajak (GET /tax-calendar) tidak diisi di sini: dihitung aplikasi dari
-- status PKP dan jumlah karyawan profil usaha.
--
-- Berkas ini hanya MENDEFINISIKAN fungsi sementara (pg_temp, hilang saat sesi
-- ditutup) — tidak mengubah apa pun sampai fungsinya dipanggil. Jalankan
-- sebagai postgres di SQL Editor dashboard staging, dalam SATU eksekusi:
--
--   <isi berkas ini>
--   select pg_temp.isi_data_contoh('email-akun@contoh.id');
--
-- Akunnya harus sudah terdaftar (dan terkonfirmasi) di staging. Kalau akun itu
-- sudah punya profil usaha, fungsi menolak — panggil dengan
-- `p_timpa => true` untuk menghapus profil beserta seluruh transaksinya lalu
-- mengisi ulang.
--
-- Dijaga tes supabase/staging/data_contoh.test.sql: kalau angka
-- contoh di wiki berubah, ubah berkas ini, tesnya, dan wikinya bersamaan.

create or replace function pg_temp.isi_data_contoh(
  p_email text,
  p_timpa boolean default false
)
returns text
language plpgsql
as $$
declare
  v_user     uuid;
  v_business uuid;
  v_jumlah   integer;
begin
  select u.id into v_user
    from auth.users u
   where lower(u.email) = lower(p_email);
  if v_user is null then
    raise exception 'Akun % belum terdaftar di proyek ini.', p_email;
  end if;

  if exists (select 1 from public.business_profiles b where b.user_id = v_user) then
    if not p_timpa then
      raise exception
        'Akun % sudah punya profil usaha. Panggil dengan p_timpa => true untuk menghapus profil dan seluruh transaksinya.',
        p_email;
    end if;
    -- Transaksi ikut terhapus lewat on delete cascade.
    delete from public.business_profiles b where b.user_id = v_user;
  end if;

  -- Contoh GET /business.
  insert into public.business_profiles
    (user_id, business_name, owner_name, npwp, business_type, pkp_status, employee_count)
  values
    (v_user, 'Batik Kencana', 'Rizal', '12.345.678.9-012.000', 'DAGANG', false, 3)
  returning id into v_business;

  -- Januari–Juli 2026: tiga pemasukan dan tiga pengeluaran per bulan.
  -- Pemasukan Januari dan Februari = contoh GET /dashboard/kpi-history;
  -- Januari–Juli berjumlah 256.500.000, sehingga YTD Agustus = 285.000.000.
  insert into public.transactions
    (user_id, business_id, date, type, amount, category_id, description, payment_method)
  select v_user, v_business, t.tanggal, t.jenis, t.nominal, t.kategori, t.keterangan, t.bayar
    from (values
            (1,  8000000,  6700000,  4500000),
            (2,  9000000,  7500000,  5000000),
            (3, 16000000, 12500000,  9500000),
            (4, 17300000, 14000000, 10000000),
            (5, 18000000, 15000000, 11000000),
            (6, 18500000, 15500000, 11500000),
            (7, 19000000, 16000000, 12000000)
         ) as bulan(m, toko, pesanan, marketplace)
    cross join lateral (
      select (array['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli'])[bulan.m] as nama
    ) as n
    cross join lateral (values
      (make_date(2026, bulan.m,  4), 'INCOME',  bulan.toko::numeric,        'ic1', 'Penjualan toko ' || n.nama,        'CASH'),
      (make_date(2026, bulan.m, 12), 'INCOME',  bulan.pesanan::numeric,     'ic2', 'Pesanan seragam ' || n.nama,       'TRANSFER'),
      (make_date(2026, bulan.m, 20), 'INCOME',  bulan.marketplace::numeric, 'ic1', 'Penjualan marketplace ' || n.nama, 'QRIS'),
      (make_date(2026, bulan.m,  3), 'EXPENSE', round((bulan.toko + bulan.pesanan + bulan.marketplace) * 0.3, -5),
                                                                             'ec1', 'Bahan baku kain ' || n.nama,       'TRANSFER'),
      (make_date(2026, bulan.m, 25), 'EXPENSE', 9000000::numeric,           'ec3', 'Gaji 3 karyawan ' || n.nama,       'TRANSFER'),
      (make_date(2026, bulan.m,  1), 'EXPENSE', 1500000::numeric,           'ec4', 'Sewa kios ' || n.nama,             'TRANSFER')
    ) as t(tanggal, jenis, nominal, kategori, keterangan, bayar);

  -- Agustus 2026: 12 transaksi, pemasukan 28.500.000, pengeluaran 18.200.000
  -- (contoh GET /dashboard/summary?month=8&year=2026). Baris pertama adalah
  -- contoh item GET /transactions.
  insert into public.transactions
    (user_id, business_id, date, type, amount, category_id, description, payment_method)
  select v_user, v_business, t.tanggal::date, t.jenis, t.nominal, t.kategori, t.keterangan, t.bayar
    from (values
      ('2026-08-05', 'INCOME',  5200000, 'ic1', 'Penjualan produk online',  'QRIS'),
      ('2026-08-02', 'INCOME',  3200000, 'ic1', 'Penjualan batik tulis',    'CASH'),
      ('2026-08-09', 'INCOME',  8500000, 'ic2', 'Order custom seragam',     'TRANSFER'),
      ('2026-08-16', 'INCOME',  4100000, 'ic1', 'Penjualan marketplace',    'TRANSFER'),
      ('2026-08-23', 'INCOME',  5000000, 'ic2', 'Jasa desain motif',        'TRANSFER'),
      ('2026-08-28', 'INCOME',  2500000, 'ic3', 'Komisi reseller',          'TRANSFER'),
      ('2026-08-03', 'EXPENSE', 2800000, 'ec1', 'Restock bahan baku kain',  'TRANSFER'),
      ('2026-08-10', 'EXPENSE', 3400000, 'ec2', 'Barang dagangan batik cap','TRANSFER'),
      ('2026-08-25', 'EXPENSE', 9000000, 'ec3', 'Gaji 3 karyawan Agustus',  'TRANSFER'),
      ('2026-08-01', 'EXPENSE', 1500000, 'ec4', 'Sewa kios Agustus',        'TRANSFER'),
      ('2026-08-07', 'EXPENSE',  620000, 'ec5', 'PLN Agustus',              'TRANSFER'),
      ('2026-08-12', 'EXPENSE',  880000, 'ec6', 'Internet & pulsa Agustus', 'TRANSFER')
    ) as t(tanggal, jenis, nominal, kategori, keterangan, bayar);

  -- Awal September 2026, supaya dashboard bulan berjalan tidak kosong.
  insert into public.transactions
    (user_id, business_id, date, type, amount, category_id, description, payment_method)
  select v_user, v_business, t.tanggal::date, t.jenis, t.nominal, t.kategori, t.keterangan, t.bayar
    from (values
      ('2026-09-01', 'EXPENSE', 1500000, 'ec4', 'Sewa kios September',       'TRANSFER'),
      ('2026-09-02', 'INCOME',  4800000, 'ic1', 'Penjualan produk online',   'QRIS'),
      ('2026-09-04', 'EXPENSE', 2600000, 'ec1', 'Restock bahan baku kain',   'TRANSFER'),
      ('2026-09-08', 'INCOME',  7500000, 'ic2', 'Order custom seragam',      'TRANSFER'),
      ('2026-09-11', 'INCOME',  3100000, 'ic1', 'Penjualan batik tulis',     'CASH'),
      ('2026-09-14', 'EXPENSE',  650000, 'ec5', 'PLN September',             'TRANSFER')
    ) as t(tanggal, jenis, nominal, kategori, keterangan, bayar);

  select count(*) into v_jumlah from public.transactions t where t.user_id = v_user;
  return format('Data contoh terisi untuk %s: 1 profil usaha, %s transaksi.', p_email, v_jumlah);
end;
$$;
