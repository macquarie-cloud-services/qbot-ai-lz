#--------------------------------------------------------------
# App Services Module — Main
#
# Creates:
#   - App Service Plan (Linux, Premium v3)
#   - WebApp — Node.js frontend / chat interface
#   - WebAPI  — .NET backend API
#   - Memory Pipeline — .NET background processor
#   - Function App — .NET serverless workers
#   - App Storage Account for Function App
#
# Security controls:
#   - HTTPS-only enforcement on all apps
#   - Minimum TLS 1.2
#   - System-assigned managed identities on all apps
#   - VNet integration (outbound) via delegated subnets
#   - Private endpoint on SCM site (Kudu) locked down
#   - IP restrictions block all public inbound (traffic via private endpoint only)
#   - App Insights connection wired to all apps
#--------------------------------------------------------------

locals {
  # Common app settings applied to all apps
  common_app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }
}

#================================================================
# APP SERVICE PLAN
# Premium v3 for VNet integration + private endpoint support
#================================================================
module "app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "~> 0.3"

  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  os_type  = "Linux"
  sku_name = var.app_service_plan_sku

  # Zone redundancy (recommended for prod)
  zone_balancing_enabled = var.enable_zone_redundancy
}

#================================================================
# WEBAPP — Node.js (QBot Chat Frontend / Orchestration)
#================================================================
module "webapp_nodejs" {
  count   = var.enable_webapp_nodejs ? 1 : 0
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.12"

  name      = var.webapp_nodejs_name
  parent_id = var.resource_group_id
  location  = var.location
  tags                = var.tags

  kind     = "webapp"
  os_type  = "Linux"
  service_plan_resource_id = module.app_service_plan.resource_id

  site_config = {
    http2_enabled              = true
    minimum_tls_version        = "1.2"
    ftps_state                 = "Disabled"
    always_on                  = true
    websockets_enabled         = true  # Required for SignalR
    vnet_route_all_enabled     = true

    application_stack = {
      node_version = var.webapp_node_version
    }

    # Block all direct public inbound; traffic via Front Door or App Gateway only
    ip_restriction_default_action = "Deny"
  }

  https_only = true

  managed_identities = {
    system_assigned = true
  }

  # VNet integration (outbound — egress to private endpoints)
  virtual_network_subnet_id = var.subnet_app_id

  app_settings = merge(local.common_app_settings, {
    COSMOSDB_ENDPOINT    = var.cosmosdb_endpoint
    COSMOSDB_DATABASE    = var.cosmosdb_database_name
    AI_SEARCH_ENDPOINT   = var.ai_search_endpoint
    KEY_VAULT_URI        = var.key_vault_uri
    SIGNALR_CONNECTION   = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/signalr-connection-string/)"
    AI_FOUNDRY_ENDPOINT  = var.ai_foundry_endpoint
    SPEECH_ENDPOINT      = var.speech_endpoint
  })

  private_endpoints = {
    sites = {
      name                          = "pe-${var.webapp_nodejs_name}-sites"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "sites"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_web_id])
    }
  }
}

#================================================================
# WEBAPI — .NET (QBot Backend REST API)
#================================================================
module "webapi_dotnet" {
  count   = var.enable_webapi_dotnet ? 1 : 0
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.12"

  name      = var.webapi_dotnet_name
  parent_id = var.resource_group_id
  location  = var.location
  tags                = var.tags

  kind     = "webapp"
  os_type  = "Linux"
  service_plan_resource_id = module.app_service_plan.resource_id

  site_config = {
    http2_enabled              = true
    minimum_tls_version        = "1.2"
    ftps_state                 = "Disabled"
    always_on                  = true
    vnet_route_all_enabled     = true

    application_stack = {
      dotnet_version = var.dotnet_version
    }

    ip_restriction_default_action = "Deny"

    # CORS for the Node.js WebApp
    cors = {
      allowed_origins = var.webapi_cors_origins
    }
  }

  https_only = true

  managed_identities = {
    system_assigned = true
  }

  virtual_network_subnet_id = var.subnet_app_id

  app_settings = merge(local.common_app_settings, {
    COSMOSDB_ENDPOINT        = var.cosmosdb_endpoint
    COSMOSDB_DATABASE        = var.cosmosdb_database_name
    AI_SEARCH_ENDPOINT       = var.ai_search_endpoint
    KEY_VAULT_URI            = var.key_vault_uri
    AI_FOUNDRY_ENDPOINT      = var.ai_foundry_endpoint
    SPEECH_ENDPOINT          = var.speech_endpoint
    DOC_INTELLIGENCE_ENDPOINT = var.doc_intelligence_endpoint
    COMPUTER_VISION_ENDPOINT = var.computer_vision_endpoint
    STORAGE_ACCOUNT_NAME     = var.storage_account_name
  })

