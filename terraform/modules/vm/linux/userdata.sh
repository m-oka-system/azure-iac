#!/bin/bash

# Common Variables
PROJECT="tf"
ENV="dev"

# Install tools
sudo apt-get -y update && sudo apt-get install -y \
  curl \
  mysql-client-core-8.0

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install docker
sudo snap install docker

# Add a user to the docker group
sudo addgroup --system docker
sudo adduser cloudadmin docker

# Azure log in using a VM's managed identity
az login --identity

# Docker login and pull image
IMAGE="mokasystem/scaffold"
TAG="latest"
DOCKER_USERNAME=$(az keyvault secret show --vault-name ${PROJECT}-${ENV}-vault --name DOCKER-USERNAME --query value -o tsv)
DOCKER_PASSWORD=$(az keyvault secret show --vault-name ${PROJECT}-${ENV}-vault --name DOCKER-PASSWORD --query value -o tsv)
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
sudo docker pull ${IMAGE}:${TAG}

# Application Environment Variables
DB_HOST=$(az keyvault secret show --vault-name ${PROJECT}-${ENV}-vault --name DB-HOST --query value -o tsv)
DB_USERNAME=$(az keyvault secret show --vault-name ${PROJECT}-${ENV}-vault --name DB-USERNAME --query value -o tsv)
DB_PASSWORD=$(az keyvault secret show --vault-name ${PROJECT}-${ENV}-vault --name DB-PASSWORD --query value -o tsv)
SECRET_KEY_BASE=$(az keyvault secret show --vault-name ${PROJECT}-${ENV}-vault --name SECRET-KEY-BASE --query value -o tsv)

# Create database and migrate
sudo docker run -p 3000:3000 -e RAILS_ENV="production" \
  -e SECRET_KEY_BASE=$SECRET_KEY_BASE \
  -e DB_HOST=$DB_HOST \
  -e DB_USERNAME=$DB_USERNAME \
  -e DB_PASSWORD=$DB_PASSWORD \
  ${IMAGE}:${TAG} rails db:create db:migrate db:seed

# Running application
sudo docker run -p 3000:3000 -e RAILS_ENV="production" \
  -e RAILS_SERVE_STATIC_FILES=1 \
  -e SECRET_KEY_BASE=$SECRET_KEY_BASE \
  -e DB_HOST=$DB_HOST \
  -e DB_USERNAME=$DB_USERNAME \
  -e DB_PASSWORD=$DB_PASSWORD \
  ${IMAGE}:${TAG} rails s -b 0.0.0.0

# # Delete database
# sudo docker run -p 3000:3000 -e RAILS_ENV="production" \
#   -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 \
#   -e SECRET_KEY_BASE=$SECRET_KEY_BASE \
#   -e DB_HOST=$DB_HOST \
#   -e DB_USERNAME=$DB_USERNAME \
#   -e DB_PASSWORD=$DB_PASSWORD \
#   ${IMAGE}:${TAG} rails db:drop
