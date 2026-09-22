-- supabase/tests/database/05_transaksi_berulang.test.sql
--
-- Transaksi berulang (#58): penjadwalan WEEKLY/MONTHLY tanpa backfill,
-- clamping akhir bulan, penerbitan susulan yang idempoten, templat yang
-- berhenti tidak bisa diaktifkan/disunting lagi, isolasi antar-akun, dan
-- pengguna tidak bisa memalsukan recurring_template_id.
--
-- "Hari ini" dijepit ke 2026-09-21 lewat GUC catatin.hari_ini supaya seluruh
-- tes deterministik terlepas dari jam sistem yang menjalankannya.
--
-- Jalankan: supabase test db

begin;
create extension if not exists pgtap with schema extensions;

select set_config('catatin.hari_ini', '2026-09-21', true);

select plan(51);

-- ── Data awal (sebagai postgres, melewati RLS) ──────────────────────────────

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@contoh.test'),
  ('22222222-2222-4222-8222-222222222222', 'b@contoh.test');

insert into public.business_profiles (id, user_id, business_name) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', '11111111-1111-4111-8111-111111111111', 'Usaha A'),
  ('bbbbbbbb-0000-4000-8000-00000000000b', '22222222-2222-4222-8222-222222222222', 'Usaha B');

-- ── Sebagai A: tiga templat dengan jadwal berbeda ───────────────────────────
--
-- T1 MONTHLY start 2026-01-31: kejadian ke-n = 31 Jan + n bulan, dihitung
-- SELALU dari 31 Jan (bukan dirantai) — n=8 jatuh di September, 31 tidak ada
-- di situ jadi di-clamp ke 30. Kejadian n=7 (31 Agu) < hari ini (21 Sep),
-- n=8 (30 Sep) >= hari ini, jadi next_date = 2026-09-30. Delapan kejadian
-- sebelumnya (n=0..7) tidak backfill: 0 transaksi.
--
-- T2 MONTHLY start 2026-09-21 = hari ini: kejadian n=0 jatuh hari ini
-- sendiri, jadi langsung diterbitkan (1 transaksi, 2026-09-21), lalu
-- next_date maju ke n=1 = 2026-10-21.
--
-- T3 WEEKLY start 2026-09-01: selisih ke hari ini 20 hari, ceil(20/7)=3,
-- next_date = 2026-09-01 + 21 = 2026-09-22 (belum jatuh tempo, 0 transaksi).

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into public.recurring_templates
       (id, business_id, type, amount, category_id, frequency, start_date)
     values
       ('c0000000-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-00000000000a',
        'INCOME', 500000, 'ic1', 'MONTHLY', '2026-01-31'),
       ('c0000000-0000-4000-8000-000000000002', 'aaaaaaaa-0000-4000-8000-00000000000a',
        'INCOME', 300000, 'ic1', 'MONTHLY', '2026-09-21'),
       ('c0000000-0000-4000-8000-000000000003', 'aaaaaaaa-0000-4000-8000-00000000000a',
        'EXPENSE', 50000, 'ec1', 'WEEKLY', '2026-09-01') $$,
  'T1, T2, T3 tersimpan'
);

select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000001'),
  '2026-09-30'::date,
  'T1 MONTHLY start 2026-01-31: next_date lompat ke 2026-09-30 (clamp akhir bulan), tanpa backfill'
);
select is(
  (select count(*)::integer from public.transactions
    where recurring_template_id = 'c0000000-0000-4000-8000-000000000001'),
  0,
  'T1 belum menerbitkan apa pun — delapan kejadian yang lewat tidak backfill'
);

select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000002'),
  '2026-10-21'::date,
  'T2 MONTHLY start = hari ini: next_date maju ke 2026-10-21 setelah terbit langsung'
);
select is(
  (select count(*)::integer from public.transactions
    where recurring_template_id = 'c0000000-0000-4000-8000-000000000002'),
  1,
  'T2 langsung menerbitkan 1 transaksi karena start_date jatuh hari ini'
);
select is(
  (select date from public.transactions
    where recurring_template_id = 'c0000000-0000-4000-8000-000000000002'),
  '2026-09-21'::date,
  'transaksi T2 bertanggal hari ini'
);

