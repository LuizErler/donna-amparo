# Gera dart_defines.local.json a partir de variaveis de ambiente (nao commitar).
# Uso local:
#   $env:SUPABASE_URL = "https://xxx.supabase.co"
#   $env:SUPABASE_ANON_KEY = "eyJ..."
#   .\scripts\gerar_dart_defines_local.ps1
#
# CI usa secrets do GitHub (deploy.yml) — nao use este script no pipeline.

$ErrorActionPreference = "Stop"
$outFile = Join-Path $PSScriptRoot "..\dart_defines.local.json"

$url = $env:SUPABASE_URL
$key = $env:SUPABASE_ANON_KEY

if (-not $url -or -not $key) {
    Write-Host "ERRO: defina SUPABASE_URL e SUPABASE_ANON_KEY no ambiente." -ForegroundColor Red
    Write-Host "Ou copie dart_defines.local.json.example para dart_defines.local.json e preencha manualmente."
    exit 1
}

$content = @{
    SUPABASE_URL = $url.Trim()
    SUPABASE_ANON_KEY = $key.Trim()
} | ConvertTo-Json

Set-Content -Path $outFile -Value $content -Encoding UTF8
Write-Host "OK: $outFile gerado (arquivo esta no .gitignore)" -ForegroundColor Green