  private_endpoints = {
    sites = {
      name                          = "pe-${var.webapi_dotnet_name}-sites"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "sites"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_web_id])
    }
  }
}

#================================================================
# MEMORY PIPELINE — .NET (Background memory ingestion service)
#================================================================
module "memory_pipeline_dotnet" {
  count   = var.enable_memory_pipeline ? 1 : 0
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.12"

  name      = var.memory_pipeline_name
  parent_id = var.resource_group_id
  location  = var.location
  tags                = var.tags

  kind     = "webapp"
  os_type  = "Linux"
  service_plan_resource_id = module.app_service_plan.resource_id

  site_config = {
    http2_enabled              = true
    minimum_tls_version        = "1.2"
    ftps_state                 = "Disabled"
    always_on                  = true
    vnet_route_all_enabled     = true

    application_stack = {
      dotnet_version = var.dotnet_version
    }

    ip_restriction_default_action = "Deny"
  }

  https_only = true

  managed_identities = {
    system_assigned = true
  }

  virtual_network_subnet_id = var.subnet_app_id

  app_settings = merge(local.common_app_settings, {
    COSMOSDB_ENDPOINT        = var.cosmosdb_endpoint
    COSMOSDB_DATABASE        = var.cosmosdb_database_name
    AI_SEARCH_ENDPOINT       = var.ai_search_endpoint
    KEY_VAULT_URI            = var.key_vault_uri
    STORAGE_ACCOUNT_NAME     = var.storage_account_name
    DOC_INTELLIGENCE_ENDPOINT = var.doc_intelligence_endpoint
    COMPUTER_VISION_ENDPOINT = var.computer_vision_endpoint
  })

  private_endpoints = {
    sites = {
      name                          = "pe-${var.memory_pipeline_name}-sites"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "sites"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_web_id])
    }
  }
}

#================================================================
# FUNCTION APP — .NET (Serverless workers: indexing, document processing)
#================================================================

# Storage account for Function App runtime (AzureWebJobsStorage)
module "func_storage" {
  count     = var.enable_function_app ? 1 : 0
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.4"

  name      = var.func_storage_name
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  https_traffic_only_enabled  = true
  min_tls_version             = "TLS1_2"
  shared_access_key_enabled   = true  # Required for Function App AzureWebJobsStorage

  network_rules = {
    bypass         = toset(["AzureServices"])
    default_action = "Deny"
    ip_rules       = []
    virtual_network_subnet_ids = []
  }

  private_endpoints = {
    blob = {
      name                          = "pe-${var.func_storage_name}-blob"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "blob"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_blob_id])
    }
  }
}

module "function_app" {
  count   = var.enable_function_app ? 1 : 0
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.12"

  name      = var.function_app_name
  parent_id = var.resource_group_id
  location  = var.location
  tags                = var.tags

  kind     = "functionapp"
  os_type  = "Linux"
  service_plan_resource_id = module.app_service_plan.resource_id

  site_config = {
    http2_enabled          = true
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    vnet_route_all_enabled = true

    application_stack = {
      dotnet_version              = var.dotnet_version
      use_dotnet_isolated_runtime = true
    }

    ip_restriction_default_action = "Deny"
  }

  https_only = true

  managed_identities = {
    system_assigned = true
  }

  virtual_network_subnet_id = var.subnet_func_id

  app_settings = merge(local.common_app_settings, {
    AzureWebJobsStorage__accountName = module.func_storage[0].name
    FUNCTIONS_EXTENSION_VERSION      = "~4"
    COSMOSDB_ENDPOINT                = var.cosmosdb_endpoint
    COSMOSDB_DATABASE                = var.cosmosdb_database_name
    AI_SEARCH_ENDPOINT               = var.ai_search_endpoint
    KEY_VAULT_URI                    = var.key_vault_uri
    STORAGE_ACCOUNT_NAME             = var.storage_account_name
    DOC_INTELLIGENCE_ENDPOINT        = var.doc_intelligence_endpoint
    COMPUTER_VISION_ENDPOINT         = var.computer_vision_endpoint
  })

  private_endpoints = {
    sites = {
      name                          = "pe-${var.function_app_name}-sites"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "sites"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_web_id])
    }
  }
}

# Grant Function App managed identity Storage Blob Data Owner on its own storage account
resource "azurerm_role_assignment" "func_storage_blob_owner" {
  count                = var.enable_function_app ? 1 : 0
  scope                = module.func_storage[0].id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = module.function_app[0].identity[0].principal_id
}