select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000003'),
  '2026-09-22'::date,
  'T3 WEEKLY start 2026-09-01: next_date ke 2026-09-22 (belum jatuh tempo hari ini)'
);

-- ── Susulan sebagai postgres ─────────────────────────────────────────────────
--
-- issue_recurring_transactions('2026-10-21') menerbitkan setiap kejadian
-- yang jatuh tempo dari ketiga templat, dihitung dengan tangan:
--   T1 (MONTHLY dari 31 Jan): hanya 2026-09-30 (n=8) yang <= 2026-10-21;
--     kejadian n=9 = 31 Okt > 2026-10-21.                              (1)
--   T2 (MONTHLY dari 21 Sep, next_date sudah 2026-10-21): 2026-10-21
--     (n=1) <= 2026-10-21; n=2 = 21 Nov > 2026-10-21.                  (1)
--   T3 (WEEKLY dari 1 Sep, next_date sudah 2026-09-22): 2026-09-22,
--     2026-09-29, 2026-10-06, 2026-10-13, 2026-10-20 semuanya
--     <= 2026-10-21; kejadian berikutnya 2026-10-27 > 2026-10-21.       (5)
-- Total = 1 + 1 + 5 = 7 transaksi baru.

reset role;

select is(
  public.issue_recurring_transactions('2026-10-21'),
  7,
  'susulan sampai 2026-10-21: T1 (1) + T2 (1) + T3 (5) = 7 transaksi'
);
select is(
  public.issue_recurring_transactions('2026-10-21'),
  0,
  'memanggil lagi dengan tanggal sama tidak menerbitkan apa pun (idempoten)'
);

select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000001'),
  '2026-10-31'::date, 'T1 next_date lanjut ke 2026-10-31 setelah susulan'
);
select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000002'),
  '2026-11-21'::date, 'T2 next_date lanjut ke 2026-11-21 setelah susulan'
);
select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000003'),
  '2026-10-27'::date, 'T3 next_date lanjut ke 2026-10-27 setelah susulan'
);

select is(
  (select count(*)::integer from public.transactions
    where recurring_template_id = 'c0000000-0000-4000-8000-000000000001'),
  1, 'T1 total 1 transaksi (susulan)'
);
select is(
  (select count(*)::integer from public.transactions
    where recurring_template_id = 'c0000000-0000-4000-8000-000000000002'),
  2, 'T2 total 2 transaksi (langsung + susulan)'
);
select is(
  (select count(*)::integer from public.transactions
    where recurring_template_id = 'c0000000-0000-4000-8000-000000000003'),
  5, 'T3 total 5 transaksi (susulan mingguan)'
);

