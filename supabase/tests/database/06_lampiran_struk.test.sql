-- supabase/tests/database/06_lampiran_struk.test.sql
--
-- Lampiran struk (#59): tabel transaction_attachments (constraint path/mime/
-- ukuran, isolasi antar-akun, cascade saat transaksi dihapus) dan kebijakan
-- storage.objects di bucket `receipts`.
--
-- Uji storage.objects dijalankan hanya kalau tabelnya ada — `supabase db
-- start` di CI cuma container Postgres tanpa layanan Storage, jadi
-- storage.buckets ada (dibuat migrasi 20260913101045 dst.) tapi
-- storage.objects bisa saja tidak tersedia di sana. Dibungkus
-- `case … when … then … else skip(…) end` supaya plan() tetap stabil di
-- kedua lingkungan (pola resmi pgTAP untuk tes kondisional).
--
-- Jalankan: supabase test db

begin;
create extension if not exists pgtap with schema extensions;

select plan(16);

-- ── Data awal (sebagai postgres, melewati RLS) ──────────────────────────────

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
   'aaaaaaaa-0000-4000-8000-00000000000a', '2026-09-21', 'INCOME', 100000, 'ic1'),
  ('b0000000-0000-4000-8000-000000000001', '22222222-2222-4222-8222-222222222222',
   'bbbbbbbb-0000-4000-8000-00000000000b', '2026-09-21', 'INCOME', 100000, 'ic1');

-- ── Sebagai A: constraint tabel ──────────────────────────────────────────────
--
-- storage_path yang benar untuk baris pertama (id d…0001, mime image/jpeg)
-- dihitung dengan tangan: <user_id A>/<transaction_id A>/<id>.jpg —
-- persis transaction_attachments_path_check.

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into public.transaction_attachments
       (id, transaction_id, storage_path, file_name, mime_type, size_bytes)
     values (
       'd0000000-0000-4000-8000-000000000001',
       'a0000000-0000-4000-8000-000000000001',
       '11111111-1111-4111-8111-111111111111/a0000000-0000-4000-8000-000000000001/d0000000-0000-4000-8000-000000000001.jpg',
       'struk-a.jpg', 'image/jpeg', 123456
     ) $$,
  'lampiran A dengan storage_path yang benar tersimpan'
);

-- Tiga cara path bisa salah: folder pemilik keliru, folder transaksi keliru,
-- ekstensi tidak cocok mime_type — semuanya kena constraint yang sama.
-- id d…00ba dipakai berulang di baris-baris gagal ini: tidak pernah benar-
-- benar tersimpan, jadi tidak bentrok dengan baris valid di atas.

select throws_ok(
  $$ insert into public.transaction_attachments
       (id, transaction_id, storage_path, file_name, mime_type, size_bytes)
     values (
       'd0000000-0000-4000-8000-0000000000ba',
       'a0000000-0000-4000-8000-000000000001',
       '22222222-2222-4222-8222-222222222222/a0000000-0000-4000-8000-000000000001/d0000000-0000-4000-8000-0000000000ba.jpg',
       'salah.jpg', 'image/jpeg', 1000
     ) $$,
  '23514',
  'new row for relation "transaction_attachments" violates check constraint "transaction_attachments_path_check"',
  'path dengan folder pemilik B (padahal user_id sebenarnya A) ditolak'
);
select throws_ok(
  $$ insert into public.transaction_attachments
       (id, transaction_id, storage_path, file_name, mime_type, size_bytes)
     values (
       'd0000000-0000-4000-8000-0000000000ba',
       'a0000000-0000-4000-8000-000000000001',
       '11111111-1111-4111-8111-111111111111/b0000000-0000-4000-8000-000000000001/d0000000-0000-4000-8000-0000000000ba.jpg',
       'salah.jpg', 'image/jpeg', 1000
     ) $$,
  '23514',
  'new row for relation "transaction_attachments" violates check constraint "transaction_attachments_path_check"',
  'path menunjuk transaksi lain (padahal transaction_id sebenarnya transaksi A) ditolak'
);
select throws_ok(
  $$ insert into public.transaction_attachments
       (id, transaction_id, storage_path, file_name, mime_type, size_bytes)
     values (
       'd0000000-0000-4000-8000-0000000000ba',
       'a0000000-0000-4000-8000-000000000001',
       '11111111-1111-4111-8111-111111111111/a0000000-0000-4000-8000-000000000001/d0000000-0000-4000-8000-0000000000ba.png',
       'salah.jpg', 'image/jpeg', 1000
     ) $$,
  '23514',
  'new row for relation "transaction_attachments" violates check constraint "transaction_attachments_path_check"',
  'ekstensi .png untuk mime image/jpeg (seharusnya .jpg) ditolak'
);

-- mime image/gif: path sengaja diakhiri .webp (cabang ELSE di
-- transaction_attachments_path_check) supaya path_check lolos dan galat yang
-- muncul benar-benar dari mime_type_check, bukan tertimpa path_check.

select throws_ok(
  $$ insert into public.transaction_attachments
       (id, transaction_id, storage_path, file_name, mime_type, size_bytes)
     values (
       'd0000000-0000-4000-8000-0000000000ba',
       'a0000000-0000-4000-8000-000000000001',
       '11111111-1111-4111-8111-111111111111/a0000000-0000-4000-8000-000000000001/d0000000-0000-4000-8000-0000000000ba.webp',
       'salah.gif', 'image/gif', 1000
     ) $$,
  '23514',
  'new row for relation "transaction_attachments" violates check constraint "transaction_attachments_mime_type_check"',
  'mime image/gif ditolak (di luar JPEG/PNG/WebP)'
);

