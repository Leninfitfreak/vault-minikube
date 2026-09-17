import os

import requests
from flask import Flask, jsonify


app = Flask(__name__)


@app.get("/")
def index():
    return jsonify({"service": "frontend-service", "status": "running"})


@app.get("/health")
def health():
    return jsonify({"status": "healthy"})


@app.get("/orders-check")
def orders_check():
    orders_service_url = os.getenv("ORDERS_SERVICE_URL")
    if not orders_service_url:
        return (
            jsonify(
                {
                    "orders_service": "unreachable",
                    "error": "ORDERS_SERVICE_URL is not configured",
                }
            ),
            500,
        )

    health_url = f"{orders_service_url.rstrip('/')}/health"
    try:
        response = requests.get(health_url, timeout=5)
        return (
            jsonify(
                {
                    "orders_service": "reachable",
                    "status_code": response.status_code,
                }
            ),
            response.status_code,
        )
    except requests.RequestException as exc:
        return (
            jsonify(
                {
                    "orders_service": "unreachable",
                    "error": str(exc),
                }
            ),
            503,
        )


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
