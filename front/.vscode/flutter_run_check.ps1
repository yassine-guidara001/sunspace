$ErrorActionPreference = 'Stop'

$flutter = 'C:\dev_mobile\flutter\bin\flutter.bat'
if (-not (Test-Path $flutter)) {
  Write-Host "Flutter introuvable: $flutter" -ForegroundColor Red
  exit 1
}

Write-Host '=== Flutter version ===' -ForegroundColor Cyan
& $flutter --version
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '=== Flutter doctor ===' -ForegroundColor Cyan
& $flutter doctor -v
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '=== Flutter pub get ===' -ForegroundColor Cyan
& $flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '=== Run app (windows) ===' -ForegroundColor Green
& $flutter run -d windows
exit $LASTEXITCODE
