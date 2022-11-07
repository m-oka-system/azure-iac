variable "prefix" {
  type    = string
  default = "terraform"
}

variable "location" {
  type    = string
  default = "japaneast"
}

variable "allowed_cidr" {
  type = list(any)
}
