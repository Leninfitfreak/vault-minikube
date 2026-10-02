param(
  [string]$ApprovedManifestPath = "artifacts/approved-provider-transfer/approved-providers.json",
  [string]$BundleDownloadsDir = "artifacts/approved-provider-transfer/downloads",
  [string]$NexusUrl = "http://127.0.0.1:8081",
  [string]$Repository = "terraform-hosted"
)

$ErrorActionPreference = "Stop"

function Get-BasicAuthHeader {
  if ($env:NEXUS_BASIC_AUTH_BASE64) {
    return "Basic $($env:NEXUS_BASIC_AUTH_BASE64)"
  }

  if (-not $env:NEXUS_USERNAME -or -not $env:NEXUS_PASSWORD) {
    throw "Set NEXUS_USERNAME and NEXUS_PASSWORD, or NEXUS_BASIC_AUTH_BASE64, before uploading."
  }

  $bytes = [Text.Encoding]::ASCII.GetBytes("$($env:NEXUS_USERNAME):$($env:NEXUS_PASSWORD)")
  return "Basic $([Convert]::ToBase64String($bytes))"
}

$approved = Get-Content -LiteralPath $ApprovedManifestPath -Raw | ConvertFrom-Json
$authHeader = Get-BasicAuthHeader
$baseUrl = $NexusUrl.TrimEnd("/")

foreach ($provider in $approved.providers) {
  $zipPath = Join-Path $BundleDownloadsDir $provider.filename
  if (-not (Test-Path -LiteralPath $zipPath)) {
    throw "Provider archive not found: $zipPath"
  }

  $actualSha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actualSha256 -ne $provider.sha256.ToLowerInvariant()) {
    throw "Checksum mismatch before upload for $($provider.filename)."
  }

  $uploadUrl = "$baseUrl/repository/$Repository/v1/providers/$($provider.namespace)/$($provider.type)/$($provider.version)/download/$($provider.os)/$($provider.arch)"
  $headers = @{
    Authorization = $authHeader
    "Content-Disposition" = "attachment; filename=""$($provider.filename)"""
  }

  Invoke-WebRequest `
    -Method Put `
    -Uri $uploadUrl `
    -Headers $headers `
    -ContentType "application/zip" `
    -InFile $zipPath `
    | Out-Null

  Write-Host "Uploaded $($provider.namespace)/$($provider.type) $($provider.version) $($provider.os)_$($provider.arch)"
}
