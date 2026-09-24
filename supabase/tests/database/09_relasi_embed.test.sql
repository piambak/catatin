-- supabase/tests/database/09_relasi_embed.test.sql
--
-- Relasi yang dipakai klien untuk menyematkan kategori. `transactions` dan
-- `recurring_templates` masing-masing punya DUA relasi ke `tx_categories`:
-- `category_id` dan komposit `(category_id, type)` (#40, #58). Tanpa petunjuk,
-- PostgREST menolak `category:tx_categories(*)` dengan `300 PGRST201`, jadi
-- `supabase_repositories.dart` menyebut nama FK satu kolom secara eksplisit
-- (`_txWithCategory`, `_recurringWithCategory`). Tes ini menjaga nama dan
-- bentuk FK itu: kalau diganti, ubah konstanta di klien bersamaan.
--
-- Jalankan: supabase test db

begin;
create extension if not exists pgtap with schema extensions;

select plan(2);

select ok(
  exists (
    select 1
      from pg_constraint c
     where c.conrelid = 'public.transactions'::regclass
       and c.conname = 'transactions_category_id_fkey'
       and c.contype = 'f'
       and c.confrelid = 'public.tx_categories'::regclass
       and c.conkey = array[(
             select attnum from pg_attribute
              where attrelid = 'public.transactions'::regclass
                and attname = 'category_id')]
       and c.confkey = array[(
             select attnum from pg_attribute
              where attrelid = 'public.tx_categories'::regclass
                and attname = 'id')]
  ),
  'transactions_category_id_fkey: FK satu kolom category_id -> tx_categories(id), dirujuk _txWithCategory'
);

select ok(
  exists (
    select 1
      from pg_constraint c
     where c.conrelid = 'public.recurring_templates'::regclass
       and c.conname = 'recurring_templates_category_id_fkey'
       and c.contype = 'f'
       and c.confrelid = 'public.tx_categories'::regclass
       and c.conkey = array[(
             select attnum from pg_attribute
              where attrelid = 'public.recurring_templates'::regclass
                and attname = 'category_id')]
       and c.confkey = array[(
             select attnum from pg_attribute
              where attrelid = 'public.tx_categories'::regclass
                and attname = 'id')]
  ),
  'recurring_templates_category_id_fkey: FK satu kolom category_id -> tx_categories(id), dirujuk _recurringWithCategory'
);

select * from finish();
rollback;
