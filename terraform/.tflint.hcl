plugin "azurerm" {
    enabled = true
    version = "0.19.0"
    source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

config {
  module = true
}

rule "terraform_required_providers" {
  enabled = false
}
