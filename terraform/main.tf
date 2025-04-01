terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.93.0"  # Specify your AWS provider version
      configuration_aliases = [
        aws.ap_southeast_1,
        aws.ap_east_1
      ]
    }
  }
}

# Configure multiple AWS providers for different regions
provider "aws" {
  alias = "ap_southeast_1"
  
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "ap-southeast-1"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    rds = "http://localhost:4566"
  }

  ignore_tags {
    key_prefixes = ["aws:"]
  }
}

provider "aws" {
  alias = "ap_east_1"
  
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "ap-east-1"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    rds = "http://localhost:4566"
  }

  ignore_tags {
    key_prefixes = ["aws:"]
  }
}

# Override default VPCs with unique CIDRs per region
resource "aws_vpc" "singapore" {
  provider   = aws.ap_southeast_1
  cidr_block = "10.0.0.0/16"  # Unique to ap-southeast-1
  tags = {
    Name = "singapore-vpc"
  }
}

resource "aws_vpc" "hongkong" {
  provider   = aws.ap_east_1
  cidr_block = "10.1.0.0/16"  # Unique to ap-east-1
  tags = {
    Name = "hongkong-vpc"
  }
}

resource "aws_key_pair" "shared_key" {
  key_name   = "my-global-key"  # Same name works in LocalStack
  public_key = file("~/.ssh/id_rsa.pub") 
}

# Southeast Asia (Singapore) Region Resources
module "ap_southeast_1" {
  source = "./modules/region"
  providers = {
    aws = aws.ap_southeast_1  
  }
  
  region_name     = "ap-southeast-1"
  key_name        = aws_key_pair.shared_key.key_name 
  vpc_id          = aws_vpc.singapore.id
  vpc_cidr_block  = aws_vpc.singapore.cidr_block
}

# East Asia (Hong Kong) Region Resources
module "ap_east_1" {
  source = "./modules/region"
  providers = {
    aws = aws.ap_east_1 
  }
  
  region_name     = "ap-east-1"
  key_name        = aws_key_pair.shared_key.key_name 
  vpc_id          = aws_vpc.hongkong.id
  vpc_cidr_block  = aws_vpc.hongkong.cidr_block
}