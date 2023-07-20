resource "aws_launch_template" "front_template" {
  name_prefix = "front-"
  instance_type = "t2.micro"
  image_id = "ami-07ce6ac5ac8a0ee6f"

  network_interfaces {
    associate_public_ip_address = false
  }
  #security_groups = [aws_security_group.front_instance.id]

  tags = {
    Application = "Front"
  }
}

resource "aws_launch_template" "backend_template" {
  name_prefix = "back-"
  instance_type = "t2.micro"
  image_id = "ami-07ce6ac5ac8a0ee6f"

  network_interfaces {
    associate_public_ip_address = false
  }
  #security_groups = [aws_security_group.backend_instance.id]

  tags = {
    Application = "Back"
  }
}

resource "aws_autoscaling_group" "internet_facing_ASG" {
  name                 = "internet_facing_ASG"
  launch_template {
    id      = aws_launch_template.front_template.id
    version = "$Latest"
  }
  min_size             = 1
  desired_capacity     = 1 
  max_size             = 2
  vpc_zone_identifier  = module.vpc.public_subnets
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "internal_ASG" {
  name                 = "internal_ASG"
  launch_template {
    id      = aws_launch_template.backend_template.id
    version = "$Latest"
  }
  min_size             = 1
  desired_capacity     = 1 
  max_size             = 2

  vpc_zone_identifier  = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_security_group" "front_instance" {
  name = "front_instance_sec_group"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.internet_facing_elb.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "backend_instance" {
  name = "backend_instance_sec_group"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.int_elb.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

resource "aws_autoscaling_attachment" "front" {
  autoscaling_group_name = aws_autoscaling_group.internet_facing_ASG.id
  lb_target_group_arn   = aws_lb_target_group.front_instances.arn
}

resource "aws_autoscaling_attachment" "backend" {
  autoscaling_group_name = aws_autoscaling_group.internal_ASG.id
  lb_target_group_arn   = aws_lb_target_group.backend_instances.arn
}