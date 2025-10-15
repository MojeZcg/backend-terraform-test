provider "aws" {
  region = "sa-east-1"
}

resource "aws_key_pair" "terraform-example-key" {
  key_name   = "terraform-example-key"
  public_key = file("./keys/terraform-test.key.pub")
}

resource "aws_security_group" "terraform-example-sg" {
  name        = "terraform-example-sg"
  description = "Security group for terraform example"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress = {
    description = "Http"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "terraform-example" {
    ami = "ami-07c0cae188e21a093"
    instance_type = "t3.micro"

    user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              
              # Instalar Docker
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              
              # Instalar Docker Compose
              sudo curl -L "https://github.com/docker/compose/releases/download/2.27.0/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              
              # Clonar el repositorio con tu app Docker
              cd /home/ec2-user
              git clone https://github.com/MojeZcg/python-terraform-test.git app
              cd app/app
              
              # Construir y ejecutar contenedor
              sudo docker build -t python-flask-app .
              sudo docker run -d -p 3000:3000 python-flask-app
              EOF

    key_name = aws_key_pair.terraform-example-key.key_name
}

