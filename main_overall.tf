
# #################################
# # VPCs & AZs
# #################################
resource "aws_vpc" "vpc_sg" {
  provider   = aws.sg
  cidr_block = "10.1.0.0/16"
}

resource "aws_internet_gateway" "igw_sg" {
  provider = aws.sg
  vpc_id   = aws_vpc.vpc_sg.id
}

resource "aws_subnet" "public_a_sg" {
  provider                = aws.sg
  vpc_id                  = aws_vpc.vpc_sg.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b_sg" {
  provider                = aws.sg
  vpc_id                  = aws_vpc.vpc_sg.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_a_sg" {
  provider          = aws.sg
  vpc_id            = aws_vpc.vpc_sg.id
  cidr_block        = "10.1.11.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "private_b_sg" {
  provider          = aws.sg
  vpc_id            = aws_vpc.vpc_sg.id
  cidr_block        = "10.1.12.0/24"
  availability_zone = "ap-southeast-1b"
}


resource "aws_vpc" "vpc_th" {
  provider   = aws.th
  cidr_block = "10.2.0.0/16"
}

resource "aws_internet_gateway" "igw_th" {
  provider = aws.th
  vpc_id   = aws_vpc.vpc_th.id
}

resource "aws_subnet" "public_a_th" {
  provider                = aws.th
  vpc_id                  = aws_vpc.vpc_th.id
  cidr_block              = "10.2.1.0/24"
  availability_zone       = "ap-southeast-7a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b_th" {
  provider                = aws.th
  vpc_id                  = aws_vpc.vpc_th.id
  cidr_block              = "10.2.2.0/24"
  availability_zone       = "ap-southeast-7b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_a_th" {
  provider          = aws.th
  vpc_id            = aws_vpc.vpc_th.id
  cidr_block        = "10.2.11.0/24"
  availability_zone = "ap-southeast-7a"
}

resource "aws_subnet" "private_b_th" {
  provider          = aws.th
  vpc_id            = aws_vpc.vpc_th.id
  cidr_block        = "10.2.12.0/24"
  availability_zone = "ap-southeast-7b"
}

# #################################
# # Security Groups
# #################################
resource "aws_security_group" "asg_securitygroup_sg" {
  name        = "asg-securitygroup-sg"
  description = "Security group for ASG instances"
  vpc_id      = aws_vpc.vpc_sg.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS traffic from anywhere
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP for SSH access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

resource "aws_security_group" "aurora_securitygroup_sg" {
  name        = "aurora-securitygroup-sg"
  description = "Security group for Aurora Cluster"
  vpc_id      = aws_vpc.vpc_sg.id

  ingress {
    description      = "Allow inbound traffic on port 4510"
    from_port        = 4510
    to_port          = 4510
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/16"] # Replace with your trusted CIDR range
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "asg_securitygroup_th" {
  name        = "asg-securitygroup-th"
  description = "Security group for ASG instances"
  vpc_id      = aws_vpc.vpc_th.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS traffic from anywhere
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP for SSH access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

resource "aws_security_group" "aurora_securitygroup_th" {
  name        = "aurora-securitygroup-th"
  description = "Security group for Aurora Cluster"
  vpc_id      = aws_vpc.vpc_th.id

  ingress {
    description      = "Allow inbound traffic on port 4510"
    from_port        = 4510
    to_port          = 4510
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/16"] # Replace with your trusted CIDR range
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# #################################
# # AUTO SCALING GROUPS
# #################################

resource "aws_launch_template" "lt_sg_a" {
  provider        = aws.sg
  name_prefix     = "lt-sg-a"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t3.medium"
  user_data       = file("install.sh")

  vpc_security_group_ids = [aws_security_group.asg_securitygroup_sg.id] #specifies the set of security group IDs that each newly-created EC2 instance must be associated with
}

resource "aws_autoscaling_group" "asg_sg_a" {
  provider            = aws.sg

  launch_template {
    id      = aws_launch_template.lt_sg_a.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_a_sg.id]

  min_size             = 1 # Ensures at least one instance per AZ.
  desired_capacity     = 1 # Starts with one instance in each AZ.
  max_size             = 24 # Allows scaling up to 24 instances.
}

resource "aws_launch_template" "lt_sg_b" {
  provider        = aws.sg
  name_prefix     = "lt-sg-a"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t3.medium"
  user_data       = file("install.sh")

  vpc_security_group_ids = [aws_security_group.asg_securitygroup_sg.id] 
}

resource "aws_autoscaling_group" "asg_sg_b" {
  provider            = aws.sg

  launch_template {
    id      = aws_launch_template.lt_sg_b.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_b_sg.id]

  min_size             = 1 # Ensures at least one instance per AZ.
  desired_capacity     = 1 # Starts with one instance in each AZ.
  max_size             = 24 # Allows scaling up to four instances.
}

resource "aws_launch_template" "lt_th_a" {
  provider        = aws.th
  name_prefix     = "lt-th-a"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t3.medium"
  user_data       = file("install.sh")

  vpc_security_group_ids = [aws_security_group.asg_securitygroup_th.id]
}


resource "aws_autoscaling_group" "asg_th_a" {
  provider            = aws.th

  launch_template {
    id      = aws_launch_template.lt_th_a.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_a_th.id]

  min_size             = 1 # Ensures at least one instance per AZ.
  desired_capacity     = 1 # Starts with one instance in each AZ.
  max_size             = 24 # Allows scaling up to four instances.
}

resource "aws_launch_template" "lt_th_b" {
  provider        = aws.th
  name_prefix     = "lt-th-b"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t3.medium"
  user_data       = file("install.sh")

  vpc_security_group_ids = [aws_security_group.asg_securitygroup_th.id]
}

resource "aws_autoscaling_group" "asg_th_b" {
  provider            = aws.th

  launch_template {
    id      = aws_launch_template.lt_th_b.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_b_th.id]

  min_size             = 1 # Ensures at least one instance per AZ.
  desired_capacity     = 1 # Starts with one instance in each AZ.
  max_size             = 24 # Allows scaling up to four instances.
}

# #################################
# # AURORA CLUSTER
# #################################

# Global Database
resource "aws_rds_global_cluster" "aurora_global_cluster" {
  global_cluster_identifier = "aurora-global-cluster-shopla"
  engine                    = "aurora-postgresql"
  engine_version            = "13.8"
  database_name             = "shopla"
}

# Primary Aurora Cluster
resource "aws_rds_cluster" "aurora_cluster" {
  provider                = aws.sg
  cluster_identifier      = "aurora-cluster-shopla"
  availability_zones      = ["ap-southeast-1a", "ap-southeast-1b"]
  engine                  = aws_rds_global_cluster.aurora_global_cluster.engine
  engine_version          = aws_rds_global_cluster.aurora_global_cluster.engine_version
  database_name           = aws_rds_global_cluster.aurora_global_cluster.database_name
  master_username         = var.db_username
  master_password         = var.db_password
  port                    = 4510

  global_cluster_identifier = aws_rds_global_cluster.aurora_global_cluster.id

  vpc_security_group_ids = [aws_security_group.aurora_securitygroup_sg.id]
}

# Primary Aurora Cluster Instances
resource "aws_rds_cluster_instance" "aurora_instances" {
  provider           = aws.sg
  for_each           = toset(aws_rds_cluster.aurora_cluster.availability_zones)
  identifier         = "aurora-instance-${each.key}"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.aurora_cluster.engine

  # Assign each instance to its corresponding availability zone
  availability_zone  = each.key
}

resource "aws_rds_cluster" "secondary_aurora_cluster" {
  provider              = aws.th
  cluster_identifier    = "aurora-cluster-shopla-secondary"
  availability_zones    = ["ap-southeast-7a", "ap-southeast-7b"]
  engine                = aws_rds_global_cluster.aurora_global_cluster.engine
  engine_version        = aws_rds_global_cluster.aurora_global_cluster.engine_version
  skip_final_snapshot   = aws_rds_cluster.aurora_cluster.skip_final_snapshot

  global_cluster_identifier = aws_rds_global_cluster.aurora_global_cluster.id

  vpc_security_group_ids = [aws_security_group.aurora_securitygroup_th.id]

  lifecycle {
    ignore_changes = [
      replication_source_identifier
    ]
  }

  depends_on = [
    aws_rds_cluster_instance.aurora_instances
  ]
}

# Secondary Aurora Cluster Instances
resource "aws_rds_cluster_instance" "secondary_aurora_instances" {
  provider              = aws.th
  for_each              = toset(aws_rds_cluster.secondary_aurora_cluster.availability_zones)
  identifier            = "secondary-aurora-instance-${each.key}"
  cluster_identifier    = aws_rds_cluster.secondary_aurora_cluster.id
  instance_class        = "db.r5.large"
  engine                = aws_rds_cluster.aurora_cluster.engine

  # Assign each instance to its corresponding availability zone
  availability_zone     = each.key
}