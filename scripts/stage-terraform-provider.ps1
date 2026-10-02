param(
  [string]$ManifestPath = "terraform/provider-supply-chain/providers.json",
  [string]$OutputDir = "artifacts/approved-provider-transfer",
  [Parameter(Mandatory = $true)]
  [string]$TrustedGpgPublicKeyPath
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) {
  throw "gpg is required to verify provider checksum signatures."
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$bundleRoot = New-Item -ItemType Directory -Force -Path $OutputDir
$downloads = New-Item -ItemType Directory -Force -Path (Join-Path $bundleRoot "downloads")
$gnupgHome = Join-Path $bundleRoot "gnupg"
New-Item -ItemType Directory -Force -Path $gnupgHome | Out-Null

$env:GNUPGHOME = (Resolve-Path -LiteralPath $gnupgHome).Path
gpg --batch --import $TrustedGpgPublicKeyPath | Out-Null

$approved = [ordered]@{
  generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
  source_manifest = $ManifestPath
  providers = @()
}

foreach ($provider in $manifest.providers) {
  if ($provider.source.kind -ne "hashicorp-releases") {
    throw "Unsupported provider source kind: $($provider.source.kind)"
  }

  $releaseName = "terraform-provider-$($provider.type)"
  $versionRoot = "$($provider.source.base_url.TrimEnd('/'))/$releaseName/$($provider.version)"
  $sumsFile = "$releaseName`_$($provider.version)_SHA256SUMS"
  $sigFile = "$sumsFile.sig"
  $localSums = Join-Path $downloads $sumsFile
  $localSig = Join-Path $downloads $sigFile

  Invoke-WebRequest -Uri "$versionRoot/$sumsFile" -OutFile $localSums
  Invoke-WebRequest -Uri "$versionRoot/$sigFile" -OutFile $localSig
  gpg --batch --verify $localSig $localSums | Out-Null

  $sumLines = Get-Content -LiteralPath $localSums
  foreach ($platform in $provider.platforms) {
    $zipName = "$releaseName`_$($provider.version)_$($platform.os)_$($platform.arch).zip"
    $zipPath = Join-Path $downloads $zipName
    $expectedLine = $sumLines | Where-Object { $_ -match "\s$([regex]::Escape($zipName))$" } | Select-Object -First 1
    if (-not $expectedLine) {
      throw "No checksum line found for $zipName"
    }

    $expectedSha256 = ($expectedLine -split "\s+")[0].ToLowerInvariant()
    Invoke-WebRequest -Uri "$versionRoot/$zipName" -OutFile $zipPath
    $actualSha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSha256 -ne $expectedSha256) {
      throw "Checksum mismatch for $zipName. Expected $expectedSha256 but got $actualSha256."
    }

    $approved.providers += [ordered]@{
      namespace = $provider.namespace
      type = $provider.type
      version = $provider.version
      os = $platform.os
      arch = $platform.arch
      filename = $zipName
      sha256 = $actualSha256
      source_url = "$versionRoot/$zipName"
      checksum_file = $sumsFile
      checksum_signature_file = $sigFile
    }
  }
}

$approvedPath = Join-Path $bundleRoot "approved-providers.json"
$approved | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $approvedPath -Encoding ascii
Write-Host "Approved provider bundle written to $approvedPath"
