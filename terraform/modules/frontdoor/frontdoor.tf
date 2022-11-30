################################
# Front Door
################################
locals {
  front_door_profile_name      = "${var.prefix}-${var.env}-afd"
  front_door_endpoint_name     = "${var.prefix}-${var.env}-afd-endpoint"
  front_door_origin_group_name = "${var.prefix}-${var.env}-afd-backend"
  front_door_origin_name       = "${var.prefix}-${var.env}-afd-origin"
  front_door_route_name        = "${var.prefix}-${var.env}-afd-route"
  sub_domain_name              = "${var.custom_domain_host_name}.${var.dns_zone_name}"
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                     = local.front_door_profile_name
  resource_group_name      = var.resource_group_name
  sku_name                 = "Standard_AzureFrontDoor"
  response_timeout_seconds = 60
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = local.front_door_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = local.front_door_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 0

  health_probe {
    interval_in_seconds = 100
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  name                          = local.front_door_origin_name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  enabled                       = true

  certificate_name_check_enabled = true

  host_name          = var.web_app_default_hostname
  http_port          = 80
  https_port         = 443
  origin_host_header = var.web_app_default_hostname
  priority           = 1
  weight             = 1000
}

resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = local.front_door_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this.id]
  cdn_frontdoor_rule_set_ids    = []
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.this.id]
  link_to_default_domain          = true

  cache {
    compression_enabled           = false
    query_string_caching_behavior = "IgnoreQueryString"
    query_strings                 = []
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  name                     = replace(local.sub_domain_name, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  dns_zone_id              = var.dns_zone_id
  host_name                = local.sub_domain_name

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "this" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.this.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.this.id]
}

resource "azurerm_dns_txt_record" "afd_validation" {
  name                = "_dnsauth.${local.sub_domain_name}"
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.this.validation_token
  }
}

resource "azurerm_dns_cname_record" "afd_cname" {
  name                = var.custom_domain_host_name
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.this.host_name

  depends_on = [azurerm_cdn_frontdoor_route.this]
}
