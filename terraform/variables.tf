variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "pg-setup"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for resources"
  type        = string
  default     = "us-west-2a"
}

variable "debian_ami_id" {
  description = "AMI ID for Debian"
  type        = string
  # Debian 11 (Bullseye) in us-west-2
  default = "ami-0b7d6d6d3da7bb791"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 8
}

variable "pg_data_volume_size" {
  description = "Size of PostgreSQL data volume in GB"
  type        = number
  default     = 20
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "pg_allowed_cidr" {
  description = "CIDR blocks allowed to connect to PostgreSQL"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "backup_retention_days" {
  description = "Number of days to retain backups in S3"
  type        = number
  default     = 30
}
