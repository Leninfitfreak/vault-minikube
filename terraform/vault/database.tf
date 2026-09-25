resource "vault_mount" "database" {
  path        = "database"
  type        = "database"
  description = "Database secrets engine for demo applications"
}

resource "vault_database_secret_backend_connection" "postgresql" {
  backend       = vault_mount.database.path
  name          = "postgresql"
  allowed_roles = ["orders-service"]

  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@postgresql.demo.svc.cluster.local:5432/appdb?sslmode=disable"
    username       = var.vault_db_admin_username
    password       = var.vault_db_admin_password
  }
}

resource "vault_database_secret_backend_role" "orders_service" {
  backend = vault_mount.database.path
  name    = "orders-service"
  db_name = vault_database_secret_backend_connection.postgresql.name

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT CONNECT ON DATABASE appdb TO \"{{name}}\";"
  ]

  default_ttl = 3600
  max_ttl     = 86400
}
