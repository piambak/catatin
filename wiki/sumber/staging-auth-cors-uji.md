---
title: Uji CORS dan refresh token di catatin-staging (21 Sep 2026)
description: "Keluaran curl terhadap Auth dan REST API proyek staging: header CORS preflight dan respons refresh token tanpa refresh token yang sah."
type: source
source_url: https://herafvadqziftszhxqeq.supabase.co/auth/v1/
media_type: text/plain
date_fetched: 2026-09-21
author: BE Catatin
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Keluaran `curl` terhadap proyek Supabase staging `catatin-staging` pada 2026-09-21, dijalankan dari mesin pengembang dengan publishable key staging (yang memang publik, ada di `app/dart_define.staging.json`). Header yang tidak berkaitan dengan CORS dibuang; sisanya kata per kata.

**1. Preflight ke endpoint refresh token dari origin situs publik**

```text
$ curl -X OPTIONS "https://herafvadqziftszhxqeq.supabase.co/auth/v1/token?grant_type=refresh_token" \
    -H "Origin: https://piambak.github.io" -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: apikey,authorization,content-type,x-client-info"
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
access-control-allow-headers: apikey,authorization,content-type,x-client-info
access-control-allow-methods: GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS,TRACE,CONNECT
access-control-max-age: 3600
```

**2. Preflight yang sama dari origin asing**

```text
$ curl -X OPTIONS "…/auth/v1/token?grant_type=refresh_token" \
    -H "Origin: https://contoh-asing.example" -H "Access-Control-Request-Method: POST"
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
```

**3. Preflight ke REST API dari origin asing**

```text
$ curl -X OPTIONS "https://herafvadqziftszhxqeq.supabase.co/rest/v1/transactions" \
    -H "Origin: https://contoh-asing.example" -H "Access-Control-Request-Method: PATCH"
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
access-control-allow-methods: GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS,TRACE,CONNECT
```

Tidak satu pun respons di atas memuat `Access-Control-Allow-Credentials`.

**4. Refresh hanya dengan header `Authorization: Bearer`, body tanpa refresh token**

```text
$ curl -X POST "…/auth/v1/token?grant_type=refresh_token" \
    -H "apikey: <publishable key>" -H "Authorization: Bearer <publishable key>" \
    -H "Content-Type: application/json" -d '{}'
{"code":400,"error_code":"validation_failed","msg":"Refresh token is not valid"}
HTTP 400
```

**5. Refresh dengan refresh token yang tidak pernah diterbitkan**

```text
$ curl -X POST "…/auth/v1/token?grant_type=refresh_token" \
    -H "apikey: <publishable key>" -H "Content-Type: application/json" \
    -d '{"refresh_token":"abcdefghijkl"}'
{"code":400,"error_code":"refresh_token_not_found","msg":"Invalid Refresh Token: Refresh Token Not Found"}
HTTP 400
```
