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