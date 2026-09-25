resource "vault_kubernetes_auth_backend_role" "orders_service" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "orders-service"
  bound_service_account_names      = ["orders-service"]
  bound_service_account_namespaces = ["demo"]
  token_policies                   = [vault_policy.orders_service.name]
  token_ttl                        = 3600
}

resource "vault_kubernetes_auth_backend_role" "frontend_service" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "frontend-service"
  bound_service_account_names      = ["frontend-service"]
  bound_service_account_namespaces = ["demo"]
  token_policies                   = [vault_policy.frontend_service.name]
  token_ttl                        = 3600
}

resource "vault_kubernetes_auth_backend_role" "notification_service" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "notification-service"
  bound_service_account_names      = ["notification-service"]
  bound_service_account_namespaces = ["demo"]
  token_policies                   = [vault_policy.notification_service.name]
  token_ttl                        = 3600
}
