# Builds Hablemos from a space-free mirror.
#
# The Windows username has a space ("wilheim leeshu") and Flutter's
# native-assets hook breaks on paths with spaces, so builds run from a copy at
# C:\hablemos-build. Always edit in the real project; the mirror is overwritten.
#
#   .\scripts\build-apk.ps1            debug APK
#   .\scripts\build-apk.ps1 -Release   release APK
#   .\scripts\build-apk.ps1 -Install   build, then install on the connected phone

param(
  [switch]$Release,
  [switch]$Install,
  [string]$Mirror = 'C:\hablemos-build'
)

# 'Continue', not 'Stop': in Windows PowerShell 5.1 any stderr line from a
# native tool (Gradle/Java print harmless warnings there) becomes an error and
# 'Stop' would abort the build. Failures are caught via $LASTEXITCODE instead.
$ErrorActionPreference = 'Continue'
$env:PUB_CACHE = 'C:\pubcache'

# Gradle's JVM opens a loopback socket file in %TEMP%; the default TEMP here is
# the short-name path C:\Users\WILHEI~1\..., which fails with
# "Unable to establish loopback connection". Use a plain path instead.
New-Item -ItemType Directory -Force 'C:\tmp' | Out-Null
$env:TEMP = 'C:\tmp'
$env:TMP = 'C:\tmp'
$root = Split-Path -Parent $PSScriptRoot

robocopy $root $Mirror /MIR /XD build .dart_tool .idea .git /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE)" }

Push-Location $Mirror
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
  $mode = if ($Release) { '--release' } else { '--debug' }
  flutter build apk $mode
  if ($LASTEXITCODE -ne 0) { throw 'flutter build failed' }

  $name = if ($Release) { 'app-release.apk' } else { 'app-debug.apk' }
  $apk = Join-Path $Mirror "build\app\outputs\flutter-apk\$name"
  New-Item -ItemType Directory -Force (Join-Path $root 'builds') | Out-Null
  Copy-Item $apk (Join-Path $root "builds\hablemos-$($mode.TrimStart('-')).apk") -Force
  Write-Host "APK: $(Join-Path $root "builds\hablemos-$($mode.TrimStart('-')).apk")"

  if ($Install) { adb install -r $apk }
} finally {
  Pop-Location
}
