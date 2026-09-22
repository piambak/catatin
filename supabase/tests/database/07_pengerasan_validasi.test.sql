-- supabase/tests/database/07_pengerasan_validasi.test.sql
--
-- Pengerasan validasi input (#115):
--
-- * Kepemilikan lintas tabel lewat FK komposit (…, user_id). Diuji sebagai
--   postgres — peran yang MELEWATI RLS, sama seperti fungsi SECURITY DEFINER
--   dan pg_cron — karena justru di situ RLS tidak menolong.
-- * Batas panjang teks bebas dan bentuk NPWP. Diuji sebagai `authenticated`,
--   jalur yang sama dengan klien Supabase.
--
-- Nominal nol/negatif dan tanggal di luar 2000–2099 dikunci
-- 04_validasi_transaksi.test.sql. Pesan galat dicocokkan persis karena nama
-- constraint di dalamnya dipetakan klien ke field form (_constraintFields di
-- app/lib/core/network/supabase_client.dart).
--
-- Jalankan: supabase test db

begin;
create extension if not exists pgtap with schema extensions;

select plan(23);

-- ── Data awal (sebagai postgres, melewati RLS) ──────────────────────────────
--
-- Templat mulai 2099 supaya tidak ada kejadian yang langsung diterbitkan,
-- apa pun "hari ini"-nya.

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'a@contoh.test'),
  ('22222222-2222-4222-8222-222222222222', 'b@contoh.test');

insert into public.business_profiles (id, user_id, business_name) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', '11111111-1111-4111-8111-111111111111', 'Usaha A'),
  ('bbbbbbbb-0000-4000-8000-00000000000b', '22222222-2222-4222-8222-222222222222', 'Usaha B');

insert into public.transactions
  (id, user_id, business_id, date, type, amount, category_id)
values
  ('a0000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111',
   'aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-22', 'INCOME', 100000, 'ic1'),
  ('b0000000-0000-4000-8000-000000000001', '22222222-2222-4222-8222-222222222222',
   'bbbbbbbb-0000-4000-8000-00000000000b', '2026-09-22', 'INCOME', 100000, 'ic1');

insert into public.recurring_templates
  (id, user_id, business_id, type, amount, category_id, frequency, start_date)
values
  ('c0000000-0000-4000-8000-00000000000a', '11111111-1111-4111-8111-111111111111',
   'aaaaaaaa-0000-4000-8000-00000000000a', 'INCOME', 500000, 'ic1', 'MONTHLY', '2099-01-01'),
  ('c0000000-0000-4000-8000-00000000000b', '22222222-2222-4222-8222-222222222222',
   'bbbbbbbb-0000-4000-8000-00000000000b', 'INCOME', 500000, 'ic1', 'MONTHLY', '2099-01-01');

-- ── Skema ────────────────────────────────────────────────────────────────────

select fk_ok(
  'public', 'transactions', array['business_id', 'user_id'],
  'public', 'business_profiles', array['id', 'user_id'],
  'transactions (business_id, user_id) merujuk business_profiles (id, user_id)'
);
select fk_ok(
  'public', 'recurring_templates', array['business_id', 'user_id'],
  'public', 'business_profiles', array['id', 'user_id'],
  'recurring_templates (business_id, user_id) merujuk business_profiles (id, user_id)'
);
select fk_ok(
  'public', 'transactions', array['recurring_template_id', 'user_id'],
  'public', 'recurring_templates', array['id', 'user_id'],
  'transactions (recurring_template_id, user_id) merujuk recurring_templates (id, user_id)'
);
select fk_ok(
  'public', 'transaction_attachments', array['transaction_id', 'user_id'],
  'public', 'transactions', array['id', 'user_id'],
  'transaction_attachments (transaction_id, user_id) merujuk transactions (id, user_id)'
);

-- ── Kepemilikan, sebagai postgres (RLS tidak berlaku) ────────────────────────
--
-- Di setiap kasus FK lama satu kolom LOLOS (barisnya memang ada) — yang
-- menolak hanya FK komposit, jadi tes ini membuktikan lapis baru itu sendiri.

select throws_ok(
  $$ insert into public.transactions (user_id, business_id, date, type, amount, category_id)
     values ('11111111-1111-4111-8111-111111111111',
             'bbbbbbbb-0000-4000-8000-00000000000b', '2026-09-22', 'INCOME', 1000, 'ic1') $$,
  '23503',
  'insert or update on table "transactions" violates foreign key constraint "transactions_business_owner_fkey"',
  'transaksi A di usaha B ditolak walau RLS dilewati'
);

select throws_ok(
  $$ update public.transactions
        set user_id = '22222222-2222-4222-8222-222222222222'
      where id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23503',
  'insert or update on table "transactions" violates foreign key constraint "transactions_business_owner_fkey"',
  'memindahkan transaksi A ke akun B tanpa usahanya ditolak'
);

select throws_ok(
  $$ insert into public.recurring_templates
       (user_id, business_id, type, amount, category_id, frequency, start_date)
     values ('11111111-1111-4111-8111-111111111111',
             'bbbbbbbb-0000-4000-8000-00000000000b', 'INCOME', 1000, 'ic1', 'MONTHLY', '2099-01-01') $$,
  '23503',
  'insert or update on table "recurring_templates" violates foreign key constraint "recurring_templates_business_owner_fkey"',
  'templat A di usaha B ditolak walau RLS dilewati'
);

