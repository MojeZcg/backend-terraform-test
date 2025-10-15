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

  ingress {
    description = "HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-example-sg"
    Environment = "test"
    Owner = "jesusmontenegro941@gmail.com"
    Team = "DevOps"
  }
}

# Database Security Group
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow PostgreSQL from app"

  ingress {
    description = "PostgreSQL inbound"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.terraform-example-sg.id]
  }

  egress {
    description = "PostgreSQL outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database
resource "aws_db_instance" "app_db" {
  identifier         = "python-app-db"
  engine             = "postgres"
  instance_class     = "db.t4g.micro"
  allocated_storage  = 20
  username           = "appuser"
  password           = "SuperSecret123!"
  db_name            = "appdb"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot = true
}

resource "aws_instance" "terraform-example" {
  ami = "ami-0ba39aef11896824a"  # Amazon Linux 2023 AMI 2023.9.20251014.0 x86_64 HVM kernel-6.1
  instance_type = "t3.micro" 
  key_name = aws_key_pair.terraform-example-key.key_name
  vpc_security_group_ids = [aws_security_group.terraform-example-sg.id]

  user_data = templatefile("setup.sh", {
    database_url = "postgresql://${aws_db_instance.app_db.username}:${aws_db_instance.app_db.password}@${aws_db_instance.app_db.address}:5432/${aws_db_instance.app_db.db_name}"
  })  
    
  tags = {
    Name = "terraform-python-docker"
    Environment = "test"
  }
}

output "public_ip" {
  value = aws_instance.terraform-example.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.app_db.address
}