-- supabase/migrations/20260922121953_pemantauan.sql
--
-- Pemantauan (#103). Paket Free Supabase tidak punya peringatan bawaan, jadi
-- database menyiapkan angka kesehatannya sendiri dan workflow
-- .github/workflows/pemantauan.yml memeriksanya tiap 30 menit:
--
--   1. app_errors — galat terstruktur yang dilaporkan klien: status, kode
--      mesin, sumber, versi aplikasi, platform. SENGAJA tanpa pesan bebas,
--      jadi tidak ada data pribadi yang ikut. Klien hanya melaporkan galat
--      yang menandakan masalah di sisi kita (403 padahal sesi ada, 5xx, dan
--      galat yang tidak dikenali) — lihat reportableAppError() di
--      app/lib/core/network/supabase_client.dart.
--   2. latency_snapshots — cuplikan pg_stat_statements tiap 15 menit untuk
--      monthly_totals yang dipanggil klien (peran authenticated). Selisih dua
--      cuplikan = rata-rata latensi agregasi dalam jendela itu; angka kumulatif
--      pg_stat_statements sendiri tidak bisa menunjukkan "satu jam terakhir".
--   3. catatin_health() — ringkasan jendela terakhir: galat, latensi, dan job
--      pg_cron transaksi berulang. Satu-satunya fungsi yang boleh dipanggil
--      `anon`, supaya workflow cukup memakai publishable key yang memang
--      publik — tanpa secret baru yang juga membuka produksi. Isinya hanya
--      hitungan agregat, tidak ada baris milik siapa pun.
--
-- Wiki: arsitektur/supabase.md §11 Pemantauan.

-- ── 1. Galat klien ───────────────────────────────────────────────────────────

create table public.app_errors (
  id          bigint generated always as identity primary key,
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  occurred_at timestamptz not null default now(),
  status      integer not null check (status between 0 and 599),
  code        text check (char_length(code) <= 64),
  source      text not null
              check (source in ('postgrest', 'auth', 'storage', 'lain')),
  app_version text not null check (char_length(app_version) between 1 and 32),
  platform    text not null check (platform in ('web', 'android', 'ios', 'lain'))
);

comment on table public.app_errors is
  'Galat terstruktur dari klien untuk pemantauan (#103). Tanpa pesan bebas. Dibersihkan setelah 30 hari oleh catatin_pemantauan_berkala().';

create index app_errors_occurred_at_idx on public.app_errors (occurred_at);
create index app_errors_user_occurred_idx on public.app_errors (user_id, occurred_at);

alter table public.app_errors enable row level security;

revoke all on table public.app_errors from anon, authenticated;

-- Hak INSERT per kolom: user_id dan occurred_at tidak termasuk, jadi selalu
-- diisi default (auth.uid(), now()) — klien tidak bisa melapor atas nama
-- orang lain atau memundurkan waktu. Tidak ada SELECT: pengguna tidak pernah
-- membaca tabel ini.
grant insert (status, code, source, app_version, platform)
  on table public.app_errors to authenticated;

create policy "Pengguna melaporkan galatnya sendiri"
  on public.app_errors for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- Paling banyak 30 laporan per akun per 10 menit; sisanya dibuang diam-diam,
-- supaya klien yang terjebak dalam loop galat tidak memenuhi tabel. SECURITY
-- DEFINER karena authenticated tidak punya hak SELECT untuk menghitung.
create or replace function public.app_errors_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select count(*)
        from public.app_errors e
       where e.user_id = new.user_id
         and e.occurred_at > now() - interval '10 minutes') >= 30 then
    return null;
  end if;
  return new;
end;
$$;

create trigger app_errors_before_insert
  before insert on public.app_errors
  for each row execute function public.app_errors_before_insert();

-- ── 2. Cuplikan latensi agregasi ─────────────────────────────────────────────

create table public.latency_snapshots (
  taken_at      timestamptz primary key default now(),
  calls         bigint not null check (calls >= 0),
  total_exec_ms double precision not null check (total_exec_ms >= 0)
);

comment on table public.latency_snapshots is
  'Cuplikan kumulatif pg_stat_statements untuk monthly_totals (peran authenticated), tiap 15 menit. Disimpan 7 hari.';

alter table public.latency_snapshots enable row level security;
revoke all on table public.latency_snapshots from anon, authenticated;
-- Tanpa kebijakan dan tanpa hak: hanya fungsi SECURITY DEFINER di bawah.

