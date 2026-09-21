-- supabase/migrations/20260921141954_transaksi_berulang.sql
--
-- Transaksi berulang (#58): templat WEEKLY/MONTHLY yang menerbitkan transaksi
-- sendiri lewat pg_cron, tanpa perlu aplikasi terbuka.
--
-- Aturan penjadwalan (wiki/arsitektur/backend-dan-api.md "Transaksi
-- berulang"):
--   * start_date adalah jangkar jadwal. Kejadian ke-n MONTHLY dihitung
--     SELALU dari start_date + n bulan (bukan dari kejadian sebelumnya),
--     supaya Postgres men-clamp ke akhir bulan secara konsisten — 31 Jan
--     jadi 28 Feb, lalu kembali 31 Mar, bukan terjebak di tanggal 28
--     seterusnya seperti kalau kejadian dirantai.
--   * TIDAK ADA BACKFILL: kejadian sebelum hari templat dibuat tidak pernah
--     diterbitkan. Kejadian yang jatuh persis hari ini tetap diterbitkan
--     saat itu juga.
--   * end_date inklusif; sekali is_active jadi false dan next_date null,
--     templat itu beku selamanya — tidak bisa diaktifkan atau diubah lagi.
--   * current_user membedakan pembaruan sistem (postgres/supabase_admin,
--     dipakai issue_recurring_transactions lewat SECURITY DEFINER) dari
--     suntingan pengguna: hanya pembaruan sistem yang boleh menimpa
--     next_date/is_active hasil perhitungan, dan hanya sistem yang boleh
--     mengisi recurring_template_id pada transactions.
--   * Idempoten: indeks unik parsial (recurring_template_id, date) + ON
--     CONFLICT DO NOTHING membuat kejadian yang sama tidak pernah
--     diterbitkan dua kali, baik dipanggil ulang oleh cron, trigger, atau
--     manual.

-- ── "Hari ini" versi Catatin ─────────────────────────────────────────────────
--
-- GUC catatin.hari_ini memungkinkan tes pgTAP menjepit tanggal "hari ini"
-- tanpa bergantung pada jam sistem. Di luar tes, GUC itu tidak diset, jadi
-- jatuh ke waktu Jakarta sungguhan.

create or replace function public.catatin_hari_ini()
returns date
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    nullif(current_setting('catatin.hari_ini', true), '')::date,
    (now() at time zone 'Asia/Jakarta')::date
  );
$$;

comment on function public.catatin_hari_ini() is
  'Tanggal "hari ini" Catatin (WIB), bisa dijepit tes lewat GUC catatin.hari_ini.';

-- ── Aritmetika jadwal ─────────────────────────────────────────────────────────
--
-- recurring_occurrence menghitung kejadian ke-n SELALU dari p_start (bukan
-- rantai dari kejadian sebelumnya), sehingga clamping akhir bulan konsisten.
-- WEEKLY: kelipatan 7 hari. MONTHLY: aritmetika bulan bawaan Postgres — date
-- + interval bulan otomatis mengecilkan tanggal ke hari terakhir bulan
-- tujuan kalau tanggal aslinya tidak ada di sana (mis. 31 Jan + 1 bulan =
-- 28 Feb 2026).

create or replace function public.recurring_occurrence(
  p_start     date,
  p_frequency text,
  p_n         integer
)
returns date
language sql
immutable
security invoker
set search_path = ''
as $$
  select case p_frequency
    when 'WEEKLY'  then p_start + 7 * p_n
    when 'MONTHLY' then (p_start + make_interval(months => p_n))::date
  end;
$$;

comment on function public.recurring_occurrence(date, text, integer) is
  'Tanggal kejadian ke-p_n dari jadwal WEEKLY/MONTHLY yang berjangkar di p_start, dengan clamping akhir bulan bawaan Postgres.';

-- recurring_first_on_or_after: kejadian terkecil >= greatest(p_start, p_day).
-- n dihitung aritmetika (bukan loop tak terbatas), lalu disesuaikan paling
-- banyak sekali: untuk MONTHLY, n perkiraan dari selisih tahun/bulan selalu
-- menghasilkan kejadian di bulan-kalender yang sama dengan target, jadi
-- cukup dibandingkan satu kali — kalau kejadian itu masih sebelum target,
-- majukan satu bulan lagi (otomatis melewati target karena beda bulan).

create or replace function public.recurring_first_on_or_after(
  p_start     date,
  p_frequency text,
  p_day       date
)
returns date
language plpgsql
immutable
security invoker
set search_path = ''
as $$
declare
  v_target date := greatest(p_start, p_day);
  v_n      integer;
  v_result date;
begin
  if p_frequency = 'WEEKLY' then
    v_n := ceil((v_target - p_start)::numeric / 7)::integer;
    return public.recurring_occurrence(p_start, p_frequency, v_n);
  elsif p_frequency = 'MONTHLY' then
    v_n := (extract(year from v_target)::integer - extract(year from p_start)::integer) * 12
         + (extract(month from v_target)::integer - extract(month from p_start)::integer);
    v_result := public.recurring_occurrence(p_start, p_frequency, v_n);
    if v_result < v_target then
      v_n := v_n + 1;
      v_result := public.recurring_occurrence(p_start, p_frequency, v_n);
    end if;
    return v_result;
  else
    return null;
  end if;
end;
$$;

comment on function public.recurring_first_on_or_after(date, text, date) is
  'Kejadian terkecil dari jadwal p_start/p_frequency yang >= greatest(p_start, p_day). Dipakai saat templat dibuat/disunting dan saat menerbitkan susulan.';

-- ── Templat transaksi berulang ────────────────────────────────────────────────

create table public.recurring_templates (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  business_id    uuid not null
                 references public.business_profiles (id) on delete cascade,
  type           text not null check (type in ('INCOME', 'EXPENSE')),
  amount         numeric(15, 2) not null check (amount > 0),
  category_id    text not null
                 references public.tx_categories (id) on delete restrict,
  description    text,
  payment_method text not null default 'CASH'
                 check (payment_method in (
                   'CASH', 'TRANSFER', 'QRIS', 'KARTU_DEBIT', 'KARTU_KREDIT',
                   'COD', 'OTHER'
                 )),
  frequency      text not null check (frequency in ('WEEKLY', 'MONTHLY')),
  start_date     date not null
                 check (start_date between date '2000-01-01' and date '2099-12-31'),
  end_date       date
                 check (end_date between date '2000-01-01' and date '2099-12-31'),
  next_date      date,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),

  constraint recurring_templates_end_after_start_check
    check (end_date is null or end_date >= start_date),
  constraint recurring_templates_category_type_fkey
    foreign key (category_id, type)
    references public.tx_categories (id, type)
);

