import os

import psycopg2
from flask import Flask, jsonify


app = Flask(__name__)


def is_loaded(value):
    return bool(value and value.strip())


@app.get("/")
def index():
    return jsonify({"service": "orders-service", "status": "running"})


@app.get("/health")
def health():
    return jsonify({"status": "healthy"})


@app.get("/secret-check")
def secret_check():
    return jsonify({"api_key_loaded": is_loaded(os.getenv("API_KEY"))})


@app.get("/db-check")
def db_check():
    connection = None
    try:
        connection = psycopg2.connect(
            host=os.getenv("DB_HOST", "postgresql"),
            port=int(os.getenv("DB_PORT", "5432")),
            dbname=os.getenv("DB_NAME", "appdb"),
            user=os.getenv("DB_USERNAME"),
            password=os.getenv("DB_PASSWORD"),
            connect_timeout=5,
        )
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_user;")
            db_user = cursor.fetchone()[0]

        return jsonify({"database": "connected", "db_user": db_user})
    except Exception as exc:
        return jsonify({"database": "failed", "error": str(exc)}), 503
    finally:
        if connection is not None:
            connection.close()


@app.get("/info")
def info():
    return jsonify(
        {
            "service": "orders-service",
            "db_host": os.getenv("DB_HOST", "postgresql"),
            "db_name": os.getenv("DB_NAME", "appdb"),
            "api_key_loaded": is_loaded(os.getenv("API_KEY")),
        }
    )


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
