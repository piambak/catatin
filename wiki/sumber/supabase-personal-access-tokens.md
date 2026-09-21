---
title: Personal Access Tokens — Supabase Docs
description: Scope personal access tokens to specific organizations, projects, and permissions
type: source
source_url: https://supabase.com/docs/guides/platform/personal-access-tokens
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
Kutipan berkas sumber dokumentasi `apps/docs/content/guides/platform/personal-access-tokens.mdx` di repo `supabase/supabase` (commit terakhir berkas itu `2681a21`, 1 Sep 2026), dibaca lewat GitHub REST API pada 2026-09-21. Hanya bagian yang dirujuk wiki, kata per kata; `[…]` menandai bagian yang dilewati.

> Scoped personal access tokens are in **public alpha** and rolling out gradually. If you don't see the option to choose permissions when creating a token, your account doesn't have access yet. […]
>
> Personal access tokens (PATs) authenticate you to the Management API and the tools built on it, like the Supabase CLI and the MCP server. They come in two flavors:
>
> - **Classic tokens** carry your account's full access. That means every permission, on every organization and every project you belong to today, and on every one you create or join in the future. A classic token created a year ago can touch a project you created today.
> - **Scoped tokens** carry only the organizations, projects, and permissions you choose. For example: read one project's database and view its logs, with no access to billing or organization settings.
>
> We recommend scoped tokens for everything, especially AI agents, automation scripts, and CI environments. If a token leaks, the blast radius stays small.
