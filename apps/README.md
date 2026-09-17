# Application Layer

This directory contains the application layer for the Vault and Kubernetes learning project. It intentionally does not include Kubernetes, Helm, Argo CD, Terraform, or Vault configuration.

## Architecture

```text
frontend-service
        |
        v
orders-service
        |
        v
PostgreSQL

notification-service is an independent service.
```

## Services

### frontend-service

Public-facing Flask service. It exposes a basic health endpoint and checks whether the orders service is reachable through `ORDERS_SERVICE_URL`.

Future Vault mapping:

- PKI/TLS exposure

Environment variables:

- `ORDERS_SERVICE_URL`
- `PORT`, default `8080`

### orders-service

Main Flask service for demonstrating Vault-backed application secrets and dynamic database credentials. It never returns API key or database password values.

Future Vault mapping:

- KV static API key
- Dynamic PostgreSQL credentials
- PKI/TLS

Environment variables:

- `API_KEY`
- `DB_HOST`, default `postgresql`
- `DB_PORT`, default `5432`
- `DB_NAME`, default `appdb`
- `DB_USERNAME`
- `DB_PASSWORD`
- `PORT`, default `8080`

### notification-service

Independent Flask service for demonstrating a second application identity. It can check for a static API key and mounted TLS certificate files without reading private key contents.

Future Vault mapping:

- KV static API key
- PKI/TLS

Environment variables:

- `NOTIFICATION_API_KEY`
- `TLS_CERT_PATH`, default `/etc/tls/tls.crt`
- `TLS_KEY_PATH`, default `/etc/tls/tls.key`
- `TLS_CA_PATH`, default `/etc/tls/ca.crt`
- `PORT`, default `8080`

## Local Docker Builds

Run from the repository root:

```powershell
docker build -t frontend-service:v1 .\apps\frontend
docker build -t orders-service:v1 .\apps\orders
docker build -t notification-service:v1 .\apps\notification
```

## Local Docker Tests

Frontend:

```powershell
docker run --rm `
  -p 8081:8080 `
  -e ORDERS_SERVICE_URL=http://host.docker.internal:8082 `
  frontend-service:v1
```

Orders:

```powershell
docker run --rm `
  -p 8082:8080 `
  -e API_KEY=test-local-key `
  -e DB_HOST=host.docker.internal `
  -e DB_PORT=5432 `
  -e DB_NAME=appdb `
  -e DB_USERNAME=testuser `
  -e DB_PASSWORD=testpassword `
  orders-service:v1
```

Notification:

```powershell
docker run --rm `
  -p 8083:8080 `
  -e NOTIFICATION_API_KEY=test-notification-key `
  notification-service:v1
```

## Endpoint Checks

Frontend:

```powershell
Invoke-RestMethod http://localhost:8081/
Invoke-RestMethod http://localhost:8081/health
Invoke-RestMethod http://localhost:8081/orders-check
```

Orders:

```powershell
Invoke-RestMethod http://localhost:8082/
Invoke-RestMethod http://localhost:8082/health
Invoke-RestMethod http://localhost:8082/secret-check
Invoke-RestMethod http://localhost:8082/db-check
Invoke-RestMethod http://localhost:8082/info
```

Notification:

```powershell
Invoke-RestMethod http://localhost:8083/
Invoke-RestMethod http://localhost:8083/health
Invoke-RestMethod http://localhost:8083/secret-check
Invoke-RestMethod http://localhost:8083/tls-check
```

## Security Notes

- No passwords, API keys, or private key contents are hardcoded or returned by HTTP responses.
- Containers run as a dedicated non-root user.
- Dependencies are intentionally minimal for a learning/demo project.
