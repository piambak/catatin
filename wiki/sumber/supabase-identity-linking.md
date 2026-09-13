---
title: Identity Linking | Supabase Docs + kode DetermineAccountLinking
description: Kutipan dokumen Supabase soal penggabungan identitas otomatis dan potongan kode Supabase Auth yang menganggap email terverifikasi saat autoconfirm menyala.
type: source
source_url: https://supabase.com/docs/guides/auth/auth-identity-linking
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
Hanya bagian yang dikutip wiki yang disimpan. Tab pada potongan kode diganti empat spasi.

## Dokumen: bagian "Automatic linking"

Sumber: <https://supabase.com/docs/guides/auth/auth-identity-linking>

Kalimat pembuka:

> Supabase Auth automatically links identities with the same email address to a single user.

Penjagaan terhadap email yang belum terverifikasi:

> It would also be an insecure practice to automatically link an identity to a user with an unverified email address since that could lead to pre-account takeover attacks. To prevent this from happening, when a new identity can be linked to an existing user, Supabase Auth will remove any other unconfirmed identities linked to an existing user.

## Kode: `internal/models/linking.go`

Sumber: <https://github.com/supabase/auth/blob/master/internal/models/linking.go>, branch `master` pada commit `4eee58f296d9` (lisensi MIT), diambil 2026-09-13.

```go
func DetermineAccountLinking(tx *storage.Connection, config *conf.GlobalConfiguration, emails []provider.Email, aud, providerName, sub string) (AccountLinkingResult, error) {
    var verifiedEmails []string
    var candidateEmail provider.Email
    for _, email := range emails {
        if email.Verified || config.Mailer.Autoconfirm {
            verifiedEmails = append(verifiedEmails, strings.ToLower(email.Email))
        }
```

## Kode: `internal/api/signup.go`

Sumber: <https://github.com/supabase/auth/blob/master/internal/api/signup.go>, commit yang sama.

```go
if params.Provider == EmailProvider && !user.IsConfirmed() {
    if config.Mailer.Autoconfirm {
        // … audit log …
        if terr = user.Confirm(tx); terr != nil {
```

Bacaan gabungan (tafsiran wiki, bukan kutipan): saat `Mailer.Autoconfirm` menyala — yaitu *Confirm email* dimatikan di dashboard — pendaftaran email langsung dikonfirmasi, dan alamat itu dihitung terverifikasi untuk penggabungan akun. Identitas email tersebut karena itu tidak termasuk "unconfirmed identities" yang dihapus saat login Google digabung.
