#!/usr/bin/env bash
set -euo pipefail

# # Required azure cli version >= 2.25.0
# az ad sp create-for-rbac --role "Contributor" \
#   --name "azure_terraform" \
#   --scopes "/subscriptions/${ARM_SUBSCRIPTION_ID}"

# Create service principal
appId=$(az ad sp create-for-rbac --name "azure_terraform" --query "appId" --output tsv)

# Assign roles
az role assignment create --assignee "$appId" \
  --role "Contributor" \
  --subscription "${ARM_SUBSCRIPTION_ID}"

az role assignment create --assignee "$appId" \
  --role "User Access Administrator" \
  --subscription "${ARM_SUBSCRIPTION_ID}"

az role assignment create --assignee "$appId" \
  --role "Key Vault Administrator" \
  --subscription "${ARM_SUBSCRIPTION_ID}"
