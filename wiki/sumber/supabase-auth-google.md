---
title: Login with Google | Supabase Docs
description: Kutipan langkah menyiapkan OAuth client Google untuk Supabase Auth dan peringatan domain supabase.co di layar izin.
type: source
source_url: https://supabase.com/docs/guides/auth/social-login/auth-google
media_type: text/html
date_fetched: 2026-09-13
author: Supabase
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Hanya bagian yang dikutip wiki yang disimpan.

## Menyiapkan OAuth client

Jenis client:

> Create a new OAuth client ID and choose Web application for the application type.

Asal JavaScript:

> Under Authorized JavaScript origins add your application's URL. These should also be configured as the Site URL or redirect configuration in your project.

Alamat redirect:

> Under Authorized redirect URIs add your Supabase project's callback URL.

Setelah dibuat:

> Click Create and make sure you save the Client ID and Client Secret.

## Domain di layar izin Google

Tentang custom domain proyek Supabase:

> If you don't set this up, users will see <project-id>.supabase.co which does not inspire trust and can make your application more susceptible to successful phishing attempts.
