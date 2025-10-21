import os
from datetime import datetime
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Obtener la URL de la base de datos desde .env
DATABASE_URL = os.getenv("DATABASE_URL")

# Crear engine
engine = create_engine(DATABASE_URL)

# Declarative base
Base = declarative_base()


# Modelo de ejemplo (tabla "users")
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


# Crear sesión
SessionLocal = sessionmaker(bind=engine)


def init_db():
    """Inicializa la base de datos creando las tablas si no existen."""
    Base.metadata.create_all(bind=engine)
    print("✅ Base de datos inicializada correctamente.")
