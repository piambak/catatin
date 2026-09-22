-- supabase/tests/database/08_pemantauan.test.sql
--
-- Pemantauan (#103): tabel app_errors yang hanya bisa ditambah (per kolom,
-- tanpa baca, dengan batas laju), cuplikan latensi, catatin_health() yang
-- boleh dipanggil anon, dan pembersihan berkala.
--
-- now() tetap sepanjang transaksi tes, jadi semua baris yang ditulis klien
-- punya occurred_at yang sama; baris "lama" ditulis sebagai postgres dengan
-- occurred_at/taken_at eksplisit.
--
-- Jalankan: supabase test db

begin;
create extension if not exists pgtap with schema extensions;

select plan(34);

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@contoh.test'),
  ('22222222-2222-4222-8222-222222222222', 'b@contoh.test');

-- ── Skema dan hak ────────────────────────────────────────────────────────────

select has_table('public', 'app_errors', 'tabel app_errors ada');
select has_table('public', 'latency_snapshots', 'tabel latency_snapshots ada');
select ok(
  (select relrowsecurity from pg_class where oid = 'public.app_errors'::regclass),
  'RLS menyala di app_errors'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.latency_snapshots'::regclass),
  'RLS menyala di latency_snapshots'
);
select policies_are(
  'public', 'app_errors',
  array['Pengguna melaporkan galatnya sendiri'],
  'kebijakan app_errors persis sesuai migrasi'
);
select table_privs_are('public', 'app_errors', 'anon', array[]::text[],
  'anon tanpa hak di app_errors');
select table_privs_are('public', 'app_errors', 'authenticated', array[]::text[],
  'authenticated tanpa hak tingkat tabel di app_errors (hanya INSERT per kolom)');
select table_privs_are('public', 'latency_snapshots', 'anon', array[]::text[],
  'anon tanpa hak di latency_snapshots');
select table_privs_are('public', 'latency_snapshots', 'authenticated', array[]::text[],
  'authenticated tanpa hak di latency_snapshots');
select is_definer('public', 'catatin_health', array['integer'],
  'catatin_health security definer (membaca tabel pemantauan dan cron)');
select function_privs_are('public', 'catatin_health', array['integer'], 'anon',
  array['EXECUTE'], 'anon BOLEH memanggil catatin_health — satu-satunya pengecualian');
select function_privs_are('public', 'catatin_pemantauan_berkala', array[]::text[],
  'authenticated', array[]::text[], 'authenticated tidak bisa memanggil catatin_pemantauan_berkala');
select function_privs_are('public', 'app_errors_before_insert', array[]::text[],
  'authenticated', array[]::text[], 'authenticated tidak bisa memanggil app_errors_before_insert');
select is(
  (select schedule from cron.job where jobname = 'catatin-pemantauan'),
  '*/15 * * * *',
  'job pg_cron catatin-pemantauan berjalan tiap 15 menit'
);

-- ── Sebagai A ────────────────────────────────────────────────────────────────

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into public.app_errors (status, code, source, app_version, platform)
     values (500, 'XX000', 'postgrest', '1.0.0', 'web') $$,
  'A melaporkan galat dengan kolom yang diizinkan'
);
select throws_ok(
  $$ insert into public.app_errors (user_id, status, source, app_version, platform)
     values ('22222222-2222-4222-8222-222222222222', 500, 'postgrest', '1.0.0', 'web') $$,
  '42501', null,
  'A tidak bisa melapor atas nama B (tidak ada hak kolom user_id)'
);
select throws_ok(
  $$ insert into public.app_errors (occurred_at, status, source, app_version, platform)
     values (now() - interval '1 day', 500, 'postgrest', '1.0.0', 'web') $$,
  '42501', null,
  'A tidak bisa memundurkan waktu (tidak ada hak kolom occurred_at)'
);
select throws_ok(
  $$ select count(*) from public.app_errors $$,
  '42501', null,
  'A tidak bisa membaca app_errors'
);
select throws_ok(
  $$ insert into public.app_errors (status, source, app_version, platform)
     values (600, 'postgrest', '1.0.0', 'web') $$,
  '23514',
  'new row for relation "app_errors" violates check constraint "app_errors_status_check"',
  'status di luar 0–599 ditolak'
);
select throws_ok(
  $$ insert into public.app_errors (status, source, app_version, platform)
     values (500, 'sembarang', '1.0.0', 'web') $$,
  '23514',
  'new row for relation "app_errors" violates check constraint "app_errors_source_check"',
  'sumber di luar daftar ditolak'
);

