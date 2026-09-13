-- supabase/migrations/20260913154535_catatin_skema_awal.sql
--
-- Skema awal Catatin di Supabase: kategori transaksi, profil usaha, transaksi,
-- dan satu fungsi agregasi bulanan.
--
-- Nama kolom sengaja sama dengan kunci JSON di app/lib/models/, jadi baris dari
-- PostgREST langsung dibaca `fromJson` tanpa pemetaan tambahan.
--
-- Keamanan ada di sini, bukan di aplikasi: setiap tabel dijaga Row Level
-- Security, dan publishable key yang ikut ter-compile ke situs publik hanya
-- membuka apa yang diizinkan kebijakan di bawah.
--
-- Penjelasan lengkap: wiki/arsitektur/backend-dan-api.md

-- ── Kategori transaksi ──────────────────────────────────────────────────────

create table public.tx_categories (
  id           text primary key,
  name         text    not null,
  type         text    not null check (type in ('INCOME', 'EXPENSE')),
  tax_relevant boolean not null default false,
  is_cogs      boolean not null default false,
  icon         text    not null default '💰',
  color        text    not null default '#6B7280'
               check (color ~ '^#[0-9A-Fa-f]{6}$'),
  sort_order   integer not null default 0
);

comment on table public.tx_categories is
  'Kategori transaksi bersama untuk semua pengguna. Id sama dengan data contoh aplikasi (ic1…ecx).';

-- Diisi di migrasi, bukan di seed.sql: seed tidak ikut `supabase db push` ke
-- proyek remote, padahal transaksi tidak bisa dicatat tanpa kategori.
-- Sumber: app/lib/core/data/mock_data.dart (MockData.txCategories).
insert into public.tx_categories
  (id, name, type, tax_relevant, is_cogs, icon, color, sort_order)
values
  ('ic1', 'Penjualan Produk',    'INCOME',  true,  false, '🛍️', '#059669',  10),
  ('ic2', 'Penjualan Jasa',      'INCOME',  true,  false, '🔧', '#059669',  20),
  ('ic3', 'Komisi',              'INCOME',  true,  false, '💼', '#059669',  30),
  ('ic4', 'Pendapatan Lain',     'INCOME',  true,  false, '💰', '#059669',  40),
  ('ec1', 'Bahan Baku',          'EXPENSE', true,  true,  '📦', '#DC2626', 110),
  ('ec2', 'Barang Dagangan',     'EXPENSE', true,  true,  '🏪', '#DC2626', 120),
  ('ec3', 'Gaji Karyawan',       'EXPENSE', true,  false, '👥', '#F59E0B', 130),
  ('ec4', 'Sewa Tempat',         'EXPENSE', true,  false, '🏠', '#F59E0B', 140),
  ('ec5', 'Listrik & Air',       'EXPENSE', false, false, '⚡', '#F59E0B', 150),
  ('ec6', 'Internet & Telepon',  'EXPENSE', false, false, '📱', '#F59E0B', 160),
  ('ec7', 'Transportasi',        'EXPENSE', false, false, '🚗', '#F59E0B', 170),
  ('ec8', 'Iklan & Marketing',   'EXPENSE', false, false, '📢', '#F59E0B', 180),
  ('ec9', 'Perlengkapan Kantor', 'EXPENSE', false, false, '📎', '#9CA3AF', 190),
  ('ec0', 'Pajak Dibayar',       'EXPENSE', true,  false, '🧾', '#9CA3AF', 200),
  ('ecx', 'Pengeluaran Lain',    'EXPENSE', false, false, '💸', '#9CA3AF', 210)
on conflict (id) do update set
  name         = excluded.name,
  type         = excluded.type,
  tax_relevant = excluded.tax_relevant,
  is_cogs      = excluded.is_cogs,
  icon         = excluded.icon,
  color        = excluded.color,
  sort_order   = excluded.sort_order;

-- ── Profil usaha ─────────────────────────────────────────────────────────────

create table public.business_profiles (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  business_name  text    not null check (length(trim(business_name)) > 0),
  owner_name     text,
  npwp           text,
  business_type  text    not null default '',
  pkp_status     boolean not null default false,
  employee_count integer not null default 0 check (employee_count >= 0),
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),

  -- Satu usaha per akun — sekaligus target upsert saat onboarding, supaya
  -- form yang terbuka di dua perangkat tidak melahirkan profil ganda.
  constraint business_profiles_user_id_key unique (user_id)
);

-- ── Transaksi ────────────────────────────────────────────────────────────────

