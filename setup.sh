#!/bin/bash
sudo dnf update -y

# Instala Docker
sudo dnf install -y docker git 
sudo systemctl enable --now docker

# Agrega el usuario ec2-user al grupo docker para evitar usar sudo con Docker
sudo usermod -aG docker ec2-user

# Clona el repositorio de la aplicación
cd /home/ec2-user
git clone https://github.com/MojeZcg/backend-terraform-test.git app
cd app/src

# Variables de conexión a la DB (inyectadas desde Terraform)
echo "DATABASE_URL=${database_url}" > .env
echo "BUCKET_NAME=${bucket_name}" >> .env

# Configura Git para evitar problemas de permisos
git config --global --add safe.directory /home/ec2-user/

# Construir y ejecutar Docker
docker build -t python-flask-app .
docker image prune -f
docker run -d --restart always --env-file .env -p 3000:3000 --name py-app python-flask-app:latest
