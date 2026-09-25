resource "vault_policy" "orders_service" {
  name = "orders-service"

  policy = <<EOT
path "kv/data/orders/*" {
  capabilities = ["read"]
}

path "database/creds/orders-service" {
  capabilities = ["read"]
}

path "pki_int/issue/orders-service" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_policy" "frontend_service" {
  name = "frontend-service"

  policy = <<EOT
path "pki_int/issue/frontend-service" {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_policy" "notification_service" {
  name = "notification-service"

  policy = <<EOT
path "kv/data/notification/*" {
  capabilities = ["read"]
}

path "pki_int/issue/notification-service" {
  capabilities = ["create", "update"]
}
EOT
}
