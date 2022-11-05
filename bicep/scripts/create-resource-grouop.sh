#!/usr/bin/env bash
set -euo pipefail

PREFIX="bicep"
REGION="japaneast"

az group create --name "${PREFIX}-rg" --location $REGION