-- supabase/migrations/20260921145039_lampiran_struk.sql
--
-- Lampiran struk (#59): pengguna melampirkan foto struk (JPEG/PNG/WebP, maks
-- 5 MB) ke transaksinya, boleh lebih dari satu per transaksi. Berkas
-- sungguhan disimpan di Storage bucket privat `receipts`; tabel
-- transaction_attachments di bawah hanya menyimpan metadatanya. Klien
-- meminta signed URL (berlaku 1 jam) untuk menampilkan berkas — bucket tidak
-- pernah dibuka publik.
--
-- storage_path mengikuti pola <user_id>/<transaction_id>/<id>.<ekstensi>,
-- dipaksa oleh transaction_attachments_path_check di bawah supaya baris
-- metadata tidak pernah bisa menunjuk berkas milik orang lain. Kebijakan
-- storage.objects memakai pola path yang sama (folder pertama = pemilik,
-- folder kedua = transaksi) untuk memutuskan siapa boleh apa di bucket.
--
-- Risiko berkas yatim: menghapus transaksi men-cascade baris
-- transaction_attachments (FK on delete cascade), TAPI berkas sungguhan di
-- Storage tidak ikut terhapus — Storage bukan bagian dari transaksi
-- Postgres, dan migrasi ini sengaja tidak pernah menghapus baris dari
-- storage.objects lewat SQL. Klien WAJIB menghapus berkasnya lewat Storage
-- API terlebih dulu, baru menghapus transaksi/baris lampirannya; kalau
-- urutan itu terlewat, berkas tertinggal di bucket tanpa baris metadata yang
-- menunjuknya. Pembersihan berkas yatim di luar cakupan issue ini.
--
-- Nama constraint tabel adalah kontrak: klien Flutter memetakannya ke field
-- form, seperti pola di 20260921135322_validasi_transaksi.sql.

-- ── Storage bucket ────────────────────────────────────────────────────────────
--
-- Privat: hanya bisa dibaca lewat signed URL yang diminta klien setelah
-- kebijakan storage.objects di bawah mengizinkannya.

insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do update set public = false;

-- file_size_limit dan allowed_mime_types ditambahkan oleh migrasi milik
-- layanan Storage sendiri, dan memang ada di proyek cloud sungguhan. Tapi
-- `supabase db start` di CI hanya menjalankan container Postgres tanpa
-- layanan Storage, jadi skema storage di sana minimal dan kedua kolom itu
-- bisa saja tidak ada. Blok ini karena itu kondisional: kalau kedua kolom
-- ada, batas ukuran/tipe file diset lewat SQL dinamis; kalau tidak ada (CI),
-- migrasi tetap berhasil tanpa galat dan batas itu tidak berlaku di sana —
-- tidak masalah, CI tidak pernah sungguh-sungguh mengunggah berkas.
do $$
begin
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'storage' and table_name = 'buckets'
       and column_name = 'file_size_limit'
  ) and exists (
    select 1 from information_schema.columns
     where table_schema = 'storage' and table_name = 'buckets'
       and column_name = 'allowed_mime_types'
  ) then
    execute $sql$
      update storage.buckets
         set file_size_limit = 5242880,
             allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
       where id = 'receipts'
    $sql$;
  end if;
end;
$$;

-- ── Tabel lampiran ───────────────────────────────────────────────────────────

create table public.transaction_attachments (
  id             uuid primary key default gen_random_uuid(),
  transaction_id uuid not null
                 references public.transactions (id) on delete cascade,
  user_id        uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  storage_path   text not null,
  file_name      text not null
                 check (length(trim(file_name)) between 1 and 200),
  mime_type      text not null
                 check (mime_type in ('image/jpeg', 'image/png', 'image/webp')),
  size_bytes     integer not null
                 check (size_bytes between 1 and 5242880),
  created_at     timestamptz not null default now(),

  constraint transaction_attachments_storage_path_key unique (storage_path),

  -- Mengikat lokasi berkas ke pemilik/transaksi/baris ini sendiri, supaya
  -- tidak ada yang bisa mendaftarkan berkas milik orang lain sebagai
  -- lampirannya sendiri.
  constraint transaction_attachments_path_check
    check (
      storage_path = user_id::text || '/' || transaction_id::text || '/' || id::text || '.' ||
        (case mime_type
           when 'image/jpeg' then 'jpg'
           when 'image/png'  then 'png'
           else 'webp'
         end)
    )
);

comment on table public.transaction_attachments is
  'Lampiran struk per transaksi (JPEG/PNG/WebP, maks 5 MB). Berkas sungguhan ada di Storage bucket receipts; baris ini hanya metadatanya.';
comment on constraint transaction_attachments_path_check on public.transaction_attachments is
  'storage_path harus <user_id>/<transaction_id>/<id>.<ekstensi sesuai mime_type> — mengikat berkas ke pemiliknya sendiri.';

create index transaction_attachments_transaction_created_idx
  on public.transaction_attachments (transaction_id, created_at);

-- ── Hak akses & Row Level Security ───────────────────────────────────────────

alter table public.transaction_attachments enable row level security;

revoke all on table public.transaction_attachments from anon, authenticated;
grant select, insert, delete on table public.transaction_attachments to authenticated;

create policy "Pengguna melihat lampirannya sendiri"
  on public.transaction_attachments for select to authenticated
  using ((select auth.uid()) = user_id);

-- Lampiran hanya boleh menempel ke transaksi milik pengguna yang sama.
create policy "Pengguna menambah lampiran untuk transaksinya sendiri"
  on public.transaction_attachments for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.transactions t
      where t.id = transaction_id
        and t.user_id = (select auth.uid())
    )
  );

create policy "Pengguna menghapus lampirannya sendiri"
  on public.transaction_attachments for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Tidak ada kebijakan update: lampiran diganti dengan menghapus lalu
-- mengunggah ulang, bukan disunting di tempat.

-- ── Kebijakan Storage ────────────────────────────────────────────────────────
--
-- storage.objects sudah punya RLS menyala bawaan Supabase — tabelnya tidak
-- disentuh di sini, hanya ditambah kebijakan. Nama diberi awalan "catatin: "
-- supaya tidak bentrok dengan kebijakan proyek lain di skema storage yang
-- sama; `drop policy if exists` dulu supaya migrasi ini aman dijalankan
-- ulang.
--
-- Path objek di bucket receipts sama polanya dengan storage_path di atas
-- (<user_id>/<transaction_id>/<file>); storage.foldername(name) memecahnya
-- jadi array folder, elemen [1] pemilik dan [2] transaksi.

drop policy if exists "catatin: pengguna melihat lampirannya sendiri" on storage.objects;
create policy "catatin: pengguna melihat lampirannya sendiri"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "catatin: pengguna mengunggah lampiran untuk transaksinya sendiri" on storage.objects;
create policy "catatin: pengguna mengunggah lampiran untuk transaksinya sendiri"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1
      from public.transactions t
      where t.id::text = (storage.foldername(name))[2]
        and t.user_id = (select auth.uid())
    )
  );

drop policy if exists "catatin: pengguna menghapus lampirannya sendiri" on storage.objects;
create policy "catatin: pengguna menghapus lampirannya sendiri"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Tidak ada kebijakan update: berkas diganti dengan menghapus lalu
-- mengunggah ulang, sama seperti tabel metadatanya.
