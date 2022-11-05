# Sign in
az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# Install Bicep
az bicep install

# Add alias
{
  alias tf="terraform"
  alias tfp="terraform plan"
  alias tfv="terraform validate"
  alias tff="terraform fmt -recursive"
  alias tfa="terraform apply --auto-approve"
  alias tfd="terraform destroy --auto-approve"
} >> ~/.bashrc