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

locals {
  diagnostic_setting = {
    workspace_resource_id = var.log_analytics_workspace_id
  }
}

#================================================================
# AZURE SIGNALR SERVICE
# https://registry.terraform.io/modules/Azure/avm-res-signalrservice-signalr/azurerm
#================================================================
module "signalr" {
  count   = var.enable_signalr ? 1 : 0
  source  = "Azure/avm-res-signalrservice-signalr/azurerm"
  version = "~> 0.1"

  name                = var.signalr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku = {
    name     = var.signalr_sku
    capacity = var.signalr_capacity
  }

  # Serverless mode — recommended for App Services / Functions integration
  service_mode = "Serverless"

  public_network_access_enabled = false

  # Allow clients to connect via HTTP/1.1 and HTTP/2
  connectivity_logs_enabled = true
  messaging_logs_enabled    = true
  live_trace_enabled        = true

  cors = {
    allowed_origins = var.signalr_cors_origins
  }

  identity = {
    type = "SystemAssigned"
  }

  private_endpoints = {
    signalr = {
      name                          = "pe-${var.signalr_name}-signalr"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "signalr"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_signalr_id])
    }
  }

  diagnostic_settings = {
    workspace = local.diagnostic_setting
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
  value        = module.signalr[0].primary_connection_string
  key_vault_id = var.key_vault_id
  content_type = "SignalR connection string"

  tags = var.tags
}
