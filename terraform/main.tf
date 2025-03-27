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

  # endpoint_url = "http://localhost:4566"  # Commented out as endpoints block is the preferred method
}

resource "aws_key_pair" "my_key" {
  key_name   = "my-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_vpc" "default" {
  default = true
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

resource "aws_security_group" "ec2_sg" {
  name        = "allow-http"
  description = "Allow HTTP traffic and outbound to RDS"

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic on port 3000 from any IP
  }

  egress {
    from_port   = 4510
    to_port     = 4510
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic to RDS (adjust to your VPC CIDR)
  }
  
  tags = {
    Name = "EC2-SG"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS instance allowing EC2 access"

  ingress {
    from_port   = 4510
    to_port     = 4510
    protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any IP (adjust to your VPC CIDR)
  }
  
  # It's also good practice to allow outbound traffic
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

resource "aws_instance" "ec2_instance" {
  ami                 = "ami-df5de72bdb3b"
  instance_type       = "t3.nano"
  key_name            = aws_key_pair.my_key.key_name # Reference the key pair
  security_groups     = [aws_security_group.ec2_sg.name] # Attach security group
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name # Attach IAM instance profile

  user_data           = file("install.sh")

  tags = {
    Name = "Shopla"
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20                    # Storage size in GB
  engine               = "postgres"            # Database engine
  engine_version       = "13.4"                # PostgreSQL version
  instance_class       = "db.t3.micro"         # Instance type
  identifier           = "postgres-instance"   # Unique name for the instance
  username             = "shopla"               # DB master username
  password             = "123456" # DB master password
  db_name              = "shopla"           # Initial database name
  publicly_accessible  = true                 # Set to true if you want public access
  skip_final_snapshot  = true                  # Skips the final snapshot upon deletion
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  # Reference your security group
  port                 = 4510  # Specify your desired port here

  tags = {
    Name = "ShoplaDB"
  }
}
