#--------------------------------------------------------------
# App Gateway Module — Main
#
# Deploys an enterprise-grade entry point for all HTTPS traffic
# to the AI Landing Zone app services.
#
# Security pillar (WAF) controls:
#   - WAF_v2 SKU with dedicated WAF policy
#   - OWASP Core Rule Set 3.2 (prevention mode for prod)
#   - Microsoft Bot Manager Rule Set 1.1
#   - HTTP → HTTPS permanent redirect (no unencrypted traffic)
#   - SSL policy AppGwSslPolicy20220101S (TLS 1.2+, PFS ciphers)
#   - Backend HTTPS with SNI (pick host name from backend address)
#   - Path-based routing: /api/* → WebAPI, /* → WebApp
#   - Full diagnostic logs → Log Analytics (access, perf, firewall)
#
# References:
#   https://learn.microsoft.com/azure/application-gateway/waf-overview
#   https://learn.microsoft.com/azure/well-architected/security/networking
#--------------------------------------------------------------

locals {
  use_kv_cert    = var.ssl_cert_key_vault_secret_id != ""
  use_autoscale  = var.autoscale_min_capacity != null
  cert_name      = "cert-${var.app_gateway_name}"
}

#--------------------------------------------------------------
# WAF Policy — OWASP 3.2 + Bot Manager 1.1
#--------------------------------------------------------------
resource "azurerm_web_application_firewall_policy" "this" {
  name                = var.waf_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.1"
    }
  }
}

#--------------------------------------------------------------
# User-Assigned Managed Identity
# Required when the certificate is sourced from Key Vault.
# Must be granted 'Key Vault Secrets User' on the vault
# (see outputs.tf for the identity_principal_id).
#--------------------------------------------------------------
resource "azurerm_user_assigned_identity" "agw" {
  count               = local.use_kv_cert ? 1 : 0
  name                = "id-${var.app_gateway_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "agw_kv_secrets_user" {
  count                = local.use_kv_cert && var.key_vault_id != "" ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.agw[0].principal_id
}

#--------------------------------------------------------------
# Public IP — Standard, zone-redundant
#--------------------------------------------------------------
resource "azurerm_public_ip" "this" {
  name                = var.public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  allocation_method = "Static"
  sku               = "Standard"
  zones             = var.zones
}

