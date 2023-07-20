output "vpc_id" {
    description = "The ID of the VPC"
    value       = module.vpc.vpc_id
}
# CIDR blocks
output "vpc_cidr_block" {
    description = "The CIDR block of the VPC"
    value       = module.vpc.vpc_cidr_block
}

# Subnets
output "private_subnets" {
    description = "List of IDs of private subnets"
    value       = module.vpc.private_subnets
}
output "public_subnets" {
    description = "List of IDs of public subnets"
    value       = module.vpc.public_subnets
}   

output "default_security_group_id_group" {
    description = "Main VPC Default security group id"
    value       = module.vpc.default_security_group_id
}   

output "internet_facing_elb_sec_group_id" {
    description = "Internet Facing ELB's Security Group ID"
    value       = aws_security_group.internet_facing_elb.id
} 

output "internet_facing_elb_dns_name" {
    description = "Internet Facing ELB's DNS Name"
    value       = aws_lb.internet_facing_elb.dns_name
} 


output "internal_elb_sec_group_id" {
    description = "Internal ELB's Security Group ID"
    value       = aws_security_group.int_elb.id
} 

output "aws_lb_target_group-front" {
    description = "LB Target Group - Front"
    value       = aws_lb_target_group.front_instances.arn
} 

output "aws_lb_target_group-backend" {
    description = "LB Target Group - Backend"
    value       = aws_lb_target_group.backend_instances.arn
}

output "aws_launch_template_front" {
  description = "Launch Template - Backend"
  value = aws_launch_template.front_template.id
}

output "aws_launch_template_backend" {
  description = "Launch Template - Backend"
  value = aws_launch_template.backend_template.id
}