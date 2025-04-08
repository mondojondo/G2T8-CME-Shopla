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
