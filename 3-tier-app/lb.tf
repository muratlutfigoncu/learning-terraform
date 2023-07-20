resource "aws_security_group" "internet_facing_elb" {
  name        = "internet-facing-elb-sec-group"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
} 

resource "aws_security_group" "int_elb" {
  name        = "internal-elb-sec-group"
  description = "Allow http inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
} 

resource "aws_lb" "internet_facing_elb" {
  name               = "internet-facing-elb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.internet_facing_elb.id]
  #enable_deletion_protection = true
}

resource "aws_lb" "int_elb" {
  name               = "int-elb"
  internal           = true
  load_balancer_type = "application"
  subnets            = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  security_groups    = [aws_security_group.int_elb.id]

  #enable_deletion_protection = true
}

resource "aws_lb_listener" "internet_facing_elb" {
  load_balancer_arn = aws_lb.internet_facing_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_instances.arn
  }
}

resource "aws_lb_listener" "int_elb" {
  load_balancer_arn = aws_lb.int_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_instances.arn
  }
}

 resource "aws_lb_target_group" "front_instances" {
   name     = "front-instances-target-group"
   port     = 80
   protocol = "HTTP"
   vpc_id   = module.vpc.vpc_id
 }

  resource "aws_lb_target_group" "backend_instances" {
   name     = "backend-instances-target-group"
   port     = 80
   protocol = "HTTP"
   vpc_id   = module.vpc.vpc_id
 }