# create RDS instance with Multi-AZ deployment

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "main"
  subnet_ids = [module.vpc.private_subnets[2], module.vpc.private_subnets[3], module.vpc.private_subnets[4]]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_kms_key" "db_pass" {
  description = "Example KMS Key"
}

resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier          = "rds-cluster"
  availability_zones          = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
  engine                      = "postgres"
  engine_version              = "14.7"
  database_name               = "test"
  db_cluster_instance_class   = "m5d.large"
  storage_type                = "io1"
  allocated_storage           = 400
  iops                        = 3000
  master_username             = "admin"
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.db_pass.key_id
}