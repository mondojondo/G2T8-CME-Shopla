provider "aws" {

  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "us-east-1"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2             = "http://localhost:4566"
    rds             = "http://localhost:4566"
    iam             = "http://localhost:4566"
  }

  endpoint_url = "http://localhost:4566"  
}

resource "aws_key_pair" "my_key" {
  key_name   = "my-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_vpc" "default" {
  default = true
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "LocalStack VPC"
  }
}

# Create public subnets
resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Public Subnet 2"
  }
}

# Create private subnets
resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_nat_gateway" "gw1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public_1.id
}

resource "aws_nat_gateway" "gw2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public_2.id
}

resource "aws_eip" "nat1" {
  domain = "vpc"

  tags = {
    Name = "NAT Gateway EIP 1"
  }
}

resource "aws_eip" "nat2" {
  domain = "vpc"

  tags = {
    Name = "NAT Gateway EIP 2"
  }
}

resource "aws_lb_target_group" "example" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = data.aws_vpc.default.id

  ingress {
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

# Security Group for EC2 Instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-private-sg"
  description = "Allow internal traffic and NAT Gateway access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Adjust based on your VPC CIDR block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-private-sg"
  description = "Security group for RDS instance allowing EC2 access"

  ingress {
    from_port   = 4510
    to_port     = 4510
    protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # Allow traffic from any IP (adjust to your VPC CIDR)
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS-SG"
  }
}

# Autoscaling is only able to mock ec2 instance but not an docker wc2 container
resource "aws_launch_template" "ec2_template" {
  name_prefix = "lt-"
  
  image_id = "ami-df5de72bdb3b"
  instance_type = "t3.nano"
  key_name = aws_key_pair.my_key.key_name
  
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  
  user_data = file("install.sh")
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Shopla"
    }
  }
}

resource "aws_autoscaling_group" "example" {
  name                = "example-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.example.arn]
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  launch_template {
    id      = aws_launch_template.ec2_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Private-EC2"
    propagate_at_launch = true
  }
}

resource "aws_instance" "ec2_instance" {
  ami                     = "ami-df5de72bdb3b"
  instance_type           = "t3.nano"
  key_name                = aws_key_pair.my_key.key_name # Reference the key pair
  vpc_security_group_ids  = [aws_security_group.ec2_sg.id]

  user_data               = file("install.sh")

  tags = {
    Name = "Shopla"
  }
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "aurora-cluster-shopla"
  engine                  = "aurora-postgresql"
  engine_version          = "13.8"
  database_name           = "shopla"
  master_username         = "shopla"
  master_password         = "123456"
  port                    = 4510
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true

  tags = {
    Name = "ShoplaDB"
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count               = 1
  identifier          = "aurora-instance-shopla-${count.index}"
  cluster_identifier  = aws_rds_cluster.aurora_cluster.id
  instance_class      = "db.t3.medium"
  engine              = aws_rds_cluster.aurora_cluster.engine
  engine_version      = aws_rds_cluster.aurora_cluster.engine_version
  publicly_accessible = true

  tags = {
    Name = "ShoplaDB-Instance"
  }
}