---
title: Row Level Security | Supabase Docs — bagian auth.jwt()
description: Secure your data using Postgres Row Level Security.
type: source
source_url: https://supabase.com/docs/guides/database/postgres/row-level-security
media_type: text/html
date_fetched: 2026-09-15
author: Supabase
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Kutipan bagian *Helper functions → `auth.jwt()`* halaman Row Level Security dokumentasi Supabase, diambil lewat pencarian dokumentasi resmi (konektor Supabase) pada 2026-09-15. Kata per kata; `[…]` menandai bagian yang dilewati. Dokumentasi Supabase berlisensi Apache-2.0.

> Not all information present in the JWT should be used in RLS policies. For instance, creating an RLS policy that relies on the `user_metadata` claim can create security issues in your application as this information can be modified by authenticated end users.
>
> Returns the JWT of the user making the request. Anything that you store in the user's `raw_app_meta_data` column or the `raw_user_meta_data` column will be accessible using this function. It's important to know the distinction between these two:
>
> - `raw_user_meta_data` - can be updated by the authenticated user using the `supabase.auth.update()` function. It is not a good place to store authorization data.
> - `raw_app_meta_data` - cannot be updated by the user, so it's a good place to store authorization data.
>
> […]
>
> Keep in mind that a JWT is not always "fresh". In the example above, even if you remove a user from a team and update the `app_metadata` field, that will not be reflected using `auth.jwt()` until the user's JWT is refreshed.
