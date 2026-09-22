-- supabase/migrations/20260922114814_pengerasan_validasi.sql
--
-- Pengerasan validasi input (#115). Nominal nol/negatif (skema awal) dan
-- tanggal di luar 2000–2099 (#40) sudah ditolak. Yang tersisa:
--
-- 1. Kepemilikan lintas tabel selama ini HANYA dijaga RLS. RLS tidak berlaku
--    bagi pemilik tabel maupun fungsi SECURITY DEFINER
--    (issue_recurring_transactions, dipanggil pg_cron), jadi satu bug di jalur
--    itu bisa menempelkan transaksi ke usaha, templat, atau lampiran milik
--    akun lain. FK komposit (…, user_id) membuat baris seperti itu mustahil
--    disimpan oleh peran apa pun. RLS tetap lapis pertama: lewat PostgREST
--    pelanggarannya tetap 42501, FK ini lapis kedua.
-- 2. Kolom teks bebas tanpa batas panjang — satu permintaan bisa menyimpan
--    megabyte teks di catatan transaksi.
-- 3. NPWP boleh berisi karakter apa saja.
--
-- Nama constraint adalah kontrak: klien memetakannya ke field form di
-- _constraintFields (app/lib/core/network/supabase_client.dart), dan
-- supabase/tests/database/07_pengerasan_validasi.test.sql menjaganya persis.
--
-- Diperiksa 22 Sep 2026: tidak ada baris di produksi maupun staging yang
-- melanggar constraint baru di bawah.

-- ── 1. Kepemilikan ───────────────────────────────────────────────────────────
--
-- MATCH SIMPLE (bawaan): FK komposit tidak diperiksa kalau salah satu
-- kolomnya null — itulah yang diinginkan untuk recurring_template_id.

alter table public.business_profiles
  add constraint business_profiles_id_user_id_key unique (id, user_id);

alter table public.transactions
  add constraint transactions_business_owner_fkey
    foreign key (business_id, user_id)
    references public.business_profiles (id, user_id) on delete cascade;

alter table public.recurring_templates
  add constraint recurring_templates_business_owner_fkey
    foreign key (business_id, user_id)
    references public.business_profiles (id, user_id) on delete cascade;

alter table public.recurring_templates
  add constraint recurring_templates_id_user_id_key unique (id, user_id);

-- Kolom SET NULL disebut eksplisit (Postgres 15+): menghapus templat hanya
-- memutus tautannya, user_id transaksi tidak ikut dikosongkan.
alter table public.transactions
  add constraint transactions_recurring_owner_fkey
    foreign key (recurring_template_id, user_id)
    references public.recurring_templates (id, user_id)
    on delete set null (recurring_template_id);

alter table public.transactions
  add constraint transactions_id_user_id_key unique (id, user_id);

alter table public.transaction_attachments
  add constraint transaction_attachments_transaction_owner_fkey
    foreign key (transaction_id, user_id)
    references public.transactions (id, user_id) on delete cascade;

comment on constraint transactions_business_owner_fkey on public.transactions is
  'Transaksi hanya boleh menempel ke usaha milik akun yang sama — juga untuk peran yang melewati RLS (#115).';
comment on constraint recurring_templates_business_owner_fkey on public.recurring_templates is
  'Templat hanya boleh menempel ke usaha milik akun yang sama — juga untuk peran yang melewati RLS (#115).';
comment on constraint transactions_recurring_owner_fkey on public.transactions is
  'Transaksi berulang hanya boleh bertaut ke templat milik akun yang sama (#115).';
comment on constraint transaction_attachments_transaction_owner_fkey on public.transaction_attachments is
  'Lampiran hanya boleh menempel ke transaksi milik akun yang sama — juga untuk peran yang melewati RLS (#115).';

-- ── 2. Panjang teks ──────────────────────────────────────────────────────────
--
-- char_length(null) = null, dan CHECK yang bernilai null lolos — kolom
-- opsional tetap boleh kosong tanpa `is null or`.

alter table public.transactions
  add constraint transactions_description_length_check
    check (char_length(description) <= 500),
  add constraint transactions_receipt_note_length_check
    check (char_length(receipt_note) <= 500);

alter table public.recurring_templates
  add constraint recurring_templates_description_length_check
    check (char_length(description) <= 500);

alter table public.business_profiles
  add constraint business_profiles_business_name_length_check
    check (char_length(business_name) <= 100),
  add constraint business_profiles_owner_name_length_check
    check (char_length(owner_name) <= 100),
  add constraint business_profiles_business_type_length_check
    check (char_length(business_type) <= 100);

-- ── 3. NPWP ──────────────────────────────────────────────────────────────────
--
-- Hanya bentuk karakternya: angka, titik, dan tanda hubung — sesuai
-- _NpwpFormatter di layar profil usaha ("00.000.000.0-000.000"). Jumlah digit
-- (15 lama / 16 berbasis NIK) sengaja TIDAK dikunci di sini; itu keputusan
-- domain pajak, bukan validasi input. Klien mengirim null untuk NPWP kosong.

alter table public.business_profiles
  add constraint business_profiles_npwp_format_check
    check (npwp ~ '^[0-9.-]{1,30}$');
