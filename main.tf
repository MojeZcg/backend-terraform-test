### Terraform Configuration for AWS Infrastructure
provider "aws" {
  region = var.aws_region
}

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
    description = "Egress all"
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

#### S3 Bucket
resource "aws_s3_bucket" "internal_bucket" {
  bucket = "bucket-interno-terraform"

  tags = {
    Name        = "InternalBucket"
    Environment = "Dev"
  }
}

# Política mínima para acceso desde IAM roles (Lambda/ECS/etc.)
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3InternalAccess"
  description = "Permite listar y obtener objetos del bucket privado"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.internal_bucket.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.internal_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Crear Elastic IP
resource "aws_eip" "app_eip" {
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.app_instance.id
  allocation_id = aws_eip.app_eip.id
}

# EC2 Instance
resource "aws_instance" "app_instance" {
  ami           = "ami-0ba39aef11896824a" # Amazon Linux 2023 AMI 
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true 

  user_data = templatefile("setup.sh", {
    database_url = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.app_db.address}:5432/${aws_db_instance.app_db.db_name}",
    bucket_name  = aws_s3_bucket.internal_bucket.id
  })

  tags = {
    Name        = "terraform-python-docker"
    Environment = "test"
  }
}

