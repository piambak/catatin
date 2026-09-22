<#
.SYNOPSIS
  Build web rilis + sinkron ke root repo (versi Windows).

.EXAMPLE
  .\tool\build_web.ps1
  Sama dengan yang tayang di GitHub Pages: memakai app\dart_define.pages.json.

.EXAMPLE
  .\tool\build_web.ps1 -Mock
  Build data contoh, tanpa backend.

.EXAMPLE
  .\tool\build_web.ps1 -ApiBaseUrl "https://api.contoh.id/api/v1"
  Build yang menembak backend REST (mode hybrid).

.EXAMPLE
  .\tool\build_web.ps1 -Yes
  Tanpa -Yes skrip hanya melaporkan apa yang akan dihapus & disalin (dry-run).

.NOTES
  Base href wajib "/catatin/" karena situs tayang di sub-direktori
  https://piambak.github.io/catatin/.
#>
[CmdletBinding()]
param(
    [string]$ApiBaseUrl = "",
    [switch]$Mock,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

$Root     = Split-Path -Parent $PSScriptRoot
$App      = Join-Path $Root "app"
$Build    = Join-Path $App "build\web"
$Manifest = Join-Path $Root "tool\.last_build_files"

# T-29: versi lama menghapus SEMUA isi root yang tidak ada di $Keep, termasuk
# dotfile (-Force ikut mengambil .env, .vscode, .idea). Sekarang yang dihapus
# hanya jejak build sebelumnya, dicatat di tool\.last_build_files, dan $Keep
# tetap jadi lapisan kedua. Tanpa -Yes skrip berhenti setelah melaporkan.

# Root repo yang bukan hasil build — jangan sampai terhapus.
# Harus sama persis dengan daftar KEEP di tool/sync_build.sh.
$Keep = @(
    ".git", ".github", ".claude", ".codex", ".ok",
    ".gitignore", ".gitattributes", ".mcp.json", ".nojekyll", ".okignore",
    "app", "supabase", "tool", "wiki",
    "README.md", "CONTRIBUTING.md", "LICENSE", "CNAME"
)

if (-not (Test-Path (Join-Path $App "pubspec.yaml"))) {
    throw "$Root tidak terlihat seperti root repo catatin. Batal."
}

Push-Location $App
try {
    Write-Host "-> flutter pub get"
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get gagal." }

    $defines = @()
    if ($ApiBaseUrl) {
        # Sengaja tanpa dart_define.pages.json: --dart-define menimpa nilai dari
        # berkas, jadi mencampur keduanya diam-diam menghasilkan build campuran.
        $defines += "--dart-define=API_BASE_URL=$ApiBaseUrl"
        $defines += "--dart-define=DATA_SOURCE=hybrid"
        Write-Host "-> build tersambung backend REST: $ApiBaseUrl"
    } elseif ($Mock) {
        Write-Host "-> build mode mock (tanpa backend)"
    } else {
        $defines += "--dart-define-from-file=dart_define.pages.json"
        Write-Host "-> build sama dengan situs publik (dart_define.pages.json)"
    }

    Write-Host "-> flutter build web --release --base-href /catatin/"
    flutter build web --release --base-href "/catatin/" @defines
    if ($LASTEXITCODE -ne 0) { throw "flutter build web gagal." }
}
finally {
    Pop-Location
}

if (-not (Test-Path (Join-Path $Build "index.html"))) {
    throw "Hasil build tidak punya index.html. Batal."
}

# Berkas yang akan disalin, sebagai path relatif terhadap $Build.
$prefix   = (Resolve-Path $Build).Path.TrimEnd('\') + '\'
$NewFiles = Get-ChildItem -Path $Build -Recurse -File -Force |
    ForEach-Object { $_.FullName.Substring($prefix.Length) }

# Yang boleh dihapus: HANYA jejak build sebelumnya yang tidak dihasilkan lagi.
$Stale = @()
if (Test-Path $Manifest) {
    $newSet = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]$NewFiles, [StringComparer]::OrdinalIgnoreCase)
    foreach ($rel in (Get-Content $Manifest | Where-Object { $_ -ne "" })) {
        $top = ($rel -split '[\\/]')[0]
        if ($Keep -contains $top) { continue }
        if ($newSet.Contains($rel)) { continue }
        $full = Join-Path $Root $rel
        if (Test-Path $full) { $Stale += $rel }
    }
} else {
    Write-Host "! Manifes $Manifest belum ada (klon baru atau pemakaian pertama)."
    Write-Host "  Pembersihan dilewati; skrip hanya menyalin dan menulis manifes."
}

Write-Host "-> Akan menyalin $($NewFiles.Count) berkas dari $Build"
if ($Stale.Count -gt 0) {
    Write-Host "-> Akan menghapus $($Stale.Count) sisa build sebelumnya:"
    $Stale | ForEach-Object { Write-Host "     $_" }
} else {
    Write-Host "-> Tidak ada sisa build sebelumnya yang perlu dihapus."
}

if (-not $Yes) {
    Write-Host ""
    Write-Host "* Ini dry-run. Jalankan ulang dengan -Yes untuk benar-benar mengubah root."
    exit 0
}

foreach ($rel in $Stale) {
    Remove-Item (Join-Path $Root $rel) -Force -ErrorAction SilentlyContinue
}

Write-Host "-> Menyalin $Build -> $Root"
Copy-Item -Path (Join-Path $Build "*") -Destination $Root -Recurse -Force

Set-Content -Path $Manifest -Value $NewFiles -Encoding utf8
Write-Host "OK. Output web tersinkron; manifes diperbarui - periksa dengan 'git status'."
