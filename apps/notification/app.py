import os

from flask import Flask, jsonify


app = Flask(__name__)


def is_loaded(value):
    return bool(value and value.strip())


@app.get("/")
def index():
    return jsonify({"service": "notification-service", "status": "running"})


@app.get("/health")
def health():
    return jsonify({"status": "healthy"})


@app.get("/secret-check")
def secret_check():
    return jsonify(
        {"notification_api_key_loaded": is_loaded(os.getenv("NOTIFICATION_API_KEY"))}
    )


@app.get("/tls-check")
def tls_check():
    cert_path = os.getenv("TLS_CERT_PATH", "/etc/tls/tls.crt")
    key_path = os.getenv("TLS_KEY_PATH", "/etc/tls/tls.key")
    ca_path = os.getenv("TLS_CA_PATH", "/etc/tls/ca.crt")

    return jsonify(
        {
            "certificate_found": os.path.isfile(cert_path),
            "private_key_found": os.path.isfile(key_path),
            "ca_found": os.path.isfile(ca_path),
        }
    )


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
