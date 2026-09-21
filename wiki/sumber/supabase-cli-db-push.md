---
title: supabase db push — bantuan CLI 2.117.0
description: Push new migrations to the remote database.
type: source
source_url: https://supabase.com/docs/reference/cli/supabase-db-push
media_type: text/plain
date_fetched: 2026-09-21
author: Supabase
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Keluaran `supabase db push --help` dan `supabase migration list --help` dari Supabase CLI **2.117.0** — versi yang dipatok `.github/workflows/supabase.yml` — dijalankan di mesin pengembang pada 2026-09-21. Hanya bagian yang dirujuk wiki, kata per kata; `[…]` menandai bagian yang dilewati.

```text
DESCRIPTION
  Push new migrations to the remote database. Vault secrets from config.toml are updated before migrations unless --skip-vault is set.

USAGE
  supabase db push [flags]

FLAGS
  --include-all            Include all migrations not found on remote history table.
  […]
  --dry-run                Print the migrations that would be applied, but don't actually apply them.
  --db-url string          Pushes to the database specified by the connection string (must be percent-encoded).
  --linked                 Pushes to the linked project.
  […]

GLOBAL FLAGS
  […]
  --yes                    answer yes to all prompts
  […]
```

```text
DESCRIPTION
  List local and remote migrations.

USAGE
  supabase migration list [flags]

FLAGS
  --db-url string          Lists migrations of the database specified by the connection string (must be percent-encoded).
  […]
```
