#!/bin/bash
# Actualiza sistema e instala Docker
sudo dnf update -y
sudo amazon-linux-extras enable docker
sudo dnf install docker git -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Clonar tu repositorio de app Python (Flask/FastAPI)
cd /home/ec2-user
git clone https://github.com/MojeZcg/python-terraform-test.git app
cd app/app

# Variables de conexión a la DB (inyectadas desde Terraform)
echo "DATABASE_URL=${database_url}" > .env

# Construir y ejecutar Docker
docker build -t python-flask-app .
docker run -d --restart always --env-file .env -p 3000:3000 --name py-app python-flask-app
