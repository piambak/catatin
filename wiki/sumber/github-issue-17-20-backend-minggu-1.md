---
title: "Issue #17–#20 tugas Backend Minggu 1 · piambak/catatin"
description: "Kutipan issue GitHub #17 (repo API, CI, staging), #18 (mock server kontrak), #19 (PR kontrak transaksi), dan #20 (skema mesin tarif): isi issue, komentar penugasan PO, dan judul issue lanjutan yang merujuknya."
type: source
source_url: https://github.com/piambak/catatin/issues/17
media_type: text/markdown
date_fetched: 2026-09-15
author: piambak (PO)
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Hanya isi issue dan komentar penugasan yang disimpan; label dan kolom Projects tidak ikut. Diambil lewat GitHub REST API (`gh api`) pada 2026-09-15, sebelum issue dikerjakan. Spasi di akhir baris dibuang supaya lolos markdownlint — selain itu kata per kata.

## Issue #17 — catatin-api repo + basic CI (lint, test, build) + staging environment

Sumber: <https://github.com/piambak/catatin/issues/17>, dibuka @piambak 2026-09-14T11:59:18Z.

Isi issue:

> **Type:** Task
> **Week:** 1
> **Phase:** Decisions & hotfixes
> **Role:** BE
> **Start:** 2026-09-14
> **Due:** 2026-09-18
>
> **Notes:** URL logged in wiki/arsitektur/backend-dan-api.md §1

Komentar penugasan, @piambak, 2026-09-14T13:51:38Z:

> **@mochrifzal — this one is yours (BE).**
>
> **What to do:** catatin-api repo + basic CI (lint, test, build) + staging environment
>
> **Note:** URL logged in wiki/arsitektur/backend-dan-api.md §1

## Issue #18 — Contract mock server from the sample JSON in wiki/arsitektur/backend-dan-api.md (Prism/OpenAPI or json-server), running on staging

Sumber: <https://github.com/piambak/catatin/issues/18>, dibuka @piambak 2026-09-14T11:59:20Z.

Isi issue:

> **Type:** Task
> **Week:** 1
> **Phase:** Decisions & hotfixes
> **Role:** BE
> **Start:** 2026-09-14
> **Due:** 2026-09-18
>
> **Notes:** Every endpoint in wiki/arsitektur/backend-dan-api.md returns its sample; FE confirms login -> dashboard -> transaction works in hybrid mode starting Friday

Komentar penugasan, @piambak, 2026-09-14T13:52:15Z:

> **@mochrifzal — this one is yours (BE).**
>
> **What to do:** Contract mock server from the sample JSON in wiki/arsitektur/backend-dan-api.md (Prism/OpenAPI or json-server), running on staging
>
> **Note:** Every endpoint in wiki/arsitektur/backend-dan-api.md returns its sample; FE confirms login -> dashboard -> transaction works in hybrid mode starting Friday

## Issue #19 — Contract PRs: PATCH /transactions/{id} (T-20), GET /transactions?from=&to= date range (T-21), GET /transactions/aggregate?year=, consistent error shape

Sumber: <https://github.com/piambak/catatin/issues/19>, dibuka @piambak 2026-09-14T12:01:13Z.

Isi issue:

> **Type:** Task
> **Week:** 1
> **Phase:** Decisions & hotfixes
> **Role:** BE
> **Start:** 2026-09-14
> **Due:** 2026-09-18

Komentar penugasan, @piambak, 2026-09-14T13:52:47Z:

> **@mochrifzal — this one is yours (BE).**
>
> **What to do:** Contract PRs: PATCH /transactions/{id} (T-20), GET /transactions?from=&to= date range (T-21), GET /transactions/aggregate?year=, consistent error shape

## Issue #20 — Design a config-driven tax rate engine schema

Sumber: <https://github.com/piambak/catatin/issues/20>, dibuka @piambak 2026-09-14T12:01:15Z. Judul lengkap: "Design a config-driven tax rate engine schema: tax_rates(version, effective_from, kind, tier_min, tier_max, rate, category) + ptkp(status, amount, version) table; draft in wiki/arsitektur/backend-dan-api.md §7 for TAX to review".

Isi issue:

> **Type:** Task
> **Week:** 1
> **Phase:** Decisions & hotfixes
> **Role:** BE
> **Start:** 2026-09-14
> **Due:** 2026-09-18

Komentar penugasan, @piambak, 2026-09-14T13:54:03Z:

> **@mochrifzal — this one is yours (BE).**
>
> **What to do:** Design a config-driven tax rate engine schema: tax_rates(version, effective_from, kind, tier_min, tier_max, rate, category) + ptkp(status, amount, version) table; draft in wiki/arsitektur/backend-dan-api.md §7 for TAX to review

## Judul issue lanjutan yang dirujuk

Judul kata per kata issue lain yang bergantung pada #17–#20 atau menjelaskan penomorannya, dibaca lewat `gh api` pada 2026-09-15. Isi dan komentarnya tidak disimpan.

- **#21** (open, dibuka @piambak 2026-09-14T12:01:17Z): wiki/domain/pajak/spek-pph21-ter.md: full TER tables A, B, C (PMK 168/2023), PTKP status -> category mapping, job-related expense deduction, what's allowed to be shown (D-10) - unblocks T-1 & T-4
- **#36** (open, dibuka @piambak 2026-09-14T12:03:53Z): T-20b: TxEditSheet._save calls AccountingService.updateTransaction() (Week 1 contract) - or hide the Edit button until the endpoint exists
- **#38** (open, dibuka @piambak 2026-09-14T12:03:57Z): Thursday cross-QA: test every mock-server endpoint in hybrid mode -> file contract issues
- **#41** (open, dibuka @piambak 2026-09-14T12:04:15Z): Monthly aggregate endpoint GET /transactions/aggregate?year= (income/expense/COGS per month, YTD revenue) - basis for Week 5 Simulator; test with 12 months of data
- **#42** (open, dibuka @piambak 2026-09-14T12:04:17Z): Tax rate config table (Week 1 schema) loaded from wiki/domain/pajak/spek-*.md; endpoint GET /tax/config?version= (read-only for now)
- **#43** (open, dibuka @piambak 2026-09-14T12:04:19Z): Automatic staging deploy from the api repo's main; wiki/arsitektur/backend-dan-api.md updated: every endpoint has a real example from staging
- **#45** (open, dibuka @piambak 2026-09-14T12:04:39Z): Review BE's tax rate config schema: can everything in the SPEC be represented (category, tiers, effective dates)
- **#88** (open, dibuka @piambak 2026-09-14T12:14:46Z): Full tax-rate engine: POST /tax/calculate (PPh Final & PPh 21 TER) reads versioned config, not hardcoded; result includes scheme, legal_basis, config_version
- **#91** (open, dibuka @piambak 2026-09-14T12:15:01Z): PATCH /tax/config endpoint for TAX (admin role) + version history
- **#131** (open, dibuka @piambak 2026-09-14T12:18:25Z): Fill in wiki/domain/pajak/sign-off.md per topic (PPh Final, PPh 21 TER, calendar, [VAT]) with the config version
