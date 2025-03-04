# AWS region
region = "ap-south-1"

# Resource prefix
prefix = "pg-setup"

# Network configuration
vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"
availability_zone = "ap-south-1a"

# Instance configuration
debian_ami_id        = "ami-03c68e52484d7488f"
instance_type        = "t3.medium"
key_name             = "pg_setup"
ssh_private_key_path = "~/.ssh/pg_setup.pem"

# Volume configuration
root_volume_size    = 8
pg_data_volume_size = 20

# Security configuration
ssh_allowed_cidr = ["0.0.0.0/0"]
pg_allowed_cidr  = ["0.0.0.0/0"]

# Backup configuration
backup_retention_days = 30
