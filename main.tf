#### SSH Key
resource "aws_key_pair" "terraform_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

#### Security Groups
resource "aws_security_group" "app_sg" {
  name        = "terraform-example-sg"
  description = "Security group for app"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Egress all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "terraform-example-sg"
    Environment = "test"
    Owner       = "jesusmontenegro941@gmail.com"
    Team        = "DevOps"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow PostgreSQL from app"

  ingress {
    description     = "PostgreSQL inbound"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "db-sg"
    Environment = "test"
  }
}

#### Database
resource "aws_db_instance" "app_db" {
  identifier         = "python-app-db"
  engine             = "postgres"
  instance_class     = "db.t4g.micro"
  allocated_storage  = 20
  username           = var.db_username
  password           = var.db_password
  db_name            = "appdb"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot = true
}

# EC2 Instance
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = templatefile("setup.sh", {
    database_url = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.app_db.address}:5432/${aws_db_instance.app_db.db_name}"
  })

  tags = {
    Name        = "terraform-python-docker"
    Environment = "test"
  }
}
