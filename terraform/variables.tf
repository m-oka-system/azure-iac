# Local Values
locals {
  create_count = 0
}

# Input Variables
variable "prefix" {
  type    = string
  default = "tf"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "japaneast"
}

variable "allowed_cidr" {
  type = list(any)
}

variable "vm_size" {
  type = string
}

variable "vm_admin_username" {
  type = string
}

variable "vm_admin_password" {
  type = string
}

variable "source_image_name" {
  type = string
}

variable "source_image_resource_group_name" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_admin_username" {
  type = string
}

variable "db_admin_password" {
  type = string
}

variable "db_size" {
  type = string
}

variable "docker_username" {
  type = string
}

variable "docker_password" {
  type = string
}

variable "secret_key_base" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

# Data Sources
data "azurerm_image" "win2022_ja" {
  name                = var.source_image_name
  resource_group_name = var.source_image_resource_group_name
}