-- Batas laju: 1 baris di atas + 40 percobaan → hanya 30 yang tersimpan.
do $$
begin
  for i in 1..40 loop
    insert into public.app_errors (status, code, source, app_version, platform)
    values (403, '42501', 'postgrest', '1.0.0', 'web');
  end loop;
end;
$$;

-- ── Sebagai anon ─────────────────────────────────────────────────────────────

set local role anon;
select set_config('request.jwt.claims', '{"role": "anon"}', true);

select throws_ok(
  $$ insert into public.app_errors (status, source, app_version, platform)
     values (500, 'postgrest', '1.0.0', 'web') $$,
  '42501', null,
  'anon tidak bisa melaporkan galat'
);
select lives_ok(
  $$ select public.catatin_health() $$,
  'anon bisa memanggil catatin_health'
);

reset role;

select is(
  (select count(*)::integer from public.app_errors
    where user_id = '11111111-1111-4111-8111-111111111111'),
  30,
  'batas laju: paling banyak 30 laporan per akun per 10 menit'
);

-- ── catatin_health (sebagai postgres, data terkendali) ───────────────────────

insert into public.app_errors (user_id, occurred_at, status, source, app_version, platform)
values ('22222222-2222-4222-8222-222222222222', now() - interval '2 hours',
        503, 'postgrest', '1.0.0', 'android');

select is(
  public.catatin_health(60) -> 'errors',
  '{"total": 30, "server": 1, "forbidden": 29, "users": 1}'::jsonb,
  'galat 60 menit terakhir: total, 5xx, 403, dan akun terdampak'
);
select is(
  (public.catatin_health(180) -> 'errors' ->> 'users')::integer,
  2,
  'jendela 180 menit ikut menghitung galat 2 jam lalu'
);

insert into public.latency_snapshots (taken_at, calls, total_exec_ms) values
  (now() - interval '50 minutes', 100, 1000),
  (now() - interval '5 minutes',  150, 1600);

select is(
  public.catatin_health(60) -> 'aggregation',
  '{"snapshots": 2, "calls": 50, "mean_ms": 12}'::jsonb,
  'latensi = selisih dua cuplikan: 600 ms / 50 panggilan = 12 ms'
);

-- pg_stat_statements direset: hitungan turun → selisih tidak bermakna.
insert into public.latency_snapshots (taken_at, calls, total_exec_ms)
values (now() - interval '1 minute', 10, 50);

select is(
  public.catatin_health(60) -> 'aggregation' -> 'mean_ms',
  'null'::jsonb,
  'hitungan yang turun (reset) menghasilkan null, bukan angka negatif'
);

select is((public.catatin_health(5) ->> 'window_minutes')::integer, 15,
  'jendela paling kecil 15 menit');
select is((public.catatin_health(99999) ->> 'window_minutes')::integer, 1440,
  'jendela paling besar 1440 menit');
select ok(
  public.catatin_health() -> 'recurring_cron' ?& array['last_status', 'hours_since_success'],
  'status job transaksi berulang selalu punya last_status dan hours_since_success'
);

-- ── Pembersihan berkala ──────────────────────────────────────────────────────

insert into public.latency_snapshots (taken_at, calls, total_exec_ms)
values (now() - interval '8 days', 1, 1);
insert into public.app_errors (user_id, occurred_at, status, source, app_version, platform)
values ('22222222-2222-4222-8222-222222222222', now() - interval '31 days',
        500, 'postgrest', '1.0.0', 'web');

select lives_ok(
  $$ select public.catatin_pemantauan_berkala() $$,
  'catatin_pemantauan_berkala berjalan (dengan atau tanpa pg_stat_statements)'
);
select is(
  (select count(*)::integer from public.latency_snapshots
    where taken_at < now() - interval '7 days'),
  0,
  'cuplikan lebih dari 7 hari dibuang'
);
select is(
  (select count(*)::integer from public.app_errors
    where occurred_at < now() - interval '30 days'),
  0,
  'galat lebih dari 30 hari dibuang'
);
select is(
  (select count(*)::integer from public.app_errors
    where occurred_at = now() - interval '2 hours'),
  1,
  'galat yang belum 30 hari tetap disimpan'
);

select * from finish();
rollback;