select throws_ok(
  $$ insert into public.transactions
       (user_id, business_id, date, type, amount, category_id, recurring_template_id)
     values ('11111111-1111-4111-8111-111111111111',
             'aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-22', 'INCOME', 1000, 'ic1',
             'c0000000-0000-4000-8000-00000000000b') $$,
  '23503',
  'insert or update on table "transactions" violates foreign key constraint "transactions_recurring_owner_fkey"',
  'transaksi A yang bertaut ke templat B ditolak'
);

select throws_ok(
  $$ insert into public.transaction_attachments
       (id, user_id, transaction_id, storage_path, file_name, mime_type, size_bytes)
     values (
       'd0000000-0000-4000-8000-0000000000ab',
       '11111111-1111-4111-8111-111111111111',
       'b0000000-0000-4000-8000-000000000001',
       '11111111-1111-4111-8111-111111111111/b0000000-0000-4000-8000-000000000001/d0000000-0000-4000-8000-0000000000ab.jpg',
       'struk.jpg', 'image/jpeg', 1000
     ) $$,
  '23503',
  'insert or update on table "transaction_attachments" violates foreign key constraint "transaction_attachments_transaction_owner_fkey"',
  'lampiran A pada transaksi B ditolak walau storage_path-nya konsisten'
);

-- Menghapus templat hanya memutus tautan: ON DELETE SET NULL
-- (recurring_template_id) tidak boleh ikut mengosongkan user_id.

select lives_ok(
  $$ insert into public.transactions
       (id, user_id, business_id, date, type, amount, category_id, recurring_template_id)
     values ('a0000000-0000-4000-8000-000000000002',
             '11111111-1111-4111-8111-111111111111',
             'aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-22', 'INCOME', 1000, 'ic1',
             'c0000000-0000-4000-8000-00000000000a') $$,
  'transaksi A bertaut ke templat A tersimpan'
);
select lives_ok(
  $$ delete from public.recurring_templates
      where id = 'c0000000-0000-4000-8000-00000000000a' $$,
  'templat A yang masih punya transaksi bisa dihapus'
);
select is(
  (select row(recurring_template_id, user_id)::text
     from public.transactions
    where id = 'a0000000-0000-4000-8000-000000000002'),
  row(null::uuid, '11111111-1111-4111-8111-111111111111'::uuid)::text,
  'tautan templat terputus, user_id transaksi tetap'
);

-- ── Sebagai A ────────────────────────────────────────────────────────────────

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

-- RLS tetap lapis pertama: lewat PostgREST pelanggaran kepemilikan tetap
-- 42501, bukan 23503.
select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id)
     values ('bbbbbbbb-0000-4000-8000-00000000000b', '2026-09-22', 'INCOME', 1000, 'ic1') $$,
  '42501', null,
  'lewat klien, transaksi di usaha B tetap ditolak RLS lebih dulu'
);

-- Panjang teks

select lives_ok(
  $$ insert into public.transactions
       (business_id, date, type, amount, category_id, description, receipt_note)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-22', 'INCOME', 1000, 'ic1',
             repeat('x', 500), repeat('y', 500)) $$,
  'catatan dan keterangan struk 500 karakter tersimpan'
);
select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id, description)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-22', 'INCOME', 1000, 'ic1',
             repeat('x', 501)) $$,
  '23514',
  'new row for relation "transactions" violates check constraint "transactions_description_length_check"',
  'catatan 501 karakter ditolak'
);
select throws_ok(
  $$ insert into public.transactions (business_id, date, type, amount, category_id, receipt_note)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-22', 'INCOME', 1000, 'ic1',
             repeat('y', 501)) $$,
  '23514',
  'new row for relation "transactions" violates check constraint "transactions_receipt_note_length_check"',
  'keterangan struk 501 karakter ditolak'
);
select throws_ok(
  $$ insert into public.recurring_templates
       (business_id, type, amount, category_id, frequency, start_date, description)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'INCOME', 1000, 'ic1', 'MONTHLY',
             '2099-01-01', repeat('x', 501)) $$,
  '23514',
  'new row for relation "recurring_templates" violates check constraint "recurring_templates_description_length_check"',
  'catatan templat 501 karakter ditolak'
);
select throws_ok(
  $$ update public.business_profiles set business_name = repeat('n', 101)
      where id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  '23514',
  'new row for relation "business_profiles" violates check constraint "business_profiles_business_name_length_check"',
  'nama usaha 101 karakter ditolak'
);
select throws_ok(
  $$ update public.business_profiles set owner_name = repeat('n', 101)
      where id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  '23514',
  'new row for relation "business_profiles" violates check constraint "business_profiles_owner_name_length_check"',
  'nama pemilik 101 karakter ditolak'
);
select throws_ok(
  $$ update public.business_profiles set business_type = repeat('t', 101)
      where id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  '23514',
  'new row for relation "business_profiles" violates check constraint "business_profiles_business_type_length_check"',
  'jenis usaha 101 karakter ditolak'
);

-- NPWP

select throws_ok(
  $$ update public.business_profiles set npwp = '01.234.567.8-901.00A'
      where id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  '23514',
  'new row for relation "business_profiles" violates check constraint "business_profiles_npwp_format_check"',
  'NPWP berhuruf ditolak'
);
select throws_ok(
  $$ update public.business_profiles set npwp = ''
      where id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  '23514',
  'new row for relation "business_profiles" violates check constraint "business_profiles_npwp_format_check"',
  'NPWP string kosong ditolak — klien mengirim null'
);
select lives_ok(
  $$ update public.business_profiles
        set npwp = '01.234.567.8-901.000', business_name = repeat('n', 100)
      where id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  'NPWP berformat dan nama usaha 100 karakter tersimpan'
);

select * from finish();
rollback;
