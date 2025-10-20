import os
from flask import Flask, jsonify, request, redirect
from sqlalchemy import create_engine, text
import boto3
from dotenv import load_dotenv
from db import init_db

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
BUCKET_NAME = os.getenv("BUCKET_NAME")

app = Flask(__name__)
engine = create_engine(DATABASE_URL)
s3 = boto3.client("s3")


@app.route("/")
def index():
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 'Hola desde PostgreSQL!'")).fetchone()
        return f"<h1>{result[0]}</h1>"


@app.route("/u", methods=["GET"])
def get_users():
    """Devuelve todos los usuarios en formato JSON"""
    with engine.connect() as conn:
        result = conn.execute(text("SELECT id, name, created_at FROM public.users"))
        users = [
            {
                "id": row[0],
                "name": row[1],
                "created_at": row[2].isoformat() if row[2] else None,
            }
            for row in result.fetchall()
        ]
    return jsonify(users)


@app.route("/u", methods=["POST"])
def create_user():
    data = request.get_json()
    if not data or "name" not in data:
        return jsonify({"error": "Falta el campo 'name'"}), 400

    with engine.begin() as conn:  # <<-- usar begin() en lugar de connect()
        result = conn.execute(
            text(
                "INSERT INTO public.users (name) VALUES (:name) RETURNING id, name, created_at"
            ),
            {"name": data["name"]},
        )
        new_user = result.fetchone()

    if not new_user:
        return jsonify({"error": "No se pudo crear el usuario"}), 500

    return (
        jsonify(
            {
                "id": new_user.id,
                "name": new_user.name,
                "created_at": (
                    new_user.created_at.isoformat() if new_user.created_at else None
                ),
            }
        ),
        201,
    )


@app.route("/f", methods=["GET"])
def list_files():
    # Listar objetos del bucket
    objects = s3.list_objects_v2(Bucket=BUCKET_NAME)
    files = []
    for obj in objects.get("Contents", []):
        files.append(
            {
                "key": obj["Key"],
                "size": obj["Size"],
                "last_modified": obj["LastModified"].isoformat(),
            }
        )
    return jsonify(files)


@app.route("/f/<filename>", methods=["GET"])
def get_file(filename):
    try:
        # Generar URL pre-firmada (válida 1 hora)
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": BUCKET_NAME, "Key": filename},
            ExpiresIn=3600,
        )
        return redirect(url)  # Redirige al navegador al S3
    except s3.exceptions.NoSuchKey:
        return jsonify({"error": "Archivo no encontrado"}), 404


@app.route("/r")
def list_routes():
    routes = [rule.rule for rule in app.url_map.iter_rules()]
    return jsonify(routes)


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=3000)
