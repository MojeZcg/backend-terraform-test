import os
from flask import Flask, jsonify
from sqlalchemy import create_engine, text

app = Flask(__name__)

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)


@app.route("/")
def index():
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 'Hello from PostgreSQL!'")).fetchone()
        return f"<h1>{result[0]}</h1>"


@app.route("/users", methods=["GET"])
def get_users():
    """Devuelve todos los usuarios en formato JSON"""
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT id, name, created_at FROM public.users")
        ).fetchall()
        users = [
            {"id": row.id, "name": row.name, "created_at": row.created_at.isoformat()}
            for row in result
        ]
        return jsonify(users)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)
