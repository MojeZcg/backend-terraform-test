import os
from flask import Flask, jsonify, request
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


@app.route("/users", methods=["POST"])
def create_user():
    """Crea un nuevo usuario"""
    data = request.get_json()
    if not data or "name" not in data:
        return jsonify({"error": "Falta el campo 'name'"}), 400

    with engine.connect() as conn:
        result = conn.execute(
            text(
                "INSERT INTO public.users (name) VALUES (:name) RETURNING id, name, created_at"
            ),
            {"name": data["name"]},
        )
        new_user = result.fetchone()
        conn.commit()
        return (
            jsonify(
                {
                    "id": new_user.id,
                    "name": new_user.name,
                    "created_at": new_user.created_at.isoformat(),
                }
            ),
            201,
        )


@app.route("/routes")
def list_routes():
    routes = [rule.rule for rule in app.url_map.iter_rules()]
    return jsonify(routes)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)
