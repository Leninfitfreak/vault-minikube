param(
  [string]$OutputPath = "terraform/cli-config/terraformrc.nexus.local",
  [string]$NexusUrl = "http://127.0.0.1:8081",
  [string]$Repository = "terraform-hosted"
)

$ErrorActionPreference = "Stop"

$providerServiceUrl = "$($NexusUrl.TrimEnd('/'))/repository/$Repository/v1/providers/"

$content = @"
host "registry.terraform.io" {
  services = {
    "providers.v1" = "$providerServiceUrl"
  }
}
"@

$parent = Split-Path -Parent $OutputPath

if ($parent) {
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $content -Encoding ascii

Write-Host "Terraform CLI config written to $OutputPath"
Write-Host "Set TF_TOKEN_registry_terraform_io to the Nexus Terraform bearer token before running Terraform."
