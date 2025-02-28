#!/bin/bash
set -e

# Save the current state
terraform state pull > terraform.tfstate.backup

# Try to apply the changes
if terraform apply -auto-approve; then
    echo "Terraform apply succeeded!"
else
    echo "Terraform apply failed, rolling back..."
    # Restore the previous state
    terraform state push terraform.tfstate.backup
    # Destroy any resources that might have been created
    terraform destroy -auto-approve
    echo "Rollback completed."
    exit 1
fi
