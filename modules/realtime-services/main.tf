#--------------------------------------------------------------
# Realtime Services Module — Main
#
# Creates:
#   - Azure SignalR Service (Standard SKU, serverless mode)
#     with private endpoint for secure VNet-only access
#
# Security controls:
#   - Public network access disabled; all traffic via private endpoint
#   - Serverless mode for Azure Functions / App Services integration
#   - System-assigned managed identity for upstream auth
#   - Connection string stored in Key Vault (not app settings directly)
#--------------------------------------------------------------

#================================================================
# AZURE SIGNALR SERVICE
# Note: No AVM module exists for SignalR — using native azurerm resources.
#================================================================
resource "azurerm_signalr_service" "this" {
  count               = var.enable_signalr ? 1 : 0
  name                = var.signalr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku {
    name     = var.signalr_sku
    capacity = var.signalr_capacity
  }

  # Serverless mode — recommended for App Services / Functions integration
  service_mode = "Serverless"

  public_network_access_enabled = false

  connectivity_logs_enabled = true
  messaging_logs_enabled    = true

  live_trace {
    enabled                   = true
    connectivity_logs_enabled = true
    messaging_logs_enabled    = true
    http_request_logs_enabled = true
  }

  cors {
    allowed_origins = var.signalr_cors_origins
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "signalr" {
  count               = var.enable_signalr ? 1 : 0
  name                = "pe-${var.signalr_name}-signalr"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_pe_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.signalr_name}-signalr"
    private_connection_resource_id = azurerm_signalr_service.this[0].id
    subresource_names              = ["signalr"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnszg-${var.signalr_name}-signalr"
    private_dns_zone_ids = [var.private_dns_zone_signalr_id]
  }
}

resource "azurerm_monitor_diagnostic_setting" "signalr" {
  count                      = var.enable_signalr ? 1 : 0
  name                       = "diag-${var.signalr_name}"
  target_resource_id         = azurerm_signalr_service.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

#--------------------------------------------------------------
# Store SignalR connection string in Key Vault
# App Services reference it via Key Vault reference:
#   @Microsoft.KeyVault(SecretUri=<kv_uri>secrets/signalr-connection-string/)
#--------------------------------------------------------------
resource "azurerm_key_vault_secret" "signalr_connection_string" {
  count        = var.enable_signalr && var.key_vault_id != "" ? 1 : 0
  name         = "signalr-connection-string"
  value        = azurerm_signalr_service.this[0].primary_connection_string
  key_vault_id = var.key_vault_id
  content_type = "SignalR connection string"

  tags = var.tags
}
