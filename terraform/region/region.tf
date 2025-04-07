terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "region_name" {
  description = "The AWS region name"
  type        = string
}

variable "key_name" {
  description = "The SSH key name to use for EC2 instances"
  type        = string
}

variable "vpc_id" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
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

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = [
    cidrsubnet(var.vpc_cidr_block, 8, 1),
    cidrsubnet(var.vpc_cidr_block, 8, 2)
  ]

  private_subnets = [
    cidrsubnet(var.vpc_cidr_block, 8, 3),
    cidrsubnet(var.vpc_cidr_block, 8, 4)
  ]

  validate_subnets = (
    length(local.public_subnets) == 2 && 
    length(local.private_subnets) == 2
  ) ? true : error("Subnet lists must have exactly 2 entries")
}

resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.selected.id
  tags = {
    Name = "IGW-${var.region_name}"
  }
}

resource "aws_subnet" "public" {
  count = 2
  vpc_id = data.aws_vpc.selected.id
  cidr_block = local.public_subnets[count.index]
  availability_zone = local.azs[count.index]
  tags = {
    Name = "Public-${var.region_name}-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = 2
  vpc_id = data.aws_vpc.selected.id
  cidr_block = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]
  tags = {
    Name = "Private-${var.region_name}-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.selected.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RT-${var.region_name}"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

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
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app" {
  name               = "alb-${var.region_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "alb-${var.region_name}"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "tg-${var.region_name}"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_launch_template" "ec2_template" {
  name_prefix   = "lt-${var.region_name}-"
  image_id      = "ami-12345678"
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

resource "aws_autoscaling_group" "app" {
  name                = "asg-${var.region_name}"
  min_size            = 1
  max_size            = 4
  desired_capacity    = min(2, length(aws_subnet.private[*].id))
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

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

resource "aws_rds_cluster" "main" {
  cluster_identifier  = "aurora-${var.region_name}"
  engine              = "aurora-postgresql"
  database_name       = "mydb"
  master_username     = "admin"
  master_password     = "ChangeMe123!"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

resource "aws_rds_cluster_instance" "writer" {
  count              = 1
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.main.engine
}