-- Dijalankan pg_cron tiap 15 menit: ambil cuplikan, lalu buang data lama.
-- pg_stat_statements dibaca lewat SQL dinamis karena ekstensinya bisa saja
-- tidak ada (mis. stack lokal tanpa shared_preload_libraries) — migrasi dan
-- lint tetap jalan, cuplikannya saja yang dilewati.
--
-- Hanya pernyataan peran authenticated (= permintaan PostgREST dari klien);
-- blok DO dikecualikan supaya uji manual seperti
-- supabase/staging/uji_beban_agregasi.sql tidak terhitung sebagai latensi.
create or replace function public.catatin_pemantauan_berkala()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if to_regclass('extensions.pg_stat_statements') is not null then
    execute $q$
      insert into public.latency_snapshots (calls, total_exec_ms)
      select coalesce(sum(s.calls), 0), coalesce(sum(s.total_exec_time), 0)
        from extensions.pg_stat_statements s
       where s.userid = to_regrole('authenticated')::oid
         and s.query ilike '%monthly_totals%'
         and s.query !~* '^\s*do\s'
      on conflict (taken_at) do nothing
    $q$;
  end if;

  delete from public.latency_snapshots where taken_at < now() - interval '7 days';
  delete from public.app_errors where occurred_at < now() - interval '30 days';
end;
$$;

comment on function public.catatin_pemantauan_berkala() is
  'Cuplikan latensi monthly_totals + pembersihan data pemantauan. Dijalankan pg_cron catatin-pemantauan tiap 15 menit.';

-- ── 3. Ringkasan kesehatan ───────────────────────────────────────────────────

create or replace function public.catatin_health(p_window_minutes integer default 60)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_minutes    integer := least(greatest(coalesce(p_window_minutes, 60), 15), 1440);
  v_since      timestamptz := now() - make_interval(mins => v_minutes);
  v_errors     jsonb;
  v_snapshots  integer;
  v_first_calls bigint;
  v_first_ms   double precision;
  v_last_calls bigint;
  v_last_ms    double precision;
  v_cron       jsonb := jsonb_build_object(
                  'last_run_at', null, 'last_status', null,
                  'last_success_at', null, 'hours_since_success', null);
begin
  select jsonb_build_object(
           'total',     count(*),
           'server',    count(*) filter (where e.status >= 500),
           'forbidden', count(*) filter (where e.status = 403),
           'users',     count(distinct e.user_id))
    into v_errors
    from public.app_errors e
   where e.occurred_at >= v_since;

  select count(*) into v_snapshots
    from public.latency_snapshots s
   where s.taken_at >= v_since;

  select s.calls, s.total_exec_ms into v_first_calls, v_first_ms
    from public.latency_snapshots s
   where s.taken_at >= v_since
   order by s.taken_at
   limit 1;

  select s.calls, s.total_exec_ms into v_last_calls, v_last_ms
    from public.latency_snapshots s
   where s.taken_at >= v_since
   order by s.taken_at desc
   limit 1;

  if to_regclass('cron.job_run_details') is not null then
    execute $q$
      select jsonb_build_object(
               'last_run_at',     max(d.start_time),
               'last_status',     (array_agg(d.status order by d.start_time desc))[1],
               'last_success_at', max(d.start_time) filter (where d.status = 'succeeded'),
               'hours_since_success', round((extract(epoch from
                  now() - max(d.start_time) filter (where d.status = 'succeeded')) / 3600)::numeric, 1))
        from cron.job_run_details d
        join cron.job j on j.jobid = d.jobid
       where j.jobname = 'catatin-transaksi-berulang'
    $q$ into v_cron;
  end if;

  return jsonb_build_object(
    'checked_at',     now(),
    'window_minutes', v_minutes,
    'errors',         v_errors,
    'aggregation',    jsonb_build_object(
      'snapshots', v_snapshots,
      -- Hitungan yang turun berarti pg_stat_statements direset: selisihnya
      -- tidak bermakna, jadi null — bukan angka negatif.
      'calls',     case when v_last_calls >= v_first_calls
                        then v_last_calls - v_first_calls end,
      'mean_ms',   case when v_last_calls > v_first_calls
                        then round(((v_last_ms - v_first_ms)
                                    / (v_last_calls - v_first_calls))::numeric, 2) end),
    'recurring_cron', v_cron
  );
end;
$$;

comment on function public.catatin_health(integer) is
  'Ringkasan kesehatan untuk workflow pemantauan: galat klien, latensi monthly_totals, job pg_cron transaksi berulang. Jendela 15-1440 menit. Boleh dipanggil anon — hanya angka agregat.';

-- ── Hak fungsi ───────────────────────────────────────────────────────────────

revoke execute on function public.app_errors_before_insert()
  from public, anon, authenticated;
revoke execute on function public.catatin_pemantauan_berkala()
  from public, anon, authenticated;
revoke execute on function public.catatin_health(integer) from public;
grant execute on function public.catatin_health(integer) to anon, authenticated;

-- ── Penjadwal ────────────────────────────────────────────────────────────────

select cron.schedule(
  'catatin-pemantauan',
  '*/15 * * * *',
  $$select public.catatin_pemantauan_berkala()$$
);