comment on table public.recurring_templates is
  'Templat transaksi berulang (WEEKLY/MONTHLY). next_date dihitung trigger, bukan diisi klien. Diterbitkan jadi baris transactions oleh issue_recurring_transactions().';
comment on constraint recurring_templates_end_after_start_check on public.recurring_templates is
  'end_date tidak boleh sebelum start_date. Dipetakan klien ke field end_date.';
comment on constraint recurring_templates_category_type_fkey on public.recurring_templates is
  'Kategori harus sejenis dengan templat (INCOME/EXPENSE). Dipetakan klien ke field category_id.';

create index recurring_templates_user_active_next_idx
  on public.recurring_templates (user_id, is_active, next_date);

-- ── Sebelum simpan: hitung next_date, bekukan templat yang sudah berhenti ────

create or replace function public.recurring_templates_before_write()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and current_user in ('postgres', 'supabase_admin') then
    -- Pembaruan sistem dari issue_recurring_transactions() (mis. next_date
    -- setelah menerbitkan transaksi, atau menonaktifkan templat yang
    -- melewati end_date). Diloloskan apa adanya, tidak diproses ulang
    -- seperti suntingan pengguna, supaya hasil hitungannya tidak tertimpa.
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.is_active := true;
    new.created_at := now();
    new.updated_at := now();
    new.next_date := public.recurring_first_on_or_after(
      new.start_date, new.frequency, public.catatin_hari_ini());
    if new.end_date is not null and new.next_date > new.end_date then
      new.next_date := null;
      new.is_active := false;
    end if;
    return new;
  end if;

  -- UPDATE oleh pengguna.
  if not old.is_active then
    -- Templat yang sudah berhenti dibekukan: perubahan apa pun diabaikan
    -- diam-diam, supaya tidak pernah bisa diaktifkan atau disunting lagi.
    return old;
  end if;

  new.user_id     := old.user_id;
  new.business_id := old.business_id;
  new.created_at  := old.created_at;
  new.updated_at  := now();

  if not new.is_active then
    -- Berhenti.
    new.next_date := null;
    return new;
  end if;

  new.is_active := true;
  if new.frequency <> old.frequency or new.start_date <> old.start_date then
    -- Jadwal berubah: next_date dihitung ulang dari jadwal baru, mulai hari
    -- ini — kejadian yang sudah lewat pada jadwal lama tidak susulan.
    new.next_date := public.recurring_first_on_or_after(
      new.start_date, new.frequency, public.catatin_hari_ini());
  else
    -- next_date kiriman pengguna diabaikan; hanya trigger yang boleh
    -- mengisinya.
    new.next_date := old.next_date;
  end if;

  if new.end_date is not null and new.next_date is not null and new.next_date > new.end_date then
    new.next_date := null;
    new.is_active := false;
  end if;

  return new;