create table public.transactions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  business_id    uuid not null
                 references public.business_profiles (id) on delete cascade,
  date           date not null,
  type           text not null check (type in ('INCOME', 'EXPENSE')),
  -- Rupiah penuh. Batas atasnya ±10 triliun; di atas itu Postgres menolak
  -- dengan kode 22003 dan aplikasi menampilkan "Nominal terlalu besar".
  amount         numeric(15, 2) not null check (amount > 0),
  -- restrict: TxData.fromJson tidak menerima transaksi tanpa kategori.
  category_id    text not null
                 references public.tx_categories (id) on delete restrict,
  description    text,
  -- Tujuh nilai PaymentMethodData.all di app/lib/models/transaction_model.dart.
  payment_method text not null default 'CASH'
                 check (payment_method in (
                   'CASH', 'TRANSFER', 'QRIS', 'KARTU_DEBIT', 'KARTU_KREDIT',
                   'COD', 'OTHER'
                 )),
  receipt_note   text,
  created_at     timestamptz not null default now()
);

create index transactions_user_date_idx
  on public.transactions (user_id, date desc);
create index transactions_business_id_idx
  on public.transactions (business_id);
create index transactions_category_id_idx
  on public.transactions (category_id);

-- ── Hak akses & Row Level Security ───────────────────────────────────────────
--
-- Proyek Supabase baru tidak lagi otomatis memberi hak tabel ke peran API,
-- jadi hak diberikan eksplisit. Peran `anon` (belum masuk) tidak mendapat apa
-- pun; `authenticated` hanya melihat dan mengubah baris miliknya.

grant usage on schema public to authenticated;

alter table public.tx_categories     enable row level security;
alter table public.business_profiles enable row level security;
alter table public.transactions      enable row level security;

revoke all on table
  public.tx_categories, public.business_profiles, public.transactions
  from anon, authenticated;

grant select on table public.tx_categories to authenticated;
grant select, insert, update, delete
  on table public.business_profiles, public.transactions to authenticated;

-- auth.uid() dibungkus select supaya dievaluasi sekali per statement, bukan
-- per baris.

create policy "Kategori bisa dibaca pengguna yang masuk"
  on public.tx_categories for select to authenticated
  using (true);

create policy "Pengguna melihat profil usahanya sendiri"
  on public.business_profiles for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Pengguna membuat profil usahanya sendiri"
  on public.business_profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Pengguna mengubah profil usahanya sendiri"
  on public.business_profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Pengguna menghapus profil usahanya sendiri"
  on public.business_profiles for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "Pengguna melihat transaksinya sendiri"
  on public.transactions for select to authenticated
  using ((select auth.uid()) = user_id);

-- Transaksi hanya boleh menempel ke usaha milik pengguna yang sama.
create policy "Pengguna mencatat transaksi untuk usahanya sendiri"
  on public.transactions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.business_profiles b
      where b.id = business_id
        and b.user_id = (select auth.uid())
    )
  );

create policy "Pengguna mengubah transaksinya sendiri"
  on public.transactions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.business_profiles b
      where b.id = business_id
        and b.user_id = (select auth.uid())
    )
  );

create policy "Pengguna menghapus transaksinya sendiri"
  on public.transactions for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ── Agregasi bulanan ─────────────────────────────────────────────────────────
--
-- Satu baris per bulan (selalu 12) untuk tahun p_year, milik pengguna yang
-- memanggil. Dipakai ringkasan dashboard dan grafik KPI; kolom hpp disiapkan
-- untuk Simulator yang menarik data pembukuan asli (linimasa Minggu 5).
--
-- security invoker: fungsi berjalan dengan hak pemanggil, jadi RLS tetap
-- berlaku. search_path kosong mencegah fungsi dibajak objek bernama sama di
-- skema lain.

create or replace function public.monthly_totals(p_year integer)
returns table (
  month    integer,
  income   numeric,
  expense  numeric,
  hpp      numeric,
  tx_count integer
)
language sql
stable
security invoker
set search_path = ''
as $$
  with totals as (
    select
      extract(month from t.date)::integer                               as m,
      sum(t.amount) filter (where t.type = 'INCOME')                    as income,
      sum(t.amount) filter (where t.type = 'EXPENSE')                   as expense,
      sum(t.amount) filter (where t.type = 'EXPENSE' and c.is_cogs)     as hpp,
      count(*)::integer                                                 as tx_count
    from public.transactions t
    join public.tx_categories c on c.id = t.category_id
    where t.user_id = (select auth.uid())
      and t.date >= make_date(p_year, 1, 1)
      and t.date <  make_date(p_year + 1, 1, 1)
    group by 1
  )
  select
    months.m,
    coalesce(totals.income, 0),
    coalesce(totals.expense, 0),
    coalesce(totals.hpp, 0),
    coalesce(totals.tx_count, 0)
  from generate_series(1, 12) as months(m)
  left join totals on totals.m = months.m
  order by months.m;
$$;

revoke execute on function public.monthly_totals(integer) from public, anon;
grant execute on function public.monthly_totals(integer) to authenticated;
