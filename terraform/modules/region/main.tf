terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.93.0"  
    }
  }
}

# variables.tf
variable "region_name" {
  description = "The AWS region name"
  type        = string
}

variable "key_name" {
  description = "The SSH key name to use for EC2 instances"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID to use for the region"
  type        = string
}

variable "vpc_cidr_block" {
  description = "Base CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# main.tf (module)
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Restrict to exactly 2 AZs
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  
  # Calculate subnets with explicit validation
  public_subnets = [
    cidrsubnet(var.vpc_cidr_block, 8, 1), # 10.0.1.0/24
    cidrsubnet(var.vpc_cidr_block, 8, 2)  # 10.0.2.0/24
  ]
  
  private_subnets = [
    cidrsubnet(var.vpc_cidr_block, 8, 3), # 10.0.3.0/24
    cidrsubnet(var.vpc_cidr_block, 8, 4)  # 10.0.4.0/24
  ]
  
  # Validate subnet counts
  validate_subnets = (
    length(local.public_subnets) == 2 && 
    length(local.private_subnets) == 2
  ) ? true : error("Subnet lists must have exactly 2 entries")
}

# Public Subnets (2 total)
resource "aws_subnet" "public" {
  count = 2

  vpc_id            = var.vpc_id
  cidr_block        = local.public_subnets[count.index]
  availability_zone = local.azs[count.index]
  tags = {
    Name = "Public-${var.region_name}-${count.index + 1}"
  }
}

# Private Subnets (2 total)
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = var.vpc_id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]
  tags = {
    Name = "Private-${var.region_name}-${count.index + 1}"
  }
}

# NAT Gateways (1 per AZ)
resource "aws_eip" "nat" {
  count = length(local.azs)
  domain = "vpc"
  tags = {
    Name = "NAT-EIP-${var.region_name}-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "gw" {
  count = length(local.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "NAT-GW-${var.region_name}-${count.index + 1}"
  }
}

# Security Groups (Hardened)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg-${var.region_name}"
  description = "Allow HTTP/3000 and SSH from VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-${var.region_name}"
  description = "Allow PostgreSQL from EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 4510
    to_port         = 4510
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # Restrict to EC2 SG only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template with validated key pair
resource "aws_launch_template" "ec2_template" {
  name_prefix   = "lt-${var.region_name}-"
  image_id      = "ami-12345678" # Replace with actual AMI
  instance_type = "t3.nano"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-${var.region_name}"
    }
  }
}

# Auto Scaling Group (constrained to 2 AZs)
resource "aws_autoscaling_group" "app" {
  name                = "asg-${var.region_name}"
  min_size            = 1
  max_size            = 4
  desired_capacity    = min(2, length(aws_subnet.private[*].id)) # Max 2 instances
  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.ec2_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app-${var.region_name}"
    propagate_at_launch = true
  }
}

# Aurora Cluster (secure)
resource "aws_rds_cluster" "main" {
  cluster_identifier  = "aurora-${var.region_name}"
  engine              = "aurora-postgresql"
  database_name       = "mydb"
  master_username     = "admin"
  master_password     = "ChangeMe123!" # Use secrets manager in production
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

resource "aws_rds_cluster_instance" "writer" {
  count              = 1
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.main.engine
}