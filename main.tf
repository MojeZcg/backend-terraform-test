provider "aws" {
  region = "sa-east-1"
}

resource "aws_instance" "terraform-example" {
    ami = "ami-07c0cae188e21a093"
    instance_type = "t3.micro"

    key_name = aws_key_pair.terraform-example-key.key_name
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
    from_port   = 80
    to_port     = 80
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