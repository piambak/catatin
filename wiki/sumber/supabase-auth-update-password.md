---
title: Supabase Auth — kode pasang kata sandi & login kata sandi
description: "Potongan kode Supabase Auth: memasang kata sandi lewat PUT /user (verifikasi ulang 24 jam, kata sandi saat ini, identitas email pertama) dan syarat login kata sandi."
type: source
source_url: https://github.com/supabase/auth/blob/4eee58f296d9/internal/api/user.go
media_type: text/x-go
date_fetched: 2026-09-13
author: Supabase
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Hanya bagian yang dikutip wiki yang disimpan. Repo `supabase/auth` commit `4eee58f296d9` (lisensi MIT), diambil 2026-09-13. Tab diganti empat spasi; `// …` menandai baris yang dilewati.

## `internal/api/user.go` — `UserUpdate`

Sumber: <https://github.com/supabase/auth/blob/4eee58f296d9/internal/api/user.go>

Verifikasi ulang saat "Secure password change" menyala:

```go
// must be captured before setting password below (via user.SetPassword)
addingFirstPassword := params.Password != nil && *params.Password != "" && !user.HasPassword()

if params.Password != nil {
    if config.Security.UpdatePasswordRequireReauthentication {
        now := time.Now()
        // we require reauthentication if the user hasn't signed in recently in the current session
        if session == nil || now.After(session.CreatedAt.Add(24*time.Hour)) {
            if len(params.Nonce) == 0 {
                return apierrors.NewBadRequestError(apierrors.ErrorCodeReauthenticationNeeded, "Password update requires reauthentication")
            }
```

Kata sandi saat ini hanya diminta untuk akun yang sudah punya kata sandi:

```go
if user.HasPassword() {
    // current password required when updating password
    if config.Security.UpdatePasswordRequireCurrentPassword {
        // …
            return apierrors.NewBadRequestError(apierrors.ErrorCodeCurrentPasswordRequired, "Current password required when setting new password.")
```

Kata sandi pertama membuat identitas email:

```go
// this is the first time a user sets a password on their account
// TODO(fm): we may want to relax it to also create identities for existing passwords
if addingFirstPassword {
    if terr := a.ensureEmailIdentityForPassword(tx, user); terr != nil {
```

## `internal/api/token.go` — login kata sandi

Sumber: <https://github.com/supabase/auth/blob/4eee58f296d9/internal/api/token.go>

```go
if !user.HasPassword() {
    return apierrors.NewBadRequestError(apierrors.ErrorCodeInvalidCredentials, InvalidLoginMessage)
}
// …
if params.Email != "" && !user.IsConfirmed() {
    return apierrors.NewBadRequestError(apierrors.ErrorCodeEmailNotConfirmed, "Email not confirmed")
```

## `internal/api/apierrors/errorcode.go`

```go
ErrorCodeReauthenticationNeeded            ErrorCode = "reauthentication_needed"
ErrorCodeSamePassword                      ErrorCode = "same_password"
ErrorCodeReauthenticationNotValid          ErrorCode = "reauthentication_not_valid"
ErrorCodeCurrentPasswordMismatch           ErrorCode = "current_password_invalid"
ErrorCodeCurrentPasswordRequired           ErrorCode = "current_password_required"
```
