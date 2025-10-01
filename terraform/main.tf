terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend para almacenar el estado (opcional - comentar si no tienes S3)
  # backend "s3" {
  #   bucket = "tu-terraform-state-bucket"
  #   key    = "user-microservice/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

# Configurar el proveedor AWS
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "user-management-microservice"
      ManagedBy   = "terraform"
      Owner       = "devops-team"
    }
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "user_service_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "user-microservice-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "user_service_igw" {
  vpc_id = aws_vpc.user_service_vpc.id

  tags = {
    Name = "user-microservice-igw"
  }
}

# Create public subnet
resource "aws_subnet" "user_service_public_subnet" {
  vpc_id                  = aws_vpc.user_service_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "user-microservice-public-subnet"
    Type = "public"
  }
}

# Create private subnet
resource "aws_subnet" "user_service_private_subnet" {
  vpc_id            = aws_vpc.user_service_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "user-microservice-private-subnet"
    Type = "private"
  }
}

# Create route table for public subnet
resource "aws_route_table" "user_service_public_rt" {
  vpc_id = aws_vpc.user_service_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.user_service_igw.id
  }

  tags = {
    Name = "user-microservice-public-rt"
  }
}

# Create route table for private subnet
resource "aws_route_table" "user_service_private_rt" {
  vpc_id = aws_vpc.user_service_vpc.id

  tags = {
    Name = "user-microservice-private-rt"
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "user_service_public_rta" {
  subnet_id      = aws_subnet.user_service_public_subnet.id
  route_table_id = aws_route_table.user_service_public_rt.id
}

# Associate private subnet with private route table
resource "aws_route_table_association" "user_service_private_rta" {
  subnet_id      = aws_subnet.user_service_private_subnet.id
  route_table_id = aws_route_table.user_service_private_rt.id
}

# Grupo de seguridad para la instancia EC2
resource "aws_security_group" "user_service_sg" {
  name_prefix = "user-microservice-"
  description = "Security group for user management microservice (all-in-one)"
  vpc_id      = aws_vpc.user_service_vpc.id

  # HTTP access for the application
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application port
  ingress {
    description = "Application Port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL port (opcional, solo si quieres acceso externo a la BD)
  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "user-microservice-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Key Pair para acceso SSH
resource "aws_key_pair" "user_service_key" {
  key_name   = "user-microservice-key"
  public_key = var.public_key
}

# Template para user data
locals {
  user_data = base64encode(templatefile("${path.module}/../user_data.sh", {
    db_password = var.db_password
    app_port    = var.app_port
  }))
}

# Instancia EC2 única que contiene todo
resource "aws_instance" "user_service_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.user_service_key.key_name

  vpc_security_group_ids = [aws_security_group.user_service_sg.id]
  subnet_id              = aws_subnet.user_service_public_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = local.user_data

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  # Etiquetas
  tags = {
    Name = "user-microservice-single-instance"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP para la instancia (opcional)
resource "aws_eip" "user_service_eip" {
  count    = var.use_elastic_ip ? 1 : 0
  instance = aws_instance.user_service_instance.id
  domain   = "vpc"

  tags = {
    Name = "user-microservice-eip"
  }

  depends_on = [aws_instance.user_service_instance]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "user_service_logs" {
  name              = "/aws/ec2/user-microservice"
  retention_in_days = 7

  tags = {
    Name = "user-microservice-logs"
  }
}

# IAM Role para CloudWatch (opcional)
resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "user-microservice-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "user-microservice-instance-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

# ECR Repository for Docker images
resource "aws_ecr_repository" "user_service_repo" {
  name                 = "user-microservice"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "user-microservice-ecr"
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "user_service_policy" {
  repository = aws_ecr_repository.user_service_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# IAM User for GitHub CI
resource "aws_iam_user" "github_ci" {
  name = "user-microservice-github-ci"
}

# IAM Policy for ECR access
resource "aws_iam_user_policy" "github_ci_policy" {
  user = aws_iam_user.github_ci.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

# Access Key for GitHub CI
resource "aws_iam_access_key" "github_ci" {
  user = aws_iam_user.github_ci.name
}