resource "vault_mount" "kv" {
  path = "kv"
  type = "kv"
  options = {
    version = "2"
  }

  description = "KV v2 secrets for demo applications"
}
