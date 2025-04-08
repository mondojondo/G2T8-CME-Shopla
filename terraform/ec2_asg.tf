
resource "aws_launch_template" "lt_sg_a" {
  provider        = aws.sg
  name_prefix     = "lt-sg-a"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t3.medium"
  user_data       = file("install.sh")
}

resource "aws_autoscaling_group" "asg_sg_a" {
  provider            = aws.sg

  launch_template {
    id      = aws_launch_template.lt_sg_a.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_a_sg.id]

  min_size             = 1 # Ensures at least one instance per AZ.
  desired_capacity     = 1 # Starts with one instance in each AZ.
  max_size             = 24 # Allows scaling up to 24 instances.
}

resource "aws_launch_template" "lt_sg_b" {
  provider        = aws.sg
  name_prefix     = "lt-sg-a"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t3.medium"
  user_data       = file("install.sh")
}

resource "aws_autoscaling_group" "asg_sg_b" {
  provider            = aws.sg

  launch_template {
    id      = aws_launch_template.lt_sg_b.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_b_sg.id]

  min_size             = 1 # Ensures at least one instance per AZ.
  desired_capacity     = 1 # Starts with one instance in each AZ.
  max_size             = 24 # Allows scaling up to four instances.
}

resource "aws_launch_template" "lt_th_a" {
  provider        = aws.th
  name_prefix     = "lt-th-a"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t3.medium"
  user_data       = file("install.sh")
}


resource "aws_autoscaling_group" "asg_th_a" {
  provider            = aws.th

  launch_template {
    id      = aws_launch_template.lt_th_a.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_a_th.id]

  min_size             = 1 # Ensures at least one instance per AZ.
  desired_capacity     = 1 # Starts with one instance in each AZ.
  max_size             = 24 # Allows scaling up to four instances.
}

resource "aws_launch_template" "lt_th_b" {
  provider        = aws.th
  name_prefix     = "lt-th-b"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t3.medium"
  user_data       = file("install.sh")
}


resource "aws_autoscaling_group" "asg_th_b" {
  provider            = aws.th

  launch_template {
    id      = aws_launch_template.lt_th_b.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_b_th.id]

  min_size             = 1 # Ensures at least one instance per AZ.
  desired_capacity     = 1 # Starts with one instance in each AZ.
  max_size             = 24 # Allows scaling up to four instances.
}

## ===========================
## Share launch template across all ASGs (not working)
# resource "aws_launch_template" "lt" {
#   name_prefix     = "launch-template-"
#   image_id        = "ami-df5de72bdb3b"
#   instance_type   = "t3.medium"
#   user_data       = file("install.sh")

#   tag_specifications {
#     resource_type = "instance"

#     tags = {
#       Name = "lt-instance"
#     }
#   }
# }

# resource "aws_autoscaling_group" "asg_sg_a" {
#   provider            = aws.sg

#   launch_template {
#     id      = aws_launch_template.lt.id
#     version = "$Latest"
#   }

#   vpc_zone_identifier = [aws_subnet.private_a_sg.id]

#   min_size             = 1 # Ensures at least one instance per AZ.
#   desired_capacity     = 1 # Starts with one instance in each AZ.
#   max_size             = 24 # Allows scaling up to four instances.
# }

# resource "aws_autoscaling_group" "asg_sg_b" {
#   provider            = aws.sg

#   launch_template {
#     id      = aws_launch_template.lt.id
#     version = "$Latest"
#   }

#   vpc_zone_identifier = [aws_subnet.private_b_sg.id]

#   min_size             = 1 # Ensures at least one instance per AZ.
#   desired_capacity     = 1 # Starts with one instance in each AZ.
#   max_size             = 24 # Allows scaling up to four instances.
# }

# resource "aws_autoscaling_group" "asg_th_a" {
#   provider            = aws.sg

#   launch_template {
#     id      = aws_launch_template.lt.id
#     version = "$Latest"
#   }

#   vpc_zone_identifier = [aws_subnet.private_a_th.id]

#   min_size             = 1 # Ensures at least one instance per AZ.
#   desired_capacity     = 1 # Starts with one instance in each AZ.
#   max_size             = 24 # Allows scaling up to four instances.
# }

# resource "aws_autoscaling_group" "asg_th_b" {
#   provider            = aws.sg

#   launch_template {
#     id      = aws_launch_template.lt.id
#     version = "$Latest"
#   }

#   vpc_zone_identifier = [aws_subnet.private_b_th.id]

#   min_size             = 1 # Ensures at least one instance per AZ.
#   desired_capacity     = 1 # Starts with one instance in each AZ.
#   max_size             = 24 # Allows scaling up to four instances.
# }
