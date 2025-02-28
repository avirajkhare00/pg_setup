provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "pg_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# Create a subnet
resource "aws_subnet" "pg_subnet" {
  vpc_id                  = aws_vpc.pg_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "${var.prefix}-subnet"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "pg_igw" {
  vpc_id = aws_vpc.pg_vpc.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

# Create a route table
resource "aws_route_table" "pg_route_table" {
  vpc_id = aws_vpc.pg_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pg_igw.id
  }

  tags = {
    Name = "${var.prefix}-route-table"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "pg_route_table_assoc" {
  subnet_id      = aws_subnet.pg_subnet.id
  route_table_id = aws_route_table.pg_route_table.id
}

# Create a security group
resource "aws_security_group" "pg_sg" {
  name        = "${var.prefix}-sg"
  description = "Security group for PostgreSQL server"
  vpc_id      = aws_vpc.pg_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  # PostgreSQL access
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.pg_allowed_cidr
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-sg"
  }
}

# Create an EBS volume for PostgreSQL data
resource "aws_ebs_volume" "pg_data" {
  availability_zone = var.availability_zone
  size              = var.pg_data_volume_size
  type              = "gp3"

  tags = {
    Name = "${var.prefix}-pg-data"
  }
}

# Create an S3 bucket for PostgreSQL backups
resource "aws_s3_bucket" "pg_backups" {
  bucket = "${var.prefix}-pg-backups-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.prefix}-pg-backups"
  }
}

# Generate random suffix for S3 bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Configure S3 bucket lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "pg_backups_lifecycle" {
  bucket = aws_s3_bucket.pg_backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    expiration {
      days = var.backup_retention_days
    }
  }
}

# Create IAM role for EC2 instance to access S3
resource "aws_iam_role" "pg_server_role" {
  name = "${var.prefix}-pg-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.prefix}-pg-server-role"
  }
}

# Create IAM policy for S3 access
resource "aws_iam_policy" "pg_s3_access" {
  name        = "${var.prefix}-pg-s3-access"
  description = "Allow PostgreSQL server to access S3 bucket for backups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.pg_backups.arn,
          "${aws_s3_bucket.pg_backups.arn}/*"
        ]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "pg_s3_access_attachment" {
  role       = aws_iam_role.pg_server_role.name
  policy_arn = aws_iam_policy.pg_s3_access.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "pg_server_profile" {
  name = "${var.prefix}-pg-server-profile"
  role = aws_iam_role.pg_server_role.name
}

# Create an EC2 instance (Debian)
resource "aws_instance" "pg_server" {
  ami                    = var.debian_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.pg_subnet.id
  vpc_security_group_ids = [aws_security_group.pg_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.pg_server_profile.name

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.prefix}-pg-server"
  }

  # Generate Ansible inventory
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/../ansible/inventory
      echo "[postgresql]" > ${path.module}/../ansible/inventory/hosts
      echo "${aws_instance.pg_server.public_ip} ansible_user=admin ansible_ssh_private_key_file=${var.ssh_private_key_path}" >> ${path.module}/../ansible/inventory/hosts
    EOT
  }
}

# Attach the EBS volume to the EC2 instance
resource "aws_volume_attachment" "pg_data_attachment" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.pg_data.id
  instance_id  = aws_instance.pg_server.id
  force_detach = true
}

# Output the public IP of the PostgreSQL server
output "pg_server_public_ip" {
  value = aws_instance.pg_server.public_ip
}

# Output the device name of the attached EBS volume
output "pg_data_device" {
  value = aws_volume_attachment.pg_data_attachment.device_name
}

# Output the S3 bucket name
output "pg_backup_bucket" {
  value = aws_s3_bucket.pg_backups.bucket
}
