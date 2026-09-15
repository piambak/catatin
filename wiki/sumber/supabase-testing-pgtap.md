---
title: Testing & linting database | Supabase Docs
description: Using the CLI to test your Supabase project — pgTAP, supabase test db, supabase db lint, and running database tests in CI.
type: source
source_url: https://supabase.com/docs/guides/local-development/testing/overview
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
Kutipan tiga halaman dokumentasi Supabase yang diambil lewat pencarian dokumentasi resmi (konektor Supabase) pada 2026-09-15. Hanya bagian yang dirujuk wiki yang disimpan, kata per kata; `[…]` menandai bagian yang dilewati. Dokumentasi Supabase berlisensi Apache-2.0 (repo `supabase/supabase`).

## Testing Overview

Sumber: <https://supabase.com/docs/guides/local-development/testing/overview>

> ### Database unit testing with pgTAP
>
> pgTAP is a unit testing framework for Postgres that allows testing:
>
> - Database structure: tables, columns, constraints
> - Row Level Security (RLS) policies
> - Functions and procedures
> - Data integrity
>
> […]
>
> ```sql
> -- as User 1
> set local role authenticated;
> set local request.jwt.claim.sub = '123e4567-e89b-12d3-a456-426614174000';
> ```
>
> […]
>
> ### Continuous integration testing
>
> Set up automated database testing in your CI pipeline:
>
> 1. Create a GitHub Actions workflow `.github/workflows/db-tests.yml`:
>
> ```yaml
> name: Database Tests
>
> on:
>   push:
>     branches: [main]
>   pull_request:
>     branches: [main]
>
> jobs:
>   test:
>     runs-on: ubuntu-latest
>
>     steps:
>       - uses: actions/checkout@v4
>
>       - name: Setup Supabase CLI
>         uses: supabase/setup-cli@v1
>
>       - name: Start Supabase
>         run: supabase start
>
>       - name: Run Tests
>         run: supabase test db
> ```
>
> […]
>
> 1. **Test Data Setup**
>     - Use begin and rollback to ensure test isolation
>     - Create realistic test data that covers edge cases
>     - Use different user roles and permissions in tests
>
> 2. **RLS Policy Testing**
>     - Test Create, Read, Update, Delete operations
>     - Test with different user roles: anonymous and authenticated
>     - Test edge cases and potential security bypasses
>     - Always test negative cases: what users should not be able to do

## Testing and linting

Sumber: <https://supabase.com/docs/guides/local-development/cli/testing-and-linting>

> The Supabase CLI provides Postgres linting using the `supabase test db` command.
>
> This is powered by the pgTAP extension.
>
> […]
>
> The Supabase CLI provides Postgres linting using the `supabase db lint` command
>
> This is powered by plpgsql_check, which leverages the internal Postgres parser/evaluator so you see any errors that would occur at runtime.

## CLI reference: supabase db lint

Sumber: <https://supabase.com/docs/reference/cli/supabase-db-lint>

> Runs `plpgsql_check` extension in the local Postgres container to check for errors in all schemas. The default lint level is `warning` and can be raised to error via the `--level` flag.
>
> […]
>
> The `--fail-on` flag can be used to control when the command should exit with a non-zero status code. The possible values are:
>
> - `none` (default): Always exit with a zero status code, regardless of lint results.
> - `warning`: Exit with a non-zero status code if any warnings or errors are found.
> - `error`: Exit with a non-zero status code only if errors are found.
