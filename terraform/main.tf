terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias      = "sg"
  region     = "ap-southeast-1"
  access_key = "mock"
  secret_key = "mock"
  endpoints {
    ec2         = "http://localhost:4566"
    rds         = "http://localhost:4566"
    elbv2       = "http://localhost:4566"
    s3          = "http://localhost:4566"
    cloudfront  = "http://localhost:4566"
    wafv2       = "http://localhost:4566"
    route53     = "http://localhost:4566"
    autoscaling = "http://localhost:4566"
  }
}

provider "aws" {
  alias      = "th"
  region     = "ap-southeast-2"
  access_key = "mock"
  secret_key = "mock"
  endpoints {
    ec2         = "http://localhost:4567"
    rds         = "http://localhost:4567"
    elbv2       = "http://localhost:4567"
    s3          = "http://localhost:4567"
    cloudfront  = "http://localhost:4567"
    wafv2       = "http://localhost:4567"
    route53     = "http://localhost:4567"
    autoscaling = "http://localhost:4567"
  }
}

# #################################
# # SINGAPORE REGION
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

resource "aws_nat_gateway" "nat_sg" {
  provider  = aws.sg
  subnet_id = aws_subnet.public_a_sg.id
  tags = {
    Name = "nat-sg (mock)"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes         = [allocation_id]
  }
}

resource "aws_s3_bucket" "bucket_sg" {
  provider = aws.sg
  bucket   = "bucket-sg"
}

resource "aws_alb" "alb_sg" {
  provider           = aws.sg
  name               = "alb-sg"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a_sg.id, aws_subnet.public_b_sg.id]
}

resource "aws_launch_template" "lt_sg" {
  provider        = aws.sg
  name_prefix     = "lt-sg"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t2.micro"
  user_data       = file("install.sh")
}

resource "aws_autoscaling_group" "asg_sg" {
  provider            = aws.sg
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_a_sg.id, aws_subnet.private_b_sg.id]

  launch_template {
    id      = aws_launch_template.lt_sg.id
    version = "$Latest"
  }
}

resource "aws_cloudfront_distribution" "cf_sg" {
  provider = aws.sg

  origin {
    domain_name = aws_s3_bucket.bucket_sg.bucket_regional_domain_name
    origin_id   = "s3-sg"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-sg"
    viewer_protocol_policy = "allow-all"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_wafv2_web_acl" "waf_sg" {
  provider = aws.sg
  name     = "waf-sg"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "waf-sg"
    sampled_requests_enabled   = false
  }
}

#################################
# THAILAND REGION
#################################

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
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b_th" {
  provider                = aws.th
  vpc_id                  = aws_vpc.vpc_th.id
  cidr_block              = "10.2.2.0/24"
  availability_zone       = "ap-southeast-2b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_a_th" {
  provider          = aws.th
  vpc_id            = aws_vpc.vpc_th.id
  cidr_block        = "10.2.11.0/24"
  availability_zone = "ap-southeast-2a"
}

resource "aws_subnet" "private_b_th" {
  provider          = aws.th
  vpc_id            = aws_vpc.vpc_th.id
  cidr_block        = "10.2.12.0/24"
  availability_zone = "ap-southeast-2b"
}

resource "aws_nat_gateway" "nat_th" {
  provider  = aws.th
  subnet_id = aws_subnet.public_a_th.id
  tags = {
    Name = "nat-th (mock)"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes         = [allocation_id]
  }
}

resource "aws_s3_bucket" "bucket_th" {
  provider = aws.th
  bucket   = "bucket-th"
}

resource "aws_alb" "alb_th" {
  provider           = aws.th
  name               = "alb-th"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a_th.id, aws_subnet.public_b_th.id]
}

resource "aws_launch_template" "lt_th" {
  provider        = aws.th
  name_prefix     = "lt-th"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t2.micro"
  user_data       = file("install.sh")
}

resource "aws_autoscaling_group" "asg_th" {
  provider            = aws.th
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_a_th.id, aws_subnet.private_b_th.id]

  launch_template {
    id      = aws_launch_template.lt_th.id
    version = "$Latest"
  }
}

resource "aws_cloudfront_distribution" "cf_th" {
  provider = aws.th

  origin {
    domain_name = aws_s3_bucket.bucket_th.bucket_regional_domain_name
    origin_id   = "s3-th"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-th"
    viewer_protocol_policy = "allow-all"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_wafv2_web_acl" "waf_th" {
  provider = aws.th
  name     = "waf-th"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "waf-th"
    sampled_requests_enabled   = false
  }
}

#################################
# ROUTE 53 (shared)
#################################

resource "aws_route53_zone" "root" {
  provider = aws.sg
  name     = "shopla.com"
}

resource "aws_route53_record" "latency_sg" {
  provider       = aws.sg
  zone_id        = aws_route53_zone.root.zone_id
  name           = "app.shopla.com"
  type           = "A"
  set_identifier = "sg"

  alias {
    name                   = aws_cloudfront_distribution.cf_sg.domain_name
    zone_id                = aws_cloudfront_distribution.cf_sg.hosted_zone_id
    evaluate_target_health = false
  }

  latency_routing_policy {
    region = "ap-southeast-1"
  }
}

resource "aws_route53_record" "latency_th" {
  provider       = aws.sg
  zone_id        = aws_route53_zone.root.zone_id
  name           = "app.shopla.com"
  type           = "A"
  set_identifier = "th"

  alias {
    name                   = aws_cloudfront_distribution.cf_th.domain_name
    zone_id                = aws_cloudfront_distribution.cf_th.hosted_zone_id
    evaluate_target_health = false
  }

  latency_routing_policy {
    region = "ap-southeast-2"
  }
}