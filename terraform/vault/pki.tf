resource "vault_mount" "pki_root" {
  path                      = "pki"
  type                      = "pki"
  description               = "Root PKI for demo environment"
  default_lease_ttl_seconds = 315360000
  max_lease_ttl_seconds     = 315360000
}

resource "vault_pki_secret_backend_root_cert" "root" {
  backend     = vault_mount.pki_root.path
  type        = "internal"
  common_name = "demo.local Root CA"
  ttl         = "315360000"
  key_type    = "rsa"
  key_bits    = 2048
}

resource "vault_mount" "pki_int" {
  path                      = "pki_int"
  type                      = "pki"
  description               = "Intermediate PKI for application certificates"
  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 31536000
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = "demo.local Intermediate CA"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend     = vault_mount.pki_root.path
  csr         = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name = "demo.local Intermediate CA"
  ttl         = "31536000"
  format      = "pem_bundle"
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

resource "vault_pki_secret_backend_role" "orders_service" {
  backend            = vault_mount.pki_int.path
  name               = "orders-service"
  ttl                = 3600
  max_ttl            = 86400
  allow_localhost    = false
  allow_bare_domains = true
  allow_subdomains   = false
  allowed_domains = [
    "orders-service.demo.svc.cluster.local",
    "orders-service.demo.svc"
  ]
}
