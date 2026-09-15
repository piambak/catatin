---
title: supabase/cli — legacy-test-db.pg-prove-args.ts (v2.117.0)
description: Build the pg_prove command, volume binds, and working directory for a test db run.
type: source
source_url: https://github.com/supabase/cli/blob/v2.117.0/apps/cli/src/command-internal/legacy-test-db.pg-prove-args.ts
media_type: text/x-typescript
date_fetched: 2026-09-15
author: Supabase
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Kutipan kode sumber Supabase CLI pada tag `v2.117.0` — versi yang di-pin workflow `supabase.yml` — dibaca lewat GitHub REST API pada 2026-09-15. Menjelaskan argumen `pg_prove` dan folder yang di-mount ke container saat `supabase test db` dijalankan. Repo berlisensi MIT.

```typescript
/**
 * Build the `pg_prove` command, volume binds, and working directory for a
 * `test db` run.
 *
 * - No paths → default to `<workdir>/supabase/tests` (Go's `filepath.Abs(DbTestsDir)`
 *   after chdir to the project root).
 * - Relative paths resolve against `cwd` (Go's `utils.CurrentDirAbs`, the original
 *   invocation directory).
 *
 * Intentional divergence from Go (CLI-1139): for a file path we mount its parent
 * *directory* rather than the lone file, so psql `\ir`/`\i` includes resolve. Go
 * mounts the file alone, which breaks single-file runs that include a sibling.
 * Output is unchanged — the full file path is still passed to `pg_prove`.
 */
```

```typescript
  const cmd: string[] = ["pg_prove", "--ext", ".pg", "--ext", ".sql", "-r"];
```

```typescript
    // Mount the *directory* containing a test file (not the lone file) so psql
    // `\ir ./sibling.sql` includes resolve: they look relative to the test file's
    // own directory, and a single-file bind leaves siblings absent in the
    // container (CLI-1139). Directories are mounted as-is.
    const isFile = nodePath.posix.extname(dockerPath) !== "";
    const hostMount = isFile ? nodePath.dirname(fp) : fp;
```