#--------------------------------------------------------------
# Application Gateway — WAF_v2
#--------------------------------------------------------------
resource "azurerm_application_gateway" "this" {
  name                = var.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  zones               = var.zones

  # Associate the WAF policy at the gateway level
  firewall_policy_id = azurerm_web_application_firewall_policy.this.id

  # Managed identity — only needed for Key Vault cert integration
  dynamic "identity" {
    for_each = local.use_kv_cert ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.agw[0].id]
    }
  }

  #----------------------------------------------------------
  # SKU
  #----------------------------------------------------------
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    # Omit capacity when autoscaling; provider treats null as "not set"
    capacity = local.use_autoscale ? null : var.capacity
  }

  dynamic "autoscale_configuration" {
    for_each = local.use_autoscale ? [1] : []
    content {
      min_capacity = var.autoscale_min_capacity
      max_capacity = var.autoscale_max_capacity
    }
  }

  #----------------------------------------------------------
  # SSL Policy — TLS 1.2+, PFS-only cipher suites
  #----------------------------------------------------------
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  #----------------------------------------------------------
  # Networking
  #----------------------------------------------------------
  gateway_ip_configuration {
    name      = "gic-${var.app_gateway_name}"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "fic-public"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "fp-http"
    port = 80
  }

  frontend_port {
    name = "fp-https"
    port = 443
  }

  #----------------------------------------------------------
  # SSL Certificate
  # Branch on PFX (self-signed / uploaded) vs Key Vault.
  #----------------------------------------------------------
  dynamic "ssl_certificate" {
    for_each = local.use_kv_cert ? [] : [1]
    content {
      name     = local.cert_name
      data     = var.ssl_cert_pfx_b64
      password = var.ssl_cert_pfx_password
    }
  }

  dynamic "ssl_certificate" {
    for_each = local.use_kv_cert ? [1] : []
    content {
      name                = local.cert_name
      key_vault_secret_id = var.ssl_cert_key_vault_secret_id
    }
  }

  #----------------------------------------------------------
  # Listeners
  #----------------------------------------------------------

  # HTTP listener — receives port-80 traffic to redirect
  http_listener {
    name                           = "listener-http"
    frontend_ip_configuration_name = "fic-public"
    frontend_port_name             = "fp-http"
    protocol                       = "Http"
  }

  # HTTPS listener — main entry point; WAF policy enforced here
  http_listener {
    name                           = "listener-https"
    frontend_ip_configuration_name = "fic-public"
    frontend_port_name             = "fp-https"
    protocol                       = "Https"
    ssl_certificate_name           = local.cert_name
    firewall_policy_id             = azurerm_web_application_firewall_policy.this.id
  }

  # HTTP → HTTPS permanent redirect (Security: no clear-text traffic)
  redirect_configuration {
    name                 = "rc-http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "listener-https"
    include_path         = true
    include_query_string = true
  }

  #----------------------------------------------------------
  # Backend address pools
  #----------------------------------------------------------
  backend_address_pool {
    name  = "bap-webapp"
    fqdns = [var.webapp_fqdn]
  }

  backend_address_pool {
    name  = "bap-webapi"
    fqdns = [var.webapi_fqdn]
  }

  #----------------------------------------------------------
  # Health probes (HTTPS, separate host header per backend)
  #----------------------------------------------------------
  probe {
    name                                      = "probe-webapp"
    protocol                                  = "Https"
    host                                      = var.webapp_fqdn
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
    match {
      status_code = ["200-399"]
    }
  }

  probe {
    name                                      = "probe-webapi"
    protocol                                  = "Https"
    host                                      = var.webapi_fqdn
    path                                      = var.webapi_health_path
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
    match {
      # Accept 404 in case /health endpoint is not yet implemented
      status_code = ["200-404"]
    }
  }

  #----------------------------------------------------------
  # Backend HTTP settings
  # Backend HTTPS with SNI so App Service validates the cert
  # against its own hostname (end-to-end TLS — not SSL offload).
  #----------------------------------------------------------
  backend_http_settings {
    name                                = "bhs-webapp"
    protocol                            = "Https"
    port                                = 443
    cookie_based_affinity               = "Disabled"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "probe-webapp"
  }

  backend_http_settings {
    name                                = "bhs-webapi"
    protocol                            = "Https"
    port                                = 443
    cookie_based_affinity               = "Disabled"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "probe-webapi"
  }

  #----------------------------------------------------------
  # Path-based routing map
  # Default (/*) → WebApp; /api/* → WebAPI
  #----------------------------------------------------------
  url_path_map {
    name                               = "upm-path-routing"
    default_backend_address_pool_name  = "bap-webapp"
    default_backend_http_settings_name = "bhs-webapp"

    path_rule {
      name                       = "pr-api"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "bap-webapi"
      backend_http_settings_name = "bhs-webapi"
    }
  }

  #----------------------------------------------------------
  # Routing rules
  #----------------------------------------------------------

  # Rule 1: HTTP redirect (priority 100, Basic)
  request_routing_rule {
    name                        = "rrr-http-redirect"
    rule_type                   = "Basic"
    priority                    = 100
    http_listener_name          = "listener-http"
    redirect_configuration_name = "rc-http-to-https"
  }

  # Rule 2: HTTPS path-based routing (priority 200, PathBasedRouting)
  request_routing_rule {
    name              = "rrr-https-path"
    rule_type         = "PathBasedRouting"
    priority          = 200
    http_listener_name = "listener-https"
    url_path_map_name  = "upm-path-routing"
  }
}

#--------------------------------------------------------------
# Diagnostic Settings → Log Analytics
# Captures access logs, performance logs, and WAF firewall logs.
#--------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  name                       = "diag-${var.app_gateway_name}"
  target_resource_id         = azurerm_application_gateway.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
