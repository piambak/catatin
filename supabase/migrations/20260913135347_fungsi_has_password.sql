-- supabase/migrations/20260913135347_fungsi_has_password.sql
--
-- Apakah akun yang sedang masuk sudah punya kata sandi.
--
-- Dipakai Pengaturan -> Cara masuk untuk menampilkan "Aktif" / "Belum
-- dipasang". Tidak bisa dibaca dari identitas akun: Supabase Auth hanya membuat
-- identitas `email` saat kata sandi pertama dipasang bila flag eksperimental
-- CreateEmailIdentityOnPasswordSetEnabled menyala, dan di proyek ini tidak.
--
-- security definer karena peran `authenticated` tidak boleh membaca
-- auth.users. Fungsinya hanya menjawab true/false untuk baris pemanggil sendiri
-- (auth.uid()), tidak pernah mengembalikan hash kata sandi, dan tidak menerima
-- parameter. search_path kosong mencegah pembajakan lewat objek bernama sama.
--
-- Security Advisor sengaja dibiarkan melaporkan lint 0029
-- (authenticated_security_definer_function_executable) untuk fungsi ini.

create or replace function public.has_password()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select u.encrypted_password is not null and u.encrypted_password <> ''
      from auth.users u
      where u.id = (select auth.uid())
    ),
    false
  );
$$;

comment on function public.has_password() is
  'true kalau akun yang sedang masuk punya kata sandi. Hanya membaca baris milik auth.uid().';

revoke execute on function public.has_password() from public, anon;
grant execute on function public.has_password() to authenticated;
