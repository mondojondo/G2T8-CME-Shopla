#-----------------------------------------------
# IAM Groups and Policies for Team Access
#-----------------------------------------------

# Administrator Group
resource "aws_iam_group" "administrators" {
  name = "administrators"
}

# Developer Group
resource "aws_iam_group" "developers" {
  name = "developers"
}

# Operator Group
resource "aws_iam_group" "operators" {
  name = "operators"
}

# Administrator Policy - Full Access
resource "aws_iam_policy" "administrator_policy" {
  name        = "administrator-policy"
  description = "Full access for administrators"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

# Developer Policy - EC2, S3, Aurora Read/Write
resource "aws_iam_policy" "developer_policy" {
  name        = "developer-policy"
  description = "EC2, S3, Aurora read/write access for developers"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:Describe*",
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:CreateTags",
          "ec2:CreateKeyPair",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
          "s3:CreateBucket"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "rds:Describe*",
          "rds:CreateDBInstance",
          "rds:ModifyDBInstance",
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:RebootDBInstance",
          "rds:CreateDBCluster",
          "rds:ModifyDBCluster", 
          "rds:DeleteDBCluster",
          "rds:AddTagsToResource",
          "rds:PromoteReadReplica",
          "rds:CreateDBClusterEndpoint",
          "rds:RebootDBInstance",
          "rds:CreateGlobalCluster",
          "rds:DeleteGlobalCluster",
          "rds:ModifyGlobalCluster",
          "rds:AddSourceIdentifierToSubscription",
          "rds:CreateEventSubscription",
          "rds:CrossRegionCommunication",
          "rds:ModifyDBClusterParameterGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# Operator Policy - CloudWatch, EC2 Read-Only, Aurora Read-Only
resource "aws_iam_policy" "operator_policy" {
  name        = "operator-policy"
  description = "CloudWatch, EC2 read-only, Aurora read-only access for operators"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "cloudwatch:*",
          "logs:*",
          "events:*"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ec2:Describe*"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "rds:Describe*",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterEndpoints",
          "rds:DescribeGlobalClusters",
          "rds:DescribeOrderableDBInstanceOptions",
          "rds:DescribeEventSubscriptions",
          "rds:DescribeGlobalClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to groups
resource "aws_iam_group_policy_attachment" "admin_policy_attach" {
  group      = aws_iam_group.administrators.name
  policy_arn = aws_iam_policy.administrator_policy.arn
}

resource "aws_iam_group_policy_attachment" "developer_policy_attach" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developer_policy.arn
}

resource "aws_iam_group_policy_attachment" "operator_policy_attach" {
  group      = aws_iam_group.operators.name
  policy_arn = aws_iam_policy.operator_policy.arn
}

# Placeholder for user creation and group membership
# Uncomment and modify as needed
/*
resource "aws_iam_user" "example_admin" {
  name = "admin1"
}

resource "aws_iam_user" "example_developer" {
  name = "developer1"
}

resource "aws_iam_user" "example_operator" {
  name = "operator1"
}

resource "aws_iam_user_group_membership" "admin_membership" {
  user = aws_iam_user.example_admin.name
  groups = [aws_iam_group.administrators.name]
}

resource "aws_iam_user_group_membership" "developer_membership" {
  user = aws_iam_user.example_developer.name
  groups = [aws_iam_group.developers.name]
}

resource "aws_iam_user_group_membership" "operator_membership" {
  user = aws_iam_user.example_operator.name
  groups = [aws_iam_group.operators.name]
}
*/

#-----------------------------------------------
# EC2 Application Role with RDS and S3 access
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
    Name        = "EC2ApplicationRole"
    Environment = "Production"
  }
}

# Policy for Aurora access
resource "aws_iam_policy" "aurora_access_policy" {
  name        = "aurora-access-policy"
  description = "Policy for EC2 to access Aurora"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "rds:Connect",
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters",
        "rds:DescribeDBClusterEndpoints",
        "rds:DescribeGlobalClusters",
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
resource "aws_iam_role_policy_attachment" "ec2_aurora_policy_attach" {
  role       = aws_iam_role.ec2_application_role.name
  policy_arn = aws_iam_policy.aurora_access_policy.arn
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
resource "aws_iam_role" "load_balancer_role" {
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
    Name        = "LoadBalancerRole"
    Environment = "Production"
  }
}

resource "aws_iam_policy" "load_balancer_policy" {
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

resource "aws_iam_role_policy_attachment" "load_balancer_policy_attach" {
  role       = aws_iam_role.load_balancer_role.name
  policy_arn = aws_iam_policy.load_balancer_policy.arn
}

#-----------------------------------------------
# CloudWatch Monitoring Role
#-----------------------------------------------
resource "aws_iam_role" "cloudwatch_monitoring_role" {
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
    Name        = "MonitoringRole"
    Environment = "Production"
  }
}

resource "aws_iam_policy" "cloudwatch_monitoring_policy" {
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

resource "aws_iam_role_policy_attachment" "cloudwatch_monitoring_policy_attach" {
  role       = aws_iam_role.cloudwatch_monitoring_role.name
  policy_arn = aws_iam_policy.cloudwatch_monitoring_policy.arn
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
    Name        = "BackupRole"
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
        "rds:CreateDBClusterSnapshot",
        "rds:DeleteDBClusterSnapshot",
        "rds:CopyDBClusterSnapshot",
        "rds:DescribeDBClusterSnapshots",
        "rds:RestoreDBClusterFromSnapshot",
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
    Name        = "AutoScalingRole"
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

output "load_balancer_role_arn" {
  description = "ARN of the Load Balancer Role"
  value       = aws_iam_role.load_balancer_role.arn
}

output "cloudwatch_monitoring_role_arn" {
  description = "ARN of the CloudWatch Monitoring Role"
  value       = aws_iam_role.cloudwatch_monitoring_role.arn
}

output "backup_role_arn" {
  description = "ARN of the Backup Role"
  value       = aws_iam_role.backup_role.arn
}

output "autoscaling_role_arn" {
  description = "ARN of the Auto Scaling Role"
  value       = aws_iam_role.autoscaling_role.arn
}