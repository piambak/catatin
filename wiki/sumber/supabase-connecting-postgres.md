---
title: Connect to your database — Supabase Docs
description: Connect to Postgres from your frontend, backend, or serverless environment
type: source
source_url: https://supabase.com/docs/guides/database/connecting-to-postgres
media_type: text/markdown
date_fetched: 2026-09-21
author: Supabase
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Kutipan berkas sumber dokumentasi `apps/docs/content/guides/database/connecting-to-postgres.mdx` di repo `supabase/supabase` (commit terakhir berkas itu `4f10a55`, 11 Sep 2026), dibaca lewat GitHub REST API pada 2026-09-21. Hanya bagian yang dirujuk wiki, kata per kata; `[…]` menandai bagian yang dilewati.

> | Where your code runs                                      | Use                                                         | Why                                                                                           |
> | --------------------------------------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
> | A frontend application                                    | Data API                                                    | Works over REST or GraphQL, so you don't need a Postgres client. Requires Row Level Security. |
> | A persistent backend on IPv6, or with the IPv4 add-on     | Direct connection                                           | No pooler in the path.                                                                        |
> | A persistent backend on an IPv4-only network              | Shared pooler, session mode                                 | The shared pooler is IPv4-only on every plan.                                                 |
> | Migrations, `pg_dump`, backup and restore, or replication | Direct connection                                           | These are single sessions and Postgres native commands.                                       |
>
> […]
>
> ## Direct connection
>
> […] Direct connections are on IPv6, or on IPv4 if the project has the IPv4 add-on. If your network is IPv4-only and you don't have the add-on, use session mode instead.
>
> ```txt
> postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
> ```
>
> ## Shared pooler, session mode
>
> The session mode connection string connects to your Postgres instance through the shared pooler. Use it as an alternative to a direct connection when you connect from an IPv4-only network.
>
> ```txt
> postgresql://postgres.[PROJECT-REF]:[YOUR-PASSWORD]@[POOLER-HOST]:5432/postgres
> ```
>
> Get this string from the Supabase Dashboard by clicking Connect and choosing **Session pooler**.
>
> […]
>
> ## Endpoints and IP versions
>
> | Mode                               | Host:Port                                       | Free | Paid | Paid + IPv4 add-on |
> | ---------------------------------- | ----------------------------------------------- | ---- | ---- | ------------------ |
> | Direct connection                  | `db.[PROJECT-REF].supabase.co:5432`             | IPv6 | IPv6 | IPv4               |
> | Shared pooler, session mode        | `aws-[INDEX]-[REGION].pooler.supabase.com:5432` | IPv4 | IPv4 | IPv4               |
> | Shared pooler, transaction mode    | `aws-[INDEX]-[REGION].pooler.supabase.com:6543` | IPv4 | IPv4 | IPv4               |
>
> `[INDEX]` in the shared pooler host is a pooler cluster index, not part of the region name. A region can have more than one, so you can't work out your host from your region. Copy the host from the Connect dialog.
>
> The username differs by connection type. Direct connections and the dedicated pooler use `postgres`. Shared pooler connections use `postgres.[PROJECT-REF]`. […]
>
> To connect over IPv4, you have two options. The shared pooler is IPv4-only on every plan, in both session and transaction mode. […]