-- ── end_date inklusif (T4) ───────────────────────────────────────────────────
--
-- T4 WEEKLY start 2026-09-01, end_date 2026-09-22: next_date awal sama
-- dengan T3 (2026-09-22), persis di end_date — masih aktif (inklusif). Saat
-- diterbitkan (postgres, p_today 2026-09-22), kejadian 2026-09-22 terbit,
-- lalu kejadian berikutnya (2026-09-29) melewati end_date sehingga templat
-- berhenti otomatis.

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into public.recurring_templates
       (id, business_id, type, amount, category_id, frequency, start_date, end_date)
     values
       ('c0000000-0000-4000-8000-000000000004', 'aaaaaaaa-0000-4000-8000-00000000000a',
        'EXPENSE', 20000, 'ec1', 'WEEKLY', '2026-09-01', '2026-09-22') $$,
  'T4 tersimpan'
);
select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000004'),
  '2026-09-22'::date, 'T4 saat dibuat: next_date 2026-09-22 (persis di end_date, masih aktif)'
);
select is(
  (select is_active from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000004'),
  true, 'T4 masih aktif saat dibuat'
);

reset role;
select is(
  public.issue_recurring_transactions('2026-09-22'),
  1,
  'T4 menerbitkan tepat 1 transaksi pada end_date (inklusif)'
);
select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000004'),
  null::date, 'T4 next_date null setelah melewati end_date'
);
select is(
  (select is_active from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000004'),
  false, 'T4 nonaktif otomatis setelah end_date terlewati'
);
select is(
  (select count(*)::integer from public.transactions
    where recurring_template_id = 'c0000000-0000-4000-8000-000000000004'),
  1, 'T4 total tepat 1 transaksi, tidak lebih'
);

-- ── Berhenti tidak bisa diaktifkan/disunting lagi (T5) ──────────────────────
--
-- T5 MONTHLY start 2026-08-21: kejadian n=1 = 2026-09-21 (hari ini) sehingga
-- langsung terbit 1 transaksi, next_date maju ke n=2 = 2026-10-21.

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into public.recurring_templates
       (id, business_id, type, amount, category_id, frequency, start_date)
     values
       ('c0000000-0000-4000-8000-000000000005', 'aaaaaaaa-0000-4000-8000-00000000000a',
        'INCOME', 400000, 'ic1', 'MONTHLY', '2026-08-21') $$,
  'T5 tersimpan'
);
select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000005'),
  '2026-10-21'::date, 'T5 setelah terbit langsung: next_date maju ke 2026-10-21'
);
select is(
  (select count(*)::integer from public.transactions
    where recurring_template_id = 'c0000000-0000-4000-8000-000000000005'),
  1, 'T5 sudah menerbitkan 1 transaksi saat dibuat'
);

select lives_ok(
  $$ update public.recurring_templates set is_active = false
      where id = 'c0000000-0000-4000-8000-000000000005' $$,
  'T5 dihentikan pengguna'
);
select is(
  (select is_active from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000005'),
  false, 'T5 dihentikan: is_active false'
);
select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000005'),
  null::date, 'T5 dihentikan: next_date null'
);

