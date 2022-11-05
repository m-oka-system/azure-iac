#!/usr/bin/env bash
set -euo pipefail

# Required azure cli version >= 2.25.0
az ad sp create-for-rbac --role "Contributor" \
  --name "azure_terraform" \
  --scopes "/subscriptions/${ARM_SUBSCRIPTION_ID}"