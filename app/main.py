import os
from flask import Flask
from sqlalchemy import create_engine, text

app = Flask(__name__)

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)


@app.route("/")
def index():
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 'Hello from PostgreSQL!'")).fetchone()
        return f"<h1>{result[0]}</h1>"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)
