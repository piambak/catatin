---
title: supabase/setup-cli — Supabase CLI Action README
description: This composite action sets up the Supabase CLI on GitHub's hosted Actions runners.
type: source
source_url: https://github.com/supabase/setup-cli
media_type: text/markdown
date_fetched: 2026-09-15
author: Supabase
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Kutipan README repo `supabase/setup-cli` (rilis terbaru saat diambil: v3.0.0), dibaca lewat GitHub REST API pada 2026-09-15. Hanya bagian yang dirujuk wiki, kata per kata; `[…]` menandai bagian yang dilewati. Repo berlisensi MIT.

> A fixed npm-published version, `latest`, or `beta` of the `supabase` CLI can be installed:
>
> ```yaml
> steps:
>   - uses: supabase/setup-cli@v3
>     with:
>       version: 2.84.2
> ```
>
> […]
>
> Run `supabase db start` to execute all migrations on a fresh database:
>
> ```yaml
> steps:
>   - uses: supabase/setup-cli@v3
>     with:
>       version: latest
>   - run: supabase init
>   - run: supabase db start
> ```
>
> […]
>
> | Name      | Type   | Description                                                      | Default                           | Required |
> | --------- | ------ | ---------------------------------------------------------------- | --------------------------------- | -------- |
> | `version` | String | Supabase CLI `latest`, `beta`, or fixed version published to npm | Root lockfile version or `latest` | false    |
