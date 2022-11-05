#!/usr/bin/env bash
set -euo pipefail

PREFIX="terraform"
REGION="japaneast"

az group create --name "${PREFIX}-rg" --location $REGION