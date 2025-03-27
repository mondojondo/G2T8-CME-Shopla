# IAM Roles for the online shopping system

#-----------------------------------------------
# EC2 Application Role with RDS and S3 access
#-----------------------------------------------
resource "aws_iam_role" "ec2_application_role" {
  name = "ec2-application-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "EC2ApplicationRole"
    Environment = "Production"
  }
}

# Policy for RDS access
resource "aws_iam_policy" "rds_access_policy" {
  name        = "rds-access-policy"
  description = "Policy for EC2 to access RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "rds:Connect",
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters",
        "rds-db:connect"
      ]
      Resource = "*"
    }]
  })
}

# Policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-access-policy"
  description = "Policy for EC2 to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ]
      Resource = [
        "arn:aws:s3:::shopla-*",
        "arn:aws:s3:::shopla-*/*"
      ]
    }]
  })
}

# Attach policies to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_rds_policy_attach" {
  role       = aws_iam_role.ec2_application_role.name
  policy_arn = aws_iam_policy.rds_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attach" {
  role       = aws_iam_role.ec2_application_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-application-profile"
  role = aws_iam_role.ec2_application_role.name
}

#-----------------------------------------------
# Load Balancer Role
#-----------------------------------------------
resource "aws_iam_role" "lb_role" {
  name = "load-balancer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "elasticloadbalancing.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "LoadBalancerRole"
    Environment = "Production"
  }
}

resource "aws_iam_policy" "lb_policy" {
  name        = "load-balancer-policy"
  description = "Policy for Load Balancer operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "elasticloadbalancing:*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lb_policy_attach" {
  role       = aws_iam_role.lb_role.name
  policy_arn = aws_iam_policy.lb_policy.arn
}

#-----------------------------------------------
# CloudWatch Monitoring Role
#-----------------------------------------------
resource "aws_iam_role" "monitoring_role" {
  name = "cloudwatch-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "cloudwatch.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "MonitoringRole"
    Environment = "Production"
  }
}

resource "aws_iam_policy" "monitoring_policy" {
  name        = "monitoring-policy"
  description = "Policy for CloudWatch monitoring operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "ec2:DescribeTags",
        "ec2:DescribeInstances"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "monitoring_policy_attach" {
  role       = aws_iam_role.monitoring_role.name
  policy_arn = aws_iam_policy.monitoring_policy.arn
}

#-----------------------------------------------
# Backup Role
#-----------------------------------------------
resource "aws_iam_role" "backup_role" {
  name = "backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "BackupRole"
    Environment = "Production"
  }
}

resource "aws_iam_policy" "backup_policy" {
  name        = "backup-policy"
  description = "Policy for AWS Backup operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "backup:*",
        "rds:CreateDBSnapshot",
        "rds:DeleteDBSnapshot",
        "rds:DescribeDBSnapshots",
        "rds:ListTagsForResource",
        "rds:AddTagsToResource",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "ec2:CreateSnapshot",
        "ec2:DeleteSnapshot",
        "ec2:DescribeSnapshots",
        "ec2:DescribeVolumes",
        "tag:GetResources"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy_attach" {
  role       = aws_iam_role.backup_role.name
  policy_arn = aws_iam_policy.backup_policy.arn
}

#-----------------------------------------------
# Auto Scaling Role
#-----------------------------------------------
resource "aws_iam_role" "autoscaling_role" {
  name = "autoscaling-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "autoscaling.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "AutoScalingRole"
    Environment = "Production"
  }
}

resource "aws_iam_policy" "autoscaling_policy" {
  name        = "autoscaling-policy"
  description = "Policy for Auto Scaling operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:CreateTags",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:DeleteAlarms"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "autoscaling_policy_attach" {
  role       = aws_iam_role.autoscaling_role.name
  policy_arn = aws_iam_policy.autoscaling_policy.arn
}

#-----------------------------------------------
# Outputs
#-----------------------------------------------
output "ec2_role_arn" {
  description = "ARN of the EC2 Application Role"
  value       = aws_iam_role.ec2_application_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 Instance Profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "lb_role_arn" {
  description = "ARN of the Load Balancer Role"
  value       = aws_iam_role.lb_role.arn
}

output "monitoring_role_arn" {
  description = "ARN of the CloudWatch Monitoring Role"
  value       = aws_iam_role.monitoring_role.arn
}

output "backup_role_arn" {
  description = "ARN of the Backup Role"
  value       = aws_iam_role.backup_role.arn
}

output "autoscaling_role_arn" {
  description = "ARN of the Auto Scaling Role"
  value       = aws_iam_role.autoscaling_role.arn
}