end;
$$;

create trigger recurring_templates_before_write
  before insert or update on public.recurring_templates
  for each row execute function public.recurring_templates_before_write();

-- ── Tautan transaksi ↔ templat ────────────────────────────────────────────────

alter table public.transactions
  add column recurring_template_id uuid
  references public.recurring_templates (id) on delete set null;

-- Parsial: hanya membatasi baris yang benar memang berasal dari templat, dan
-- jadi target ON CONFLICT DO NOTHING di issue_recurring_transactions supaya
-- kejadian yang sama tidak pernah diterbitkan dua kali.
create unique index transactions_recurring_date_key
  on public.transactions (recurring_template_id, date)
  where recurring_template_id is not null;

-- Pengguna tidak pernah boleh memalsukan tautan ini — hanya sistem (lewat
-- issue_recurring_transactions, SECURITY DEFINER) yang mengisinya.
create or replace function public.transactions_recurring_guard()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if current_user not in ('postgres', 'supabase_admin') then
    if tg_op = 'INSERT' then
      new.recurring_template_id := null;
    elsif tg_op = 'UPDATE' then
      new.recurring_template_id := old.recurring_template_id;
    end if;
  end if;
  return new;
end;
$$;

create trigger transactions_recurring_guard
  before insert or update on public.transactions
  for each row execute function public.transactions_recurring_guard();

-- ── Penerbitan ────────────────────────────────────────────────────────────────
--
-- SECURITY DEFINER: dipanggil pg_cron (tanpa sesi pengguna) dan trigger AFTER
-- di bawah, keduanya perlu menembus RLS untuk menulis transaksi ke banyak
-- pengguna sekaligus. p_today default catatin_hari_ini(); bisa dioverride
-- (mis. tes) tanpa mengubah GUC. p_template_id membatasi ke satu templat.

