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

