FROM python:3.13-slim

# Establecer el directorio de trabajo 
WORKDIR /app

# Installar dependencias
COPY requirements.txt .

# Installar las dependencias del archivo requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación al contenedor
COPY . .

# Exponer el puerto en el que la aplicación correrá
EXPOSE 3000

# Comando para correr la aplicación
CMD ["gunicorn", "--bind", "0.0.0.0:3000", "--workers", "4", "app:app"]