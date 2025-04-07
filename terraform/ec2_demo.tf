resource "aws_key_pair" "my_key" {
  key_name   = "my-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "ec2_instance" {
  ami                     = "ami-df5de72bdb3b"
  instance_type           = "t3.nano"
  key_name                = aws_key_pair.my_key.key_name # Reference the key pair

  user_data               = file("install.sh")

  tags = {
    Name = "Shopla"
  }
}

# ============================================================

# resource "aws_vpc" "vpc_sg" {
#   provider   = aws.sg
#   cidr_block = "10.1.0.0/16"
# }

# resource "aws_internet_gateway" "igw_sg" {
#   provider = aws.sg
#   vpc_id   = aws_vpc.vpc_sg.id
# }

# resource "aws_subnet" "public_a_sg" {
#   provider                = aws.sg
#   vpc_id                  = aws_vpc.vpc_sg.id
#   cidr_block              = "10.1.1.0/24"
#   availability_zone       = "ap-southeast-1a"
#   map_public_ip_on_launch = true
# }

# resource "aws_subnet" "public_b_sg" {
#   provider                = aws.sg
#   vpc_id                  = aws_vpc.vpc_sg.id
#   cidr_block              = "10.1.2.0/24"
#   availability_zone       = "ap-southeast-1b"
#   map_public_ip_on_launch = true
# }

# resource "aws_subnet" "private_a_sg" {
#   provider          = aws.sg
#   vpc_id            = aws_vpc.vpc_sg.id
#   cidr_block        = "10.1.11.0/24"
#   availability_zone = "ap-southeast-1a"
# }

# resource "aws_subnet" "private_b_sg" {
#   provider          = aws.sg
#   vpc_id            = aws_vpc.vpc_sg.id
#   cidr_block        = "10.1.12.0/24"
#   availability_zone = "ap-southeast-1b"
# }


# resource "aws_vpc" "vpc_th" {
#   provider   = aws.th
#   cidr_block = "10.2.0.0/16"
# }

# resource "aws_internet_gateway" "igw_th" {
#   provider = aws.th
#   vpc_id   = aws_vpc.vpc_th.id
# }

# resource "aws_subnet" "public_a_th" {
#   provider                = aws.th
#   vpc_id                  = aws_vpc.vpc_th.id
#   cidr_block              = "10.2.1.0/24"
#   availability_zone       = "ap-southeast-2a"
#   map_public_ip_on_launch = true
# }

# resource "aws_subnet" "public_b_th" {
#   provider                = aws.th
#   vpc_id                  = aws_vpc.vpc_th.id
#   cidr_block              = "10.2.2.0/24"
#   availability_zone       = "ap-southeast-2b"
#   map_public_ip_on_launch = true
# }

# resource "aws_subnet" "private_a_th" {
#   provider          = aws.th
#   vpc_id            = aws_vpc.vpc_th.id
#   cidr_block        = "10.2.11.0/24"
#   availability_zone = "ap-southeast-2a"
# }

# resource "aws_subnet" "private_b_th" {
#   provider          = aws.th
#   vpc_id            = aws_vpc.vpc_th.id
#   cidr_block        = "10.2.12.0/24"
#   availability_zone = "ap-southeast-2b"
# }

# resource "aws_launch_template" "lt_sg" {
#   provider        = aws.sg
#   name_prefix     = "lt-sg"
#   image_id        = "ami-df5de72bdb3b"
#   instance_type   = "t2.micro"
#   user_data       = file("install.sh")
# }

# resource "aws_autoscaling_group" "asg_sg" {
#   provider            = aws.sg
#   desired_capacity    = 1
#   max_size            = 2
#   min_size            = 1
#   vpc_zone_identifier = [aws_subnet.private_a_sg.id, aws_subnet.private_b_sg.id]

#   launch_template {
#     id      = aws_launch_template.lt_sg.id
#     version = "$Latest"
#   }
# }

# resource "aws_launch_template" "lt_th" {
#   provider        = aws.th
#   name_prefix     = "lt-th"
#   image_id        = "ami-df5de72bdb3b"
#   instance_type   = "t2.micro"
#   user_data       = file("install.sh")
# }

# resource "aws_autoscaling_group" "asg_th" {
#   provider            = aws.th
#   desired_capacity    = 1
#   max_size            = 2
#   min_size            = 1
#   vpc_zone_identifier = [aws_subnet.private_a_th.id, aws_subnet.private_b_th.id]

#   launch_template {
#     id      = aws_launch_template.lt_th.id
#     version = "$Latest"
#   }
# }

# # Global Database
# resource "aws_rds_global_cluster" "aurora_global_cluster" {
#   global_cluster_identifier = "aurora-global-cluster-shopla"
#   engine                    = "aurora-postgresql"
#   engine_version            = "13.8"
#   database_name             = "shopla"
# }

# # Primary Aurora Cluster
# resource "aws_rds_cluster" "aurora_cluster" {
#   provider                = aws.sg
#   cluster_identifier      = "aurora-cluster-shopla"
#   availability_zones      = ["ap-southeast-1a", "ap-southeast-1b"]
#   engine                  = aws_rds_global_cluster.aurora_global_cluster.engine
#   engine_version          = aws_rds_global_cluster.aurora_global_cluster.engine_version
#   database_name           = aws_rds_global_cluster.aurora_global_cluster.database_name
#   master_username         = "shopla"
#   master_password         = "123456"
#   port                    = 4510

#   global_cluster_identifier = aws_rds_global_cluster.aurora_global_cluster.id
# }

# # Primary Aurora Cluster Instances
# resource "aws_rds_cluster_instance" "aurora_instances" {
#   provider           = aws.sg
#   for_each           = toset(aws_rds_cluster.aurora_cluster.availability_zones)
#   identifier         = "aurora-instance-${each.key}"
#   cluster_identifier = aws_rds_cluster.aurora_cluster.id
#   instance_class     = "db.r5.large"
#   engine             = aws_rds_cluster.aurora_cluster.engine

#   # Assign each instance to its corresponding availability zone
#   availability_zone  = each.key
# }

# resource "aws_rds_cluster" "secondary_aurora_cluster" {
#   provider              = aws.th
#   cluster_identifier    = "aurora-cluster-shopla-secondary"
#   availability_zones    = ["ap-southeast-2a", "ap-southeast-2b"]
#   engine                = aws_rds_global_cluster.aurora_global_cluster.engine
#   engine_version        = aws_rds_global_cluster.aurora_global_cluster.engine_version
#   skip_final_snapshot   = aws_rds_cluster.aurora_cluster.skip_final_snapshot

#   global_cluster_identifier = aws_rds_global_cluster.aurora_global_cluster.id

#   lifecycle {
#     ignore_changes = [
#       replication_source_identifier
#     ]
#   }

#   depends_on = [
#     aws_rds_cluster_instance.aurora_instances
#   ]
# }

# # Secondary Aurora Cluster Instances
# resource "aws_rds_cluster_instance" "secondary_aurora_instances" {
#   provider              = aws.th
#   for_each              = toset(aws_rds_cluster.secondary_aurora_cluster.availability_zones)
#   identifier            = "secondary-aurora-instance-${each.key}"
#   cluster_identifier    = aws_rds_cluster.secondary_aurora_cluster.id
#   instance_class        = "db.r5.large"
#   engine                = aws_rds_cluster.aurora_cluster.engine

#   # Assign each instance to its corresponding availability zone
#   availability_zone     = each.key
# }