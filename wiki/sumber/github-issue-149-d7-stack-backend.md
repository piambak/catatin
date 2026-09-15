---
title: "Issue #149 Backend stack (BaaS vs. custom-built) + Issue #16 · piambak/catatin"
description: "Kutipan issue GitHub #149 (keputusan D-7, stack backend) dan #16 (tugas memutuskannya): isi issue, komentar penugasan PO, rationale lima baris, dan komentar penutup."
type: source
source_url: https://github.com/piambak/catatin/issues/149
media_type: text/markdown
date_fetched: 2026-09-15
author: piambak (PO), mochrifzal (BE)
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Hanya isi issue dan komentar yang menyangkut keputusan D-7 yang disimpan; label dan kolom Projects tidak ikut. Diambil lewat GitHub REST API (`gh api`) pada 2026-09-15 setelah kedua issue ditutup. Spasi di akhir baris dibuang dan URL polos dibungkus `<…>` supaya lolos markdownlint — selain itu kata per kata.

## Issue #149 — Backend stack (BaaS vs. custom-built)

Sumber: <https://github.com/piambak/catatin/issues/149>, dibuka @piambak 2026-09-14T12:20:02Z, ditutup 2026-09-15T14:41:16Z.

Isi issue:

> **Type:** Decision
> **Week:** None
> **Phase:**
> **Role:** BE -> PO
> **Start:** 2026-09-16
> **Due:** 2026-09-16
>
> **Notes:** Default: BaaS (Supabase)

Komentar penugasan, @piambak, 2026-09-14T13:55:50Z:

> **Role: BE -> PO — no single owner assigned; see the issue body for detail.**
>
> **What to do:** Backend stack (BaaS vs. custom-built)
>
> **Note:** Default: BaaS (Supabase)

Komentar keputusan, @mochrifzal, 2026-09-15T14:41:06Z (<https://github.com/piambak/catatin/issues/149#issuecomment-5682205925>):

> **D-7 decided: BaaS (Supabase)** — agreed with @piambak (PO), recorded by @mochrifzal (BE) for #16.
>
> 1. **Already live, zero migration:** since Sep 13 the public site runs on Supabase project `catatin` (Auth incl. Google login verified end-to-end, 3 RLS-protected tables, `monthly_totals`); custom-built would mean rebuilding auth/OAuth and migrating live accounts.
> 2. **Fits the team:** 1 BE for 9 weeks — no server, TLS, CORS, token rotation or hosting to own, so the time goes to the tax engine, aggregation and import/export.
> 3. **Roadmap maps onto the platform:** versioned tax config = Postgres tables + RLS admin role; receipts = Storage (per-bucket size/MIME limits, signed URLs); recurring transactions = `pg_cron`; tax engine & CSV = SQL/Edge Functions, tested with pgTAP against `wiki/domain/pajak/kasus-*.csv`.
> 4. **Accepted risks:** Free plan pauses after 1 idle week, has no automatic backups and caps active projects at 2 (prod + staging) — T-19 (Pro plan or keep-alive + manual backup) must be settled before M5; security lives in RLS, so every migration passes Security Advisor + isolation tests.
> 5. **Consequence:** REST-shaped tasks (#17, #18, #39, #43, #129) get re-scoped to Supabase equivalents (staging project + migrations in CI, `DATA_SOURCE=supabase`); the Dio `api` mode stays as a fallback, not the target.

## Issue #16 — Wednesday: decide D-7 with PO - write a 5-line rationale in the issue

Sumber: <https://github.com/piambak/catatin/issues/16>, dibuka @piambak 2026-09-14T11:58:33Z, ditutup 2026-09-15T14:41:14Z.

Isi issue:

> **Type:** Task
> **Week:** 1
> **Phase:** Decisions & hotfixes
> **Role:** BE
> **Start:** 2026-09-14
> **Due:** 2026-09-18

Komentar penugasan, @piambak, 2026-09-14T13:51:08Z:

> **@mochrifzal — this one is yours (BE).**
>
> **What to do:** Wednesday: decide D-7 with PO - write a 5-line rationale in the issue

Komentar penutup, @mochrifzal, 2026-09-15T14:41:12Z:

> D-7 decided with @piambak (PO): **BaaS (Supabase)**. The 5-line rationale is recorded on the decision issue: <https://github.com/piambak/catatin/issues/149#issuecomment-5682205925>
