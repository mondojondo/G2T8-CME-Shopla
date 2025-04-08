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

# #################################
# # SINGAPORE REGION
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

# #################################
# # THAILAND REGION
# #################################
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