################################
# Application Gateway
################################
locals {
  application_gateway_name        = "${var.prefix}-${var.env}-appgw"
  frontend_http_port_name         = "${var.prefix}-${var.env}-appgw-fe-http"
  frontend_https_port_name        = "${var.prefix}-${var.env}-appgw-fe-https"
  frontend_ip_configuration_name  = "${var.prefix}-${var.env}-appgw-feip"
  backend_address_pool_name       = "${var.prefix}-${var.env}-appgw-backend"
  backend_http_settings_name      = "${var.prefix}-${var.env}-appgw-target"
  http_listener_name              = "${var.prefix}-${var.env}-appgw-http-listener"
  https_listener_name             = "${var.prefix}-${var.env}-appgw-https-listener"
  http_request_routing_rule_name  = "${var.prefix}-${var.env}-appgw-http-rule"
  https_request_routing_rule_name = "${var.prefix}-${var.env}-appgw-https-rule"
  probe_name                      = "${var.prefix}-${var.env}-appgw-probe"
}

resource "azurerm_public_ip" "this" {
  name                = "${var.prefix}-${var.env}-appgw-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = ["1", "2", "3"]
}

resource "azurerm_dns_a_record" "this" {
  name                = "www"
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.this.id
}

resource "azurerm_application_gateway" "this" {
  name                              = local.application_gateway_name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  enable_http2                      = false
  fips_enabled                      = false
  force_firewall_policy_association = false
  zones                             = ["1", "2", "3", ]

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 0
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.web_subnet_id
  }

  frontend_ip_configuration {
    name                          = local.frontend_ip_configuration_name
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }

  frontend_port {
    name = local.frontend_http_port_name
    port = 80
  }

  frontend_port {
    name = local.frontend_https_port_name
    port = 443
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.backend_http_settings_name
    cookie_based_affinity = "Disabled"
    protocol              = "Http"
    port                  = 3000
    request_timeout       = 20
    probe_name            = local.probe_name

    connection_draining {
      enabled           = true
      drain_timeout_sec = 60
    }
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_http_port_name
    protocol                       = "Http"
    require_sni                    = false
  }

  http_listener {
    name                           = local.https_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_https_port_name
    protocol                       = "Https"
    require_sni                    = false
    ssl_certificate_name           = var.app_selfcert_name
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.appgw_managed_id
    ]
  }

  request_routing_rule {
    name                        = local.http_request_routing_rule_name
    redirect_configuration_name = local.http_request_routing_rule_name
    rule_type                   = "Basic"
    http_listener_name          = local.http_listener_name
    priority                    = 1
  }

  redirect_configuration {
    name                 = local.http_request_routing_rule_name
    target_listener_name = local.https_listener_name
    redirect_type        = "Permanent"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                       = local.https_request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.https_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
    priority                   = 2
  }

  ssl_certificate {
    name                = var.app_selfcert_name
    key_vault_secret_id = var.app_selfcert_versionless_secret_id # https://{keyvault_name}.vault.azure.net/secretes/{certificate_name}/
  }

  probe {
    name                = local.probe_name
    host                = "127.0.0.1"
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }
}

# resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "this" {
#   ip_configuration_name   = "ipconfig1"
#   backend_address_pool_id = tolist(azurerm_application_gateway.this.backend_address_pool).0.id
#   network_interface_id    = var.vm_network_interface_id
# }
