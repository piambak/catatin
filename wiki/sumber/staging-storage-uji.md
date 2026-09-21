---
title: Uji bucket dan kebijakan Storage lampiran di catatin-staging (21 Sep 2026)
description: "Hasil menjalankan migrasi lampiran struk di proyek staging dalam transaksi yang digulung balik: setelan bucket, kebijakan storage.objects, dan penolakan hapus langsung."
type: source
source_url: https://herafvadqziftszhxqeq.supabase.co/storage/v1/
media_type: text/plain
date_fetched: 2026-09-21
author: BE Catatin
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Migrasi `20260921145039_lampiran_struk` dijalankan di proyek Supabase staging `catatin-staging` pada 2026-09-21 lewat konektor Supabase (`execute_sql`), dalam satu transaksi yang digagalkan di akhir dengan `raise exception`, sehingga tidak ada bucket, tabel, kebijakan, maupun akun uji yang tersisa (dicek sesudahnya: 0 bucket, 0 objek, tabel tidak ada, 0 kebijakan `catatin:`). Pengguna fiktif A dan B masing-masing punya satu transaksi; langkah 1–8 dijalankan sebagai `authenticated` dengan klaim JWT A, lalu B. Keluaran kata per kata:

```text
bucket: 5242880 image/jpeg,image/png,image/webp public=false
1 objek A di folder sendiri: OK
2 objek ke folder B: 42501
3 folder sendiri tx B: 42501
4 baris lampiran A: OK
5 path salah: 23514 transaction_attachments_path_check
6 A melihat objek: 1
7 B melihat objek A: 0, baris A: 0
8 B hapus: 42501 Direct deletion from storage tables is not allowed. Use the Storage API instead.
```

Langkah 8 menjalankan `delete from storage.objects where bucket_id = 'receipts'` sebagai B.