reset role;
select is(
  public.issue_recurring_transactions('2026-12-31', 'c0000000-0000-4000-8000-000000000005'),
  0,
  'templat yang sudah berhenti tidak pernah diterbitkan lagi'
);

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ update public.recurring_templates set is_active = true
      where id = 'c0000000-0000-4000-8000-000000000005' $$,
  'percobaan mengaktifkan lagi T5 tidak menimbulkan galat...'
);
select is(
  (select is_active from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000005'),
  false, '...tapi diabaikan diam-diam: T5 tetap tidak aktif'
);

select lives_ok(
  $$ update public.recurring_templates set amount = 999999
      where id = 'c0000000-0000-4000-8000-000000000005' $$,
  'percobaan menyunting T5 yang beku tidak menimbulkan galat...'
);
select is(
  (select amount from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000005'),
  400000::numeric, '...tapi diabaikan diam-diam: amount T5 tidak berubah'
);

-- ── Sunting frekuensi menghitung ulang next_date (T6) ───────────────────────
--
-- T6 WEEKLY start 2026-09-01: next_date awal 2026-09-22 (sama seperti T3).
-- Diganti ke MONTHLY (start_date tetap): kejadian n=0 = 2026-09-01 < hari
-- ini, jadi majunya ke n=1 = 2026-10-01.

select lives_ok(
  $$ insert into public.recurring_templates
       (id, business_id, type, amount, category_id, frequency, start_date)
     values
       ('c0000000-0000-4000-8000-000000000006', 'aaaaaaaa-0000-4000-8000-00000000000a',
        'EXPENSE', 60000, 'ec1', 'WEEKLY', '2026-09-01') $$,
  'T6 tersimpan'
);
select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000006'),
  '2026-09-22'::date, 'T6 awal: next_date 2026-09-22'
);

select lives_ok(
  $$ update public.recurring_templates set frequency = 'MONTHLY'
      where id = 'c0000000-0000-4000-8000-000000000006' $$,
  'T6 diganti ke MONTHLY'
);
select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000006'),
  '2026-10-01'::date, 'T6 setelah ganti frequency: next_date dihitung ulang dari jadwal baru'
);
select is(
  (select frequency from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000006'),
  'MONTHLY', 'T6 frequency benar-benar berubah jadi MONTHLY'
);

select lives_ok(
  $$ update public.recurring_templates set amount = 70000
      where id = 'c0000000-0000-4000-8000-000000000006' $$,
  'T6 amount diubah tanpa mengubah jadwal'
);
select is(
  (select next_date from public.recurring_templates where id = 'c0000000-0000-4000-8000-000000000006'),
  '2026-10-01'::date, 'ubah amount saja tidak mengubah next_date'
);

-- ── recurring_template_id tidak bisa dipalsukan pengguna ────────────────────

select lives_ok(
  $$ insert into public.transactions
       (id, business_id, date, type, amount, category_id, recurring_template_id)
     values ('e0000000-0000-4000-8000-00000000000e',
             'aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-21', 'INCOME', 1000, 'ic1',
             'c0000000-0000-4000-8000-000000000001') $$,
  'transaksi manual dengan recurring_template_id "titipan" tetap tersimpan...'
);
select is(
  (select recurring_template_id from public.transactions
    where id = 'e0000000-0000-4000-8000-00000000000e'),
  null::uuid,
  '...tapi recurring_template_id dipaksa null oleh trigger, tidak bisa dipalsukan pengguna'
);

-- ── Validasi ─────────────────────────────────────────────────────────────────

select throws_ok(
  $$ insert into public.recurring_templates (business_id, type, amount, category_id, frequency, start_date)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'INCOME', 0, 'ic1', 'MONTHLY', '2026-09-21') $$,
  '23514',
  'new row for relation "recurring_templates" violates check constraint "recurring_templates_amount_check"',
  'nominal 0 ditolak'
);
select throws_ok(
  $$ insert into public.recurring_templates (business_id, type, amount, category_id, frequency, start_date)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'EXPENSE', 1000, 'ic1', 'MONTHLY', '2026-09-21') $$,
  '23503',
  'insert or update on table "recurring_templates" violates foreign key constraint "recurring_templates_category_type_fkey"',
  'kategori pemasukan pada templat EXPENSE ditolak'
);
select throws_ok(
  $$ insert into public.recurring_templates
       (business_id, type, amount, category_id, frequency, start_date, end_date)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'INCOME', 1000, 'ic1', 'MONTHLY',
             '2026-09-21', '2026-09-01') $$,
  '23514',
  'new row for relation "recurring_templates" violates check constraint "recurring_templates_end_after_start_check"',
  'end_date sebelum start_date ditolak'
);
select throws_ok(
  $$ insert into public.recurring_templates (business_id, type, amount, category_id, frequency, start_date)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'INCOME', 1000, 'ic1', 'DAILY', '2026-09-21') $$,
  '23514',
  'new row for relation "recurring_templates" violates check constraint "recurring_templates_frequency_check"',
  'frequency di luar WEEKLY/MONTHLY ditolak'
);

-- ── Isolasi antar-akun (B) ───────────────────────────────────────────────────

select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-4222-8222-222222222222", "role": "authenticated"}', true);

select is(
  (select count(*)::integer from public.recurring_templates), 0,
  'B tidak melihat satu pun templat A'
);
select throws_ok(
  $$ insert into public.recurring_templates (business_id, type, amount, category_id, frequency, start_date)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'INCOME', 1000, 'ic1', 'MONTHLY', '2026-09-21') $$,
  '42501', null,
  'B tidak bisa membuat templat berulang di usaha A'
);

-- ── anon tidak punya hak apa pun ────────────────────────────────────────────

select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok(
  'select count(*) from public.recurring_templates',
  '42501', null,
  'anon ditolak membaca recurring_templates'
);
select throws_ok(
  $$ select public.issue_recurring_transactions() $$,
  '42501', null,
  'anon ditolak memanggil issue_recurring_transactions'
);
select throws_ok(
  $$ select public.catatin_hari_ini() $$,
  '42501', null,
  'anon ditolak memanggil catatin_hari_ini'
);

select * from finish();
rollback;