create or replace function public.issue_recurring_transactions(
  p_today       date default null,
  p_template_id uuid default null
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_today    date := coalesce(p_today, public.catatin_hari_ini());
  v_template record;
  v_next     date;
  v_active   boolean;
  v_inserted integer;
  v_total    integer := 0;
begin
  for v_template in
    select t.*
      from public.recurring_templates t
     where t.is_active
       and t.next_date is not null
       and t.next_date <= v_today
       and (p_template_id is null or t.id = p_template_id)
     order by t.id
     for update
  loop
    v_next   := v_template.next_date;
    v_active := true;

    -- Susulan: terbitkan setiap kejadian yang jatuh tempo, bukan cuma yang
    -- terakhir — supaya hari yang terlewat (mis. cron tidak jalan) tetap
    -- lengkap.
    while v_next is not null and v_next <= v_today loop
      insert into public.transactions
        (user_id, business_id, date, type, amount, category_id, description,
         payment_method, recurring_template_id)
      values
        (v_template.user_id, v_template.business_id, v_next, v_template.type,
         v_template.amount, v_template.category_id, v_template.description,
         v_template.payment_method, v_template.id)
      on conflict (recurring_template_id, date) where recurring_template_id is not null
        do nothing;

      get diagnostics v_inserted = row_count;
      v_total := v_total + v_inserted;

      v_next := public.recurring_first_on_or_after(
        v_template.start_date, v_template.frequency, v_next + 1);
      if v_template.end_date is not null and v_next > v_template.end_date then
        v_next   := null;
        v_active := false;
      end if;
    end loop;

    update public.recurring_templates
       set next_date = v_next,
           is_active = v_active
     where id = v_template.id;
  end loop;

  return v_total;
end;
$$;

comment on function public.issue_recurring_transactions(date, uuid) is
  'Menerbitkan semua kejadian jatuh tempo (<=p_today) dari templat aktif. Idempoten lewat transactions_recurring_date_key. Dipanggil pg_cron harian dan trigger recurring_templates_after_write.';

-- Terbit langsung kalau kejadian pertama jatuh persis hari templat dibuat
-- (atau disunting jadwalnya). pg_trigger_depth() > 1 menghindari rekursi:
-- UPDATE yang dilakukan issue_recurring_transactions() sendiri terhadap
-- baris templat ini akan memicu trigger AFTER ini lagi secara bersarang;
-- level pertama (depth 1, dipicu langsung oleh pernyataan pengguna) yang
-- boleh menerbitkan.
create or replace function public.recurring_templates_after_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 then
    return null;
  end if;

  if new.is_active and new.next_date <= public.catatin_hari_ini() then
    perform public.issue_recurring_transactions(null, new.id);
  end if;

  return null;
end;
$$;

create trigger recurring_templates_after_write
  after insert or update on public.recurring_templates
  for each row execute function public.recurring_templates_after_write();

-- ── Hak akses & Row Level Security ───────────────────────────────────────────

alter table public.recurring_templates enable row level security;

revoke all on table public.recurring_templates from anon, authenticated;
grant select, insert, update on table public.recurring_templates to authenticated;

create policy "Pengguna melihat templat berulang miliknya sendiri"
  on public.recurring_templates for select to authenticated
  using ((select auth.uid()) = user_id);

-- Templat hanya boleh menempel ke usaha milik pengguna yang sama.
create policy "Pengguna membuat templat berulang untuk usahanya sendiri"
  on public.recurring_templates for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.business_profiles b
      where b.id = business_id
        and b.user_id = (select auth.uid())
    )
  );

create policy "Pengguna mengubah templat berulang miliknya sendiri"
  on public.recurring_templates for update to authenticated
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

-- Tidak ada kebijakan delete: berhenti dilakukan lewat is_active = false
-- (lihat recurring_templates_before_write), bukan penghapusan baris.

-- ── Hak fungsi ────────────────────────────────────────────────────────────────
--
-- Hanya tiga fungsi baca murni yang dipanggil trigger sebagai pengguna biasa
-- (security invoker) yang perlu EXECUTE untuk authenticated. Fungsi penulis
-- (issue_recurring_transactions) dan fungsi trigger lain tidak pernah
-- dipanggil langsung oleh peran API — trigger tidak butuh hak EXECUTE untuk
-- terpicu — jadi dicabut sepenuhnya.

revoke execute on function public.catatin_hari_ini() from public, anon;
grant execute on function public.catatin_hari_ini() to authenticated;

revoke execute on function public.recurring_occurrence(date, text, integer) from public, anon;
grant execute on function public.recurring_occurrence(date, text, integer) to authenticated;

revoke execute on function public.recurring_first_on_or_after(date, text, date) from public, anon;
grant execute on function public.recurring_first_on_or_after(date, text, date) to authenticated;

revoke execute on function public.issue_recurring_transactions(date, uuid)
  from public, anon, authenticated;
revoke execute on function public.recurring_templates_before_write()
  from public, anon, authenticated;
revoke execute on function public.transactions_recurring_guard()
  from public, anon, authenticated;
revoke execute on function public.recurring_templates_after_write()
  from public, anon, authenticated;

-- ── Penjadwal (pg_cron) ───────────────────────────────────────────────────────
--
-- Menerbitkan susulan setiap hari walau tidak ada pengguna yang membuka
-- aplikasi hari itu. issue_recurring_transactions() sendiri idempoten (lihat
-- komentar di atas), jadi aman kalau tumpang tindih dengan penerbitan lewat
-- trigger recurring_templates_after_write.
--
-- 17:05 UTC = 00:05 WIB (Asia/Jakarta, UTC+7): sedikit lewat tengah malam
-- supaya catatin_hari_ini() sudah berpindah ke hari berikutnya saat cron
-- berjalan.
create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'catatin-transaksi-berulang',
  '5 17 * * *',
  $$select public.issue_recurring_transactions()$$
);
