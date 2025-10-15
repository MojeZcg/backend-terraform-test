import os
from flask import Flask
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

db_url = os.getenv("DATABASE_URL")
engine = create_engine(db_url)


@app.route("/")
def index():
    with engine.connect() as conn:
        result = conn.execute("SELECT 'Hello from PostgreSQL!'").fetchone()
    return f"<h1>{result[0]}</h1>"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)
