-- supabase/tests/database/01_skema.test.sql
--
-- Bentuk skema dan hak akses yang keamanan Catatin bergantung padanya: tabel
-- ada, RLS menyala, `anon` tidak punya hak apa pun, `authenticated` hanya hak
-- yang diberikan migrasi, dan kebijakan RLS persis yang tertulis di migrasi.
--
-- Kalau tes ini gagal setelah migrasi baru, periksa dulu apakah perubahannya
-- disengaja — lalu perbarui tes DAN wiki/arsitektur/supabase.md §3.
--
-- Jalankan: supabase test db   (butuh `supabase start` atau `supabase db start`)

begin;
create extension if not exists pgtap with schema extensions;

select plan(64);

-- ── Tabel ────────────────────────────────────────────────────────────────────

select has_table('public', 'tx_categories', 'tabel tx_categories ada');
select has_table('public', 'business_profiles', 'tabel business_profiles ada');
select has_table('public', 'transactions', 'tabel transactions ada');
select has_table('public', 'recurring_templates', 'tabel recurring_templates ada');
select has_table('public', 'transaction_attachments', 'tabel transaction_attachments ada');

select is(
  (select count(*)::integer from public.tx_categories),
  15,
  '15 kategori transaksi diisi migrasi (bukan seed)'
);

-- ── Row Level Security ───────────────────────────────────────────────────────

select ok(
  (select relrowsecurity from pg_class where oid = 'public.tx_categories'::regclass),
  'RLS menyala di tx_categories'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.business_profiles'::regclass),
  'RLS menyala di business_profiles'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.transactions'::regclass),
  'RLS menyala di transactions'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.recurring_templates'::regclass),
  'RLS menyala di recurring_templates'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.transaction_attachments'::regclass),
  'RLS menyala di transaction_attachments'
);

select policies_are(
  'public', 'tx_categories',
  array['Kategori bisa dibaca pengguna yang masuk'],
  'kebijakan tx_categories persis sesuai migrasi'
);
select policies_are(
  'public', 'business_profiles',
  array[
    'Pengguna melihat profil usahanya sendiri',
    'Pengguna membuat profil usahanya sendiri',
    'Pengguna mengubah profil usahanya sendiri',
    'Pengguna menghapus profil usahanya sendiri'
  ],
  'kebijakan business_profiles persis sesuai migrasi'
);
select policies_are(
  'public', 'transactions',
  array[
    'Pengguna melihat transaksinya sendiri',
    'Pengguna mencatat transaksi untuk usahanya sendiri',
    'Pengguna mengubah transaksinya sendiri',
    'Pengguna menghapus transaksinya sendiri'
  ],
  'kebijakan transactions persis sesuai migrasi'
);
select policies_are(
  'public', 'recurring_templates',
  array[
    'Pengguna melihat templat berulang miliknya sendiri',
    'Pengguna membuat templat berulang untuk usahanya sendiri',
    'Pengguna mengubah templat berulang miliknya sendiri'
  ],
  'kebijakan recurring_templates persis sesuai migrasi'
);
select policies_are(
  'public', 'transaction_attachments',
  array[
    'Pengguna melihat lampirannya sendiri',
    'Pengguna menambah lampiran untuk transaksinya sendiri',
    'Pengguna menghapus lampirannya sendiri'
  ],
  'kebijakan transaction_attachments persis sesuai migrasi'
);

-- ── Hak tabel ────────────────────────────────────────────────────────────────
--
-- Postgres memeriksa hak tabel sebelum RLS: hak yang bocor ke `anon` berarti
-- tamu tanpa sesi bisa menembak tabel dengan publishable key.

select table_privs_are('public', 'tx_categories', 'anon', array[]::text[],
  'anon tanpa hak di tx_categories');
select table_privs_are('public', 'business_profiles', 'anon', array[]::text[],
  'anon tanpa hak di business_profiles');
select table_privs_are('public', 'transactions', 'anon', array[]::text[],
  'anon tanpa hak di transactions');
select table_privs_are('public', 'recurring_templates', 'anon', array[]::text[],
  'anon tanpa hak di recurring_templates');
select table_privs_are('public', 'transaction_attachments', 'anon', array[]::text[],
  'anon tanpa hak di transaction_attachments');

select table_privs_are('public', 'tx_categories', 'authenticated',
  array['SELECT'],
  'authenticated hanya membaca tx_categories');
