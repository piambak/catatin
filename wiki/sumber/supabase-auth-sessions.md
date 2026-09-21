---
title: User sessions — Supabase Docs
description: Supabase Auth provides fine-grained control over your user's sessions.
type: source
source_url: https://supabase.com/docs/guides/auth/sessions
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
Kutipan berkas sumber dokumentasi `apps/docs/content/guides/auth/sessions.mdx` di repo `supabase/supabase` (commit terakhir berkas itu `24be387`, 3 Sep 2026), dibaca lewat GitHub REST API pada 2026-09-21. Hanya bagian yang dirujuk wiki, kata per kata; `[…]` menandai bagian yang dilewati.

> Supabase Auth provides fine-grained control over your user's sessions.
> A session is created when a user signs in. By default, it lasts indefinitely and a user can have an unlimited number of active sessions on as many devices.
>
> A session is represented by the Supabase Auth access token in the form of a JWT, and a refresh token which is a unique string.
>
> Access tokens are designed to be short lived, usually between 5 minutes and 1 hour while refresh tokens never expire but can only be used once. You can exchange a refresh token only once to get a new access and refresh token pair.
>
> […]
>
> ## Limiting session lifetime and number of allowed sessions per user
>
> This feature is only available on Pro Plans and up.
>
> Supabase Auth can be configured to limit the lifetime of a user's session. By default, all sessions are active until the user signs out or performs some other action that terminates a session.
>
> […]
>
> There are three ways to limit the lifetime of a session:
>
> - Time-boxed sessions, which terminate after a fixed amount of time.
> - Set an inactivity timeout, which terminates sessions that haven't been refreshed within the timeout duration.
> - Enforce a single-session per user, which only keeps the most recently active session.
>
> […]
>
> ## Frequently asked questions
>
> ### What are recommended values for access token (JWT) expiration?
>
> Most applications should use the default expiration time of 1 hour. You can customize this value in the Auth settings > Sessions.
>
> Setting a value over 1 hour is generally discouraged for security reasons, but it may make sense in certain situations.
>
> Values below 5 minutes, and especially below 2 minutes, should not be used in most situations because:
>
> - The shorter the expiration time, the more frequently refresh tokens are used, which increases the load on the Auth server.
> - […]
> - Supabase's client libraries always try to refresh the session ahead of time, which won't be possible if the expiration time is too short.
>
> ### What is refresh token reuse detection and what does it protect from?
>
> […]
>
> The general rule is that a refresh token can only be used once. However, strictly enforcing this can cause certain issues to arise. There are two exceptions to this design to prevent the early and unexpected termination of user's sessions:
>
> - A refresh token can be used more than once within a defined reuse interval. By default this is 10 seconds and we do not recommend changing this value. […]
> - If the parent of the currently active refresh token for the user's session is being used, the active token will be returned. […]
>
> Should the reuse attempt not fall under these two exceptions, the whole session is regarded as terminated and all refresh tokens belonging to it are marked as revoked. You can disable this behavior in the Advanced Settings of the Auth settings page, though it is generally not recommended.
>
> The purpose of this mechanism is to guard against potential security issues where a refresh token could have been stolen from the user, for example by exposing it accidentally in logs that leak (like logging cookies, request bodies or URL params) or via vulnerable third-party servers. It does not guard against the case where a user's session is stolen from their device.
>
> […]
>
> ### Using HTTP-only cookies to store access and refresh tokens
>
> This is possible, but only for apps that use the traditional server-only web app approach where all of the application logic is implemented on the server and it returns rendered HTML only.
>
> If your app uses any client side JavaScript to build a rich user experience, using HTTP-Only cookies is not feasible since only your server will be able to read and refresh the session of the user. The browser will not have access to the access and refresh tokens.
