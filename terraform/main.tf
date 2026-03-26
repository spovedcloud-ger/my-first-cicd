# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
}

# Terraform State Storage (S3)
terraform {
  backend "s3" {
    bucket = "my-first-cicd-terraform-state-${var.environment}"
    key    = "terraform.tfstate"
    region = var.aws_region
  }
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-first-cicd-vpc-${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-first-cicd-igw-${var.environment}"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "my-first-cicd-public-subnet-${var.environment}"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "my-first-cicd-public-rt-${var.environment}"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for App
resource "aws_security_group" "app" {
  name        = "my-first-cicd-app-sg-${var.environment}"
  description = "Security group for CI/CD app"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # App port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL (for development/debugging)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redis (for development/debugging)
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (port 80) for Let's Encrypt ACME challenge
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (port 443) for SSL/TLS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-first-cicd-app-sg-${var.environment}"
  }
}

# EC2 Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "my-first-cicd-key-${var.environment}"
  public_key = var.ssh_public_key

  tags = {
    Name = "my-first-cicd-key-${var.environment}"
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.deployer.id

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io docker-compose git nginx certbot python3-certbot-nginx
              usermod -aG docker ubuntu
              systemctl enable docker
              systemctl start docker
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = {
    Name = "my-first-cicd-server-${var.environment}"
  }
}

# Elastic IP
resource "aws_eip" "app" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "my-first-cicd-eip-${var.environment}"
  }
}