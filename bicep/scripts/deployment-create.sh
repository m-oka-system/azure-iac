#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP_NAME=$1
BICEP_FILE_NAME=$2

az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file $BICEP_FILE_NAME