# PostgreSQL Infrastructure Setup

This document outlines the production setup for PostgreSQL using Terraform and Ansible, deployed via GitHub Actions.

## Architecture

The setup consists of:
- A Debian VM hosted on AWS EC2
- An external EBS volume for PostgreSQL data
- PostgreSQL 15 installation with optimized configuration
- Automated maintenance scripts running as cron jobs
- S3 bucket for storing PostgreSQL backups

## Components

### Infrastructure (Terraform)
- VPC with public subnet
- Security group allowing SSH and PostgreSQL access
- EC2 instance (Debian) with IAM role for S3 access
- EBS volume for PostgreSQL data
- S3 bucket for PostgreSQL backups with lifecycle policy

### Configuration (Ansible)
- PostgreSQL installation and configuration
- External storage formatting and mounting
- PostgreSQL data directory setup
- Security configuration

### Maintenance Scripts
- Daily backups with 7-day local retention and 30-day S3 retention
- Weekly VACUUM ANALYZE
- Regular monitoring (every 5 minutes)

## Deployment Process

1. GitHub Actions workflow is triggered by:
   - Push to main branch
   - Manual workflow dispatch
   - Pull request (plan only)

2. Terraform creates the infrastructure:
   - EC2 instance
   - EBS volume
   - Network components

3. Ansible configures PostgreSQL:
   - Installs PostgreSQL 15
   - Formats and mounts external storage
   - Configures PostgreSQL for optimal performance
   - Sets up maintenance scripts

## Security Considerations

- SSH access is restricted to specified IP addresses
- PostgreSQL access is restricted to specified IP addresses
- All PostgreSQL connections require password authentication
- Backups are secured with appropriate permissions

## Maintenance

The following maintenance tasks are automated:
- Daily backups at 1:00 AM (stored locally and in S3)
- Weekly VACUUM ANALYZE on Sundays at 2:30 AM
- Monitoring every 5 minutes

## S3 Backup Process

The PostgreSQL backup process includes:
1. Creating a full database dump using `pg_dumpall`
2. Compressing the dump with gzip
3. Uploading the compressed dump to S3
4. Removing the local copy after successful S3 upload
5. Cleaning up old backups in S3 based on retention policy

## Required Secrets for GitHub Actions

- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `SSH_KEY_NAME`: Name of the SSH key in AWS
- `SSH_PRIVATE_KEY`: Private SSH key for connecting to the instance