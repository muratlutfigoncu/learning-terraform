terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 5.0.0"
        }
    }

    required_version = ">= 1.2.0"
}

provider "aws" {
    region = "eu-central-1"
    profile = "default"

    default_tags {
        tags = {
            Environment     = "Test"
            Name            = "Terraform-3-Tier-App"
        }
    }
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "terraform-vpc"
    cidr = "10.0.0.0/16"

    azs = ["eu-central-1a", "eu-central-1b"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
    public_subnets = ["10.0.5.0/24", "10.0.6.0/24"]

    enable_nat_gateway = false
    enable_vpn_gateway = false
}