select table_privs_are('public', 'business_profiles', 'authenticated',
  array['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
  'authenticated: CRUD business_profiles (dibatasi RLS)');
select table_privs_are('public', 'transactions', 'authenticated',
  array['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
  'authenticated: CRUD transactions (dibatasi RLS)');
select table_privs_are('public', 'recurring_templates', 'authenticated',
  array['SELECT', 'INSERT', 'UPDATE'],
  'authenticated: baca/buat/ubah recurring_templates, tanpa delete (dibatasi RLS)');
select table_privs_are('public', 'transaction_attachments', 'authenticated',
  array['SELECT', 'INSERT', 'DELETE'],
  'authenticated: baca/tambah/hapus transaction_attachments, tanpa update (dibatasi RLS)');

-- ── Fungsi ───────────────────────────────────────────────────────────────────

select has_function('public', 'monthly_totals', array['integer'],
  'fungsi monthly_totals(integer) ada');
select isnt_definer('public', 'monthly_totals', array['integer'],
  'monthly_totals security invoker, jadi RLS tetap berlaku');
select function_privs_are('public', 'monthly_totals', array['integer'], 'anon',
  array[]::text[], 'anon tidak bisa memanggil monthly_totals');
select function_privs_are('public', 'monthly_totals', array['integer'],
  'authenticated', array['EXECUTE'], 'authenticated bisa memanggil monthly_totals');

select has_function('public', 'has_password', array[]::text[],
  'fungsi has_password() ada');
select is_definer('public', 'has_password', array[]::text[],
  'has_password security definer (satu-satunya, lihat migrasinya)');
select function_privs_are('public', 'has_password', array[]::text[], 'anon',
  array[]::text[], 'anon tidak bisa memanggil has_password');
select function_privs_are('public', 'has_password', array[]::text[],
  'authenticated', array['EXECUTE'], 'authenticated bisa memanggil has_password');

-- Transaksi berulang (#58).

select has_function('public', 'catatin_hari_ini', array[]::text[],
  'fungsi catatin_hari_ini() ada');
select isnt_definer('public', 'catatin_hari_ini', array[]::text[],
  'catatin_hari_ini security invoker');
select function_privs_are('public', 'catatin_hari_ini', array[]::text[], 'anon',
  array[]::text[], 'anon tidak bisa memanggil catatin_hari_ini');
select function_privs_are('public', 'catatin_hari_ini', array[]::text[],
  'authenticated', array['EXECUTE'], 'authenticated bisa memanggil catatin_hari_ini');

select has_function('public', 'recurring_occurrence', array['date', 'text', 'integer'],
  'fungsi recurring_occurrence(date, text, integer) ada');
select isnt_definer('public', 'recurring_occurrence', array['date', 'text', 'integer'],
  'recurring_occurrence security invoker');
select function_privs_are('public', 'recurring_occurrence', array['date', 'text', 'integer'],
  'anon', array[]::text[], 'anon tidak bisa memanggil recurring_occurrence');
select function_privs_are('public', 'recurring_occurrence', array['date', 'text', 'integer'],
  'authenticated', array['EXECUTE'], 'authenticated bisa memanggil recurring_occurrence');

select has_function('public', 'recurring_first_on_or_after', array['date', 'text', 'date'],
  'fungsi recurring_first_on_or_after(date, text, date) ada');
select isnt_definer('public', 'recurring_first_on_or_after', array['date', 'text', 'date'],
  'recurring_first_on_or_after security invoker');
select function_privs_are('public', 'recurring_first_on_or_after', array['date', 'text', 'date'],
  'anon', array[]::text[], 'anon tidak bisa memanggil recurring_first_on_or_after');
select function_privs_are('public', 'recurring_first_on_or_after', array['date', 'text', 'date'],
  'authenticated', array['EXECUTE'], 'authenticated bisa memanggil recurring_first_on_or_after');

select has_function('public', 'issue_recurring_transactions', array['date', 'uuid'],
  'fungsi issue_recurring_transactions(date, uuid) ada');
select is_definer('public', 'issue_recurring_transactions', array['date', 'uuid'],
  'issue_recurring_transactions security definer (menembus RLS untuk menulis transaksi lintas pengguna)');
select function_privs_are('public', 'issue_recurring_transactions', array['date', 'uuid'],
  'anon', array[]::text[], 'anon tidak bisa memanggil issue_recurring_transactions');
select function_privs_are('public', 'issue_recurring_transactions', array['date', 'uuid'],
  'authenticated', array[]::text[],
  'authenticated tidak bisa memanggil issue_recurring_transactions langsung');

select has_function('public', 'recurring_templates_before_write', array[]::text[],
  'fungsi trigger recurring_templates_before_write() ada');
select isnt_definer('public', 'recurring_templates_before_write', array[]::text[],
  'recurring_templates_before_write security invoker');
select function_privs_are('public', 'recurring_templates_before_write', array[]::text[],
  'anon', array[]::text[], 'anon tidak bisa memanggil recurring_templates_before_write');
select function_privs_are('public', 'recurring_templates_before_write', array[]::text[],
  'authenticated', array[]::text[],
  'authenticated tidak bisa memanggil recurring_templates_before_write langsung');

select has_function('public', 'recurring_templates_after_write', array[]::text[],
  'fungsi trigger recurring_templates_after_write() ada');
select is_definer('public', 'recurring_templates_after_write', array[]::text[],
  'recurring_templates_after_write security definer (memanggil issue_recurring_transactions)');
select function_privs_are('public', 'recurring_templates_after_write', array[]::text[],
  'anon', array[]::text[], 'anon tidak bisa memanggil recurring_templates_after_write');
select function_privs_are('public', 'recurring_templates_after_write', array[]::text[],
  'authenticated', array[]::text[],
  'authenticated tidak bisa memanggil recurring_templates_after_write langsung');

select has_function('public', 'transactions_recurring_guard', array[]::text[],
  'fungsi trigger transactions_recurring_guard() ada');
select isnt_definer('public', 'transactions_recurring_guard', array[]::text[],
  'transactions_recurring_guard security invoker');
select function_privs_are('public', 'transactions_recurring_guard', array[]::text[],
  'anon', array[]::text[], 'anon tidak bisa memanggil transactions_recurring_guard');
select function_privs_are('public', 'transactions_recurring_guard', array[]::text[],
  'authenticated', array[]::text[],
  'authenticated tidak bisa memanggil transactions_recurring_guard langsung');

select is(
  (select array_agg(p.proname::text order by p.proname)
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosecdef),
  array['has_password', 'issue_recurring_transactions', 'recurring_templates_after_write'],
  'tidak ada fungsi security definer lain di skema public'
);

select is(
  (select p.proconfig
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'has_password'),
  array['search_path=""'],
  'has_password memakai search_path kosong'
);

select * from finish();
rollback;
