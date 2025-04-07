resource "aws_launch_template" "lt_sg" {
  provider        = aws.sg
  name_prefix     = "lt-sg"
  image_id        = "ami-df5de72bdb3b"
  instance_type   = "t2.micro"
  user_data       = file("install.sh")
}

resource "aws_autoscaling_group" "asg_sg" {
  provider            = aws.sg

  launch_template {
    id      = aws_launch_template.lt_sg.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_a_sg.id, aws_subnet.private_b_sg.id]

  min_size             = 2 # Ensures at least one instance per AZ.
  desired_capacity     = 2 # Starts with one instance in each AZ.
  max_size             = 4 # Allows scaling up to four instances.
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

  launch_template {
    id      = aws_launch_template.lt_th.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_a_th.id, aws_subnet.private_b_th.id]

  min_size             = 2 # Ensures at least one instance per AZ.
  desired_capacity     = 2 # Starts with one instance in each AZ.
  max_size             = 4 # Allows scaling up to four instances.
}