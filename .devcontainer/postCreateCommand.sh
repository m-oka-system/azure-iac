#!/usr/bin/env bash
# Azure sign in
az login --service-principal --username "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"

# Add safe directory
# git config --global --add safe.directory "$(pwd)"

# Add alias for Terraform
cat <<EOL >>~/.bashrc
alias tf="terraform"
alias tfp="terraform plan"
alias tfv="terraform validate"
alias tff="terraform fmt -recursive"
alias tfa="terraform apply --auto-approve"
alias tfd="terraform destroy --auto-approve"
EOL
