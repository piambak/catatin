-- supabase/staging/uji_beban_agregasi.sql
--
-- Uji beban ringan agregasi (#75): 12 bulan × 200 transaksi per akun, untuk
-- banyak akun sekaligus, lalu mengukur — sebagai `authenticated`, jalur yang
-- sama dengan klien, jadi RLS ikut berlaku — tiga kueri yang benar-benar
-- dikirim aplikasi:
--
--   1. rpc monthly_totals(tahun)       dashboard, grafik KPI, agregat, tutup bulan
--   2. transaksi satu bulan + kategori tab Pembukuan
--   3. setahun per halaman 1000 baris  jalur yang sama dengan ekspor CSV (#72)
--
-- Semuanya di dalam satu transaksi yang diakhiri `raise exception` berisi
-- laporan, jadi TIDAK ADA yang tertinggal di database. Jalankan di staging
-- (MCP execute_sql atau psql), jangan di produksi.
--
-- Jumlah akun diatur di baris set_config('uji.akun', ...) di bawah.
-- Hasil dan cara membacanya: wiki/arsitektur/supabase.md §10.

begin;

select set_config('uji.akun', '50', true);
select setseed(0.75);

-- Merangkum sampel waktu (ms) jadi satu baris laporan.
create function pg_temp.ringkas(p_label text, p_ms double precision[])
returns text language sql as $f$
  select format('%s: n=%s min=%s p50=%s p95=%s maks=%s ms',
    p_label, count(*),
    round(min(x)::numeric, 1),
    round((percentile_cont(0.5) within group (order by x))::numeric, 1),
    round((percentile_cont(0.95) within group (order by x))::numeric, 1),
    round(max(x)::numeric, 1))
  from unnest(p_ms) as x
$f$;

-- ── Data (sebagai postgres, melewati RLS) ────────────────────────────────────

select set_config('uji.t0', clock_timestamp()::text, true);

insert into auth.users (id, email)
select ('00000000-0000-4000-8000-' || lpad(to_hex(u), 12, '0'))::uuid,
       'beban' || u || '@contoh.test'
  from generate_series(1, current_setting('uji.akun')::int) as u;

insert into public.business_profiles (id, user_id, business_name)
select ('10000000-0000-4000-8000-' || lpad(to_hex(u), 12, '0'))::uuid,
       ('00000000-0000-4000-8000-' || lpad(to_hex(u), 12, '0'))::uuid,
       'Usaha beban ' || u
  from generate_series(1, current_setting('uji.akun')::int) as u;

-- 200 transaksi per bulan per akun: 2/3 pemasukan, 1/3 pengeluaran, dan
-- sepertiga pengeluaran itu kategori HPP.
insert into public.transactions
  (user_id, business_id, date, type, amount, category_id, description)
select ('00000000-0000-4000-8000-' || lpad(to_hex(u), 12, '0'))::uuid,
       ('10000000-0000-4000-8000-' || lpad(to_hex(u), 12, '0'))::uuid,
       make_date(2026, m, 1 + i % 28),
       case when i % 3 = 0 then 'EXPENSE' else 'INCOME' end,
       10000 + floor(random() * 5000000),
       case
         when i % 3 <> 0 then (array['ic1', 'ic2', 'ic3', 'ic4'])[1 + i % 4]
         when i % 9 = 0  then (array['ec1', 'ec2'])[1 + i % 2]
         else (array['ec3', 'ec4', 'ec5', 'ec6', 'ec7', 'ec8', 'ec9', 'ec0', 'ecx'])[1 + (i / 3) % 9]
       end,
       'Transaksi uji ' || i
  from generate_series(1, current_setting('uji.akun')::int) as u,
       generate_series(1, 12) as m,
       generate_series(1, 200) as i;

analyze public.transactions;

select set_config('uji.hasil', format(
  E'\ndata: %s akun, %s transaksi (%s), diisi dalam %s dtk',
  current_setting('uji.akun'),
  (select count(*) from public.transactions),
  pg_size_pretty(pg_total_relation_size('public.transactions')),
  round(extract(epoch from clock_timestamp() - current_setting('uji.t0')::timestamptz)::numeric, 1)
), true);

-- ── Pengukuran (sebagai akun pertama, lewat RLS) ─────────────────────────────

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-4000-8000-000000000001", "role": "authenticated"}', true);

do $$
declare
  hasil  text := current_setting('uji.hasil');
  t0     timestamptz;
  ms     double precision[];
  baris  bigint;
  total  bigint;
  bagian text;
begin
  -- Isolasi dulu: akun ini hanya boleh melihat 2.400 transaksinya sendiri.
  select count(*) into baris from public.transactions;
  select sum(tx_count) into total from public.monthly_totals(2026);
  hasil := hasil || format(E'\nterlihat oleh akun 1: %s baris, monthly_totals menjumlah %s', baris, total);

  -- Pemanasan cache, tidak dihitung.
  perform * from public.monthly_totals(2026);

  -- 1. monthly_totals
  ms := '{}';
  for k in 1..30 loop
    t0 := clock_timestamp();
    perform * from public.monthly_totals(2026);
    ms := ms || extract(epoch from clock_timestamp() - t0) * 1000;
  end loop;
  hasil := hasil || E'\n' || pg_temp.ringkas('1. monthly_totals(2026)', ms);

  -- 2. satu bulan + kategori, urutan sama dengan getTransactions
  ms := '{}';
  for k in 1..30 loop
    t0 := clock_timestamp();
    perform t.*, to_jsonb(c)
       from public.transactions t
       join public.tx_categories c on c.id = t.category_id
      where t.date >= '2026-08-01' and t.date < '2026-09-01'
      order by t.date desc, t.created_at desc
      limit 1000;
    ms := ms || extract(epoch from clock_timestamp() - t0) * 1000;
  end loop;
  hasil := hasil || E'\n' || pg_temp.ringkas('2. satu bulan (200 baris)', ms);

  -- 3. setahun, tiga halaman × 1000 baris seperti _pageSize di klien
  ms := '{}';
  for k in 1..10 loop
    t0 := clock_timestamp();
    for halaman in 0..2 loop
      perform t.*, to_jsonb(c)
         from public.transactions t
         join public.tx_categories c on c.id = t.category_id
        where t.date >= '2026-01-01' and t.date < '2027-01-01'
        order by t.date desc, t.created_at desc
        limit 1000 offset halaman * 1000;
    end loop;
    ms := ms || extract(epoch from clock_timestamp() - t0) * 1000;
  end loop;
  hasil := hasil || E'\n' || pg_temp.ringkas('3. setahun, 3 halaman (2.400 baris)', ms);

  -- Rencana kueri inti monthly_totals: harus memakai indeks (user_id, date).
  hasil := hasil || E'\nrencana monthly_totals:';
  for bagian in
    execute $q$
      explain (analyze, costs off, timing off)
      select extract(month from t.date)::integer, sum(t.amount), count(*)
        from public.transactions t
        join public.tx_categories c on c.id = t.category_id
       where t.user_id = (select auth.uid())
         and t.date >= make_date(2026, 1, 1)
         and t.date <  make_date(2027, 1, 1)
       group by 1
    $q$
  loop
    if bagian ~ '(Scan|Execution Time|Filter)' then
      hasil := hasil || E'\n  ' || trim(bagian);
    end if;
  end loop;

  perform set_config('uji.hasil', hasil, true);
end;
$$;

do $$ begin raise exception 'HASIL %', current_setting('uji.hasil'); end $$;