-- Ukuran: path .jpg tetap benar (mime image/jpeg), hanya size_bytes yang
-- melanggar batas 1..5242880.

select throws_ok(
  $$ insert into public.transaction_attachments
       (id, transaction_id, storage_path, file_name, mime_type, size_bytes)
     values (
       'd0000000-0000-4000-8000-0000000000ba',
       'a0000000-0000-4000-8000-000000000001',
       '11111111-1111-4111-8111-111111111111/a0000000-0000-4000-8000-000000000001/d0000000-0000-4000-8000-0000000000ba.jpg',
       'kosong.jpg', 'image/jpeg', 0
     ) $$,
  '23514',
  'new row for relation "transaction_attachments" violates check constraint "transaction_attachments_size_bytes_check"',
  'ukuran 0 byte ditolak'
);
select throws_ok(
  $$ insert into public.transaction_attachments
       (id, transaction_id, storage_path, file_name, mime_type, size_bytes)
     values (
       'd0000000-0000-4000-8000-0000000000ba',
       'a0000000-0000-4000-8000-000000000001',
       '11111111-1111-4111-8111-111111111111/a0000000-0000-4000-8000-000000000001/d0000000-0000-4000-8000-0000000000ba.jpg',
       'kebesaran.jpg', 'image/jpeg', 5242881
     ) $$,
  '23514',
  'new row for relation "transaction_attachments" violates check constraint "transaction_attachments_size_bytes_check"',
  'ukuran 5.242.881 byte (5 MB + 1) ditolak'
);

-- ── Sebagai B: isolasi antar-akun ────────────────────────────────────────────

select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-4222-8222-222222222222", "role": "authenticated"}', true);

select is(
  (select count(*)::integer from public.transaction_attachments),
  0,
  'B tidak melihat satu pun lampiran A'
);

-- storage_path memakai folder B sendiri (lolos path_check), tapi
-- transaction_id menunjuk transaksi A — RLS insert menolak karena transaksi
-- itu bukan milik B, bukan karena constraint path.

select throws_ok(
  $$ insert into public.transaction_attachments
       (id, transaction_id, storage_path, file_name, mime_type, size_bytes)
     values (
       'd0000000-0000-4000-8000-0000000000c0',
       'a0000000-0000-4000-8000-000000000001',
       '22222222-2222-4222-8222-222222222222/a0000000-0000-4000-8000-000000000001/d0000000-0000-4000-8000-0000000000c0.jpg',
       'nakal.jpg', 'image/jpeg', 1000
     ) $$,
  '42501', null,
  'B tidak bisa menambah lampiran yang menunjuk transaksi A'
);

-- ── Kebijakan storage.objects (kalau tabelnya ada) ──────────────────────────

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select case when to_regclass('storage.objects') is not null then
  lives_ok(
    $$ insert into storage.objects (bucket_id, name)
       values ('receipts',
         '11111111-1111-4111-8111-111111111111/a0000000-0000-4000-8000-000000000001/11111111-1111-4111-8111-1111111111aa.jpg') $$,
    'A mengunggah objek Storage di foldernya sendiri untuk transaksinya sendiri'
  )
  else skip('storage.objects tidak tersedia di lingkungan ini', 1)
end;

select case when to_regclass('storage.objects') is not null then
  throws_ok(
    $$ insert into storage.objects (bucket_id, name)
       values ('receipts',
         '22222222-2222-4222-8222-222222222222/a0000000-0000-4000-8000-000000000001/11111111-1111-4111-8111-1111111111ab.jpg') $$,
    '42501', null,
    'A tidak bisa mengunggah ke folder milik B'
  )
  else skip('storage.objects tidak tersedia di lingkungan ini', 1)
end;

select case when to_regclass('storage.objects') is not null then
  throws_ok(
    $$ insert into storage.objects (bucket_id, name)
       values ('receipts',
         '11111111-1111-4111-8111-111111111111/b0000000-0000-4000-8000-000000000001/11111111-1111-4111-8111-1111111111ac.jpg') $$,
    '42501', null,
    'A tidak bisa mengunggah ke foldernya sendiri untuk transaksi milik B'
  )
  else skip('storage.objects tidak tersedia di lingkungan ini', 1)
end;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-4222-8222-222222222222", "role": "authenticated"}', true);

select case when to_regclass('storage.objects') is not null then
  is(
    (select count(*)::integer from storage.objects
      where bucket_id = 'receipts'
        and name = '11111111-1111-4111-8111-111111111111/a0000000-0000-4000-8000-000000000001/11111111-1111-4111-8111-1111111111aa.jpg'),
    0,
    'B tidak melihat objek Storage milik A'
  )
  else skip('storage.objects tidak tersedia di lingkungan ini', 1)
end;

-- ── Cascade saat transaksi dihapus ───────────────────────────────────────────

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-4111-8111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ delete from public.transactions
      where id = 'a0000000-0000-4000-8000-000000000001' $$,
  'A menghapus transaksinya sendiri'
);
select is(
  (select count(*)::integer from public.transaction_attachments
    where transaction_id = 'a0000000-0000-4000-8000-000000000001'),
  0,
  'lampirannya ikut terhapus lewat cascade FK, tanpa perlu dihapus manual'
);

-- ── anon tidak punya hak apa pun ────────────────────────────────────────────

select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok(
  'select count(*) from public.transaction_attachments',
  '42501', null,
  'anon ditolak membaca transaction_attachments'
);

select * from finish();
rollback;
