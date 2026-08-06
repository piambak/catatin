<#
.SYNOPSIS
  Build web rilis + sinkron ke root repo (versi Windows).

.EXAMPLE
  .\tool\build_web.ps1
  Build mode mock — sama dengan yang tayang di GitHub Pages.

.EXAMPLE
  .\tool\build_web.ps1 -ApiBaseUrl "https://api.contoh.id/api/v1"
  Build yang menembak backend sungguhan.

.NOTES
  Base href wajib "/catatin/" karena situs tayang di sub-direktori
  https://piambak.github.io/catatin/.
#>
[CmdletBinding()]
param(
    [string]$ApiBaseUrl = ""
)

$ErrorActionPreference = "Stop"

$Root  = Split-Path -Parent $PSScriptRoot
$App   = Join-Path $Root "app"
$Build = Join-Path $App "build\web"

# Root repo yang bukan hasil build — jangan sampai terhapus.
$Keep = @(
    ".git", ".github", ".claude",
    ".gitignore", ".gitattributes", ".nojekyll",
    "app", "docs", "tool",
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
        $defines += "--dart-define=API_BASE_URL=$ApiBaseUrl"
        $defines += "--dart-define=DATA_SOURCE=hybrid"
        Write-Host "-> build tersambung backend: $ApiBaseUrl"
    } else {
        Write-Host "-> build mode mock (tanpa backend)"
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

Write-Host "-> Membersihkan output lama di root..."
Get-ChildItem -Path $Root -Force |
    Where-Object { $Keep -notcontains $_.Name } |
    ForEach-Object { Remove-Item $_.FullName -Recurse -Force }

Write-Host "-> Menyalin $Build -> $Root"
Copy-Item -Path (Join-Path $Build "*") -Destination $Root -Recurse -Force

Write-Host "OK. Output web tersinkron - periksa dengan 'git status'."
