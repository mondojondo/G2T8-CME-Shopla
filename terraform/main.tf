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
    cloudwatch      = "http://localhost:4566"
    logs            = "http://localhost:4566"
  }
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
  monitoring          = true

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

resource "aws_cloudwatch_log_group" "shopla_logs" {
  name              = "/aws/ec2/shopla"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_metric_filter" "error_metric_filter" {
  name            = "shopla-app-error-filter"
  pattern         = "[timestamp, level=\"ERROR\", ...]"
  log_group_name  = aws_cloudwatch_log_group.shopla_logs.name
  
  metric_transformation {
    name      = "ShoplaAppErrorCount"
    namespace = "Shopla/Custom"
    value     = "1"
  }
  
}

resource "aws_cloudwatch_log_metric_filter" "http_5xx_metric_filter" {
  name            = "shopla-5xx-error-filter"
  pattern         = "[timestamp, statusCode=5*, ...]"
  log_group_name  = aws_cloudwatch_log_group.shopla_logs.name
  
  metric_transformation {
    name      = "Shopla5xxCount"
    namespace = "Shopla/Custom"
    value     = "1"
  }
  
}

resource "aws_sns_topic" "shopla_sns_topic" {
  name = "shopla-monitoring-topic"
  
  tags = {
    Name = "Shopla-SNSTopic"
  }
}

resource "aws_sns_topic_subscription" "shopla_email_subscription" {
  topic_arn = aws_sns_topic.shopla_sns_topic.arn
  protocol  = "email"
  endpoint  = "jasperchong21@gmail.com"
  
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "shopla-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.shopla_sns_topic.arn]
  dimensions = {
    InstanceId = aws_instance.ec2_instance.id
  }
  
  tags = {
    Name = "Shopla-CPUAlarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_alarm" {
  alarm_name          = "shopla-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alarm when status check fails"
  alarm_actions       = [aws_sns_topic.shopla_sns_topic.arn]
  dimensions = {
    InstanceId = aws_instance.ec2_instance.id
  }
  
  tags = {
    Name = "Shopla-StatusCheckAlarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_count_alarm" {
  alarm_name          = "shopla-high-error-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ShoplaAppErrorCount"
  namespace           = "Shopla/Custom"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm when application errors exceed threshold"
  alarm_actions       = [aws_sns_topic.shopla_sns_topic.arn]
  
  tags = {
    Name = "Shopla-ErrorCountAlarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "http_5xx_alarm" {
  alarm_name          = "shopla-high-5xx-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Shopla5xxCount"
  namespace           = "Shopla/Custom"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm when HTTP 5xx errors exceed threshold"
  alarm_actions       = [aws_sns_topic.shopla_sns_topic.arn]
  
  tags = {
    Name = "Shopla-5xxCountAlarm"
  }
}
