#--------------------------------------------------------------
# Data Services Module — Main
#
# Creates:
#   - Storage Account (private endpoints for blob + file)
#   - Azure Cosmos DB — NoSQL API (private endpoint, RBAC data plane,
#     geo-replication optional, analytical store optional)
#   - Key Vault (RBAC mode, purge protection, private endpoint)
#     Shared by all workloads in this landing zone deployment.
#
# Security controls:
#   - Storage: HTTPS-only, TLS 1.2+, public access disabled, CMK optional
#   - Cosmos DB: public access disabled, IP firewall deny-all, RBAC data plane
#   - Key Vault: RBAC auth, purge protection, soft-delete 90 days, no public access
#--------------------------------------------------------------

data "azurerm_client_config" "current" {}

locals {
  diagnostic_setting = {
    workspace_resource_id = var.log_analytics_workspace_id
  }
}

#================================================================
# KEY VAULT
#================================================================
module "key_vault" {
  count   = var.enable_key_vault ? 1 : 0
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags

  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = []
  }

  private_endpoints = {
    vault = {
      name                          = "pe-${var.key_vault_name}-vault"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "vault"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_keyvault_id])
    }
  }

  diagnostic_settings = {
    workspace = local.diagnostic_setting
  }
}

# Grant Terraform identity Key Vault Administrator so it can manage secrets during deployment
resource "azurerm_role_assignment" "terraform_kv_admin" {
  count                = var.enable_key_vault ? 1 : 0
  scope                = module.key_vault[0].resource_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant App Services managed identity Key Vault Secrets User at runtime
resource "azurerm_role_assignment" "app_identity_kv_secrets_user" {
  count                = var.app_service_principal_id != "" && var.enable_key_vault ? 1 : 0
  scope                = module.key_vault[0].resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.app_service_principal_id
}

#================================================================
# STORAGE ACCOUNT
#================================================================
module "storage_account" {
  count     = var.enable_storage_account ? 1 : 0
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.4"

  name      = var.storage_account_name
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"

  https_traffic_only_enabled  = true
  min_tls_version             = "TLS1_2"
  allow_nested_items_to_be_public = false
  cross_tenant_replication_enabled = false
  shared_access_key_enabled   = false  # Disable storage key auth; require Azure AD

  network_rules = {
    bypass         = toset(["AzureServices"])
    default_action = "Deny"
    ip_rules       = []
    virtual_network_subnet_ids = []
  }

  private_endpoints = {
    blob = {
      name                          = "pe-${var.storage_account_name}-blob"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "blob"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_blob_id])
    }
    file = {
      name                          = "pe-${var.storage_account_name}-file"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_file_id])
    }
  }
}

# Grant App Services managed identity Storage Blob Data Contributor
resource "azurerm_role_assignment" "app_identity_storage_blob" {
  count                = var.app_service_principal_id != "" && var.enable_storage_account ? 1 : 0
  scope                = module.storage_account[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.app_service_principal_id
}

#================================================================
# COSMOS DB — NoSQL API
# https://registry.terraform.io/modules/Azure/avm-res-documentdb-databaseaccount/azurerm
#================================================================
module "cosmosdb" {
  count   = var.enable_cosmosdb ? 1 : 0
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "~> 0.4"

  name                = var.cosmosdb_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Consistency policy
  consistency_policy = {
    consistency_level       = var.cosmosdb_consistency_level
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_locations = var.cosmosdb_geo_locations

  # Security: disable public access, disable local auth (key-based)
  public_network_access_enabled         = false
  network_acl_bypass_for_azure_services = true
  ip_range_filter                       = ""

  # RBAC data-plane — disable key-based authentication
  local_authentication_disabled = true

  # Analytical store for Synapse integration (optional)
  analytical_storage_enabled = var.cosmosdb_analytical_storage_enabled

  # Automatic failover when geo_locations has secondary
  automatic_failover_enabled = length(var.cosmosdb_geo_locations) > 1 ? true : false

  private_endpoints = {
    sql = {
      name                          = "pe-${var.cosmosdb_account_name}-sql"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "Sql"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_cosmosdb_id])
    }
  }

  diagnostic_settings = {
    workspace = local.diagnostic_setting
  }
}

# Cosmos DB NoSQL Database
resource "azurerm_cosmosdb_sql_database" "main" {
  count               = var.enable_cosmosdb ? 1 : 0
  name                = var.cosmosdb_database_name
  resource_group_name = var.resource_group_name
  account_name        = module.cosmosdb[0].name
}

# Default container for memory pipeline (vector + document store)
resource "azurerm_cosmosdb_sql_container" "memory" {
  count               = var.enable_cosmosdb ? 1 : 0
  name                = "memory"
  resource_group_name = var.resource_group_name
  account_name        = module.cosmosdb[0].name
  database_name       = azurerm_cosmosdb_sql_database.main[0].name
  partition_key_paths  = ["/sessionId"]
  throughput          = null  # Use autoscale

  autoscale_settings {
    max_throughput = var.cosmosdb_container_max_throughput
  }

  indexing_policy {
    indexing_mode = "consistent"
    included_path { path = "/*" }
    excluded_path { path = "/\"_etag\"/?" }
  }

  # TTL for session-scoped data (-1 = off, 0+ = seconds)
  default_ttl = var.cosmosdb_memory_ttl_seconds
}

# Container for chat history
resource "azurerm_cosmosdb_sql_container" "chat_history" {
  count               = var.enable_cosmosdb ? 1 : 0
  name                = "chat-history"
  resource_group_name = var.resource_group_name
  account_name        = module.cosmosdb[0].name
  database_name       = azurerm_cosmosdb_sql_database.main[0].name
  partition_key_paths  = ["/userId"]
  throughput          = null

  autoscale_settings {
    max_throughput = var.cosmosdb_container_max_throughput
  }

  indexing_policy {
    indexing_mode = "consistent"
    included_path { path = "/*" }
    excluded_path { path = "/\"_etag\"/?" }
  }
}

# Grant App Services managed identity Cosmos DB Built-in Data Contributor
resource "azurerm_cosmosdb_sql_role_assignment" "app_identity_cosmosdb" {
  count               = var.app_service_principal_id != "" && var.enable_cosmosdb ? 1 : 0
  resource_group_name = var.resource_group_name
  account_name        = module.cosmosdb[0].name
  role_definition_id  = "${module.cosmosdb[0].resource_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = var.app_service_principal_id
  scope               = module.cosmosdb[0].resource_id
}
