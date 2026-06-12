#--------------------------------------------------------------
# AI Services Module — Main
#
# Creates:
#   - Azure AI Foundry Hub (azurerm_ai_foundry)
#   - Azure AI Foundry Project (azurerm_ai_foundry_project)
#   - Azure AI Search (private endpoint, semantic ranker)
#   - Azure Speech Service (Cognitive Services — SpeechServices)
#   - Document Intelligence (Cognitive Services — FormRecognizer)
#   - Computer Vision / Image Analysis (Cognitive Services — ComputerVision)
#   - Bing Search resource (via azapi — Microsoft.Bing/accounts)
#   - Bing Custom Search resource (via azapi — Microsoft.Bing/accounts)
#
# All Cognitive Services accounts have public network access disabled
# and a private endpoint registered in the centralised hub DNS zone
# (privatelink.cognitiveservices.azure.com).
#
# AI Search has a private endpoint in (privatelink.search.windows.net).
# AI Foundry has private endpoints for API and Notebooks.
#--------------------------------------------------------------

data "azurerm_client_config" "current" {}

locals {
  # Shared diagnostic settings wired to Log Analytics
  diagnostic_setting = {
    workspace_resource_id = var.log_analytics_workspace_id
  }
}

#================================================================
# AZURE AI FOUNDRY
#================================================================

#--------------------------------------------------------------
# AI Foundry Hub Storage Account
# AI Foundry Hub requires a dedicated storage account
#--------------------------------------------------------------
module "ai_foundry_storage" {
  count   = var.enable_ai_foundry ? 1 : 0
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.4"

  name      = var.ai_foundry_storage_name
  parent_id = var.resource_group_id
  location  = var.location
  tags      = var.tags

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  network_rules = {
    bypass         = toset(["AzureServices"])
    default_action = "Deny"
    ip_rules       = []
    virtual_network_subnet_ids = []
  }

  private_endpoints = {
    blob = {
      name                          = "pe-${var.ai_foundry_storage_name}-blob"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "blob"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_blob_id])
    }
    file = {
      name                          = "pe-${var.ai_foundry_storage_name}-file"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_file_id])
    }
  }
}

#--------------------------------------------------------------
# AI Foundry Hub Key Vault
# AI Foundry Hub requires a dedicated Key Vault
#--------------------------------------------------------------
module "ai_foundry_keyvault" {
  count   = var.enable_ai_foundry ? 1 : 0
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  name                = var.ai_foundry_keyvault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags

  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days      = 90
  public_network_access_enabled   = false

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = []
  }

  private_endpoints = {
    vault = {
      name                          = "pe-${var.ai_foundry_keyvault_name}-vault"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "vault"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_keyvault_id])
    }
  }
}

#--------------------------------------------------------------
# Azure AI Foundry Hub
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ai_foundry
# The Hub is the management plane — projects share its storage, KV, and identity.
#--------------------------------------------------------------
resource "azurerm_ai_foundry" "hub" {
  count               = var.enable_ai_foundry ? 1 : 0
  name                = var.ai_foundry_hub_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  storage_account_id = module.ai_foundry_storage[count.index].id
  key_vault_id       = module.ai_foundry_keyvault[count.index].resource_id

  identity {
    type = "SystemAssigned"
  }

  public_network_access = "Disabled"

  # Diagnostic settings → Log Analytics
  # (configured via azurerm_monitor_diagnostic_setting in landing zone)
}

#--------------------------------------------------------------
# Azure AI Foundry Project
# A project scopes the AI workloads and inherits the hub's resources.
#--------------------------------------------------------------
resource "azurerm_ai_foundry_project" "project" {
  count              = var.enable_ai_foundry ? 1 : 0
  name               = var.ai_foundry_project_name
  location           = var.location
  ai_services_hub_id = azurerm_ai_foundry.hub[count.index].id
  tags               = var.tags

  identity {
    type = "SystemAssigned"
  }
}

#--------------------------------------------------------------
# AI Foundry Hub — Private Endpoints
#--------------------------------------------------------------
resource "azurerm_private_endpoint" "ai_foundry_api" {
  count               = var.enable_ai_foundry ? 1 : 0
  name                = "pe-${var.ai_foundry_hub_name}-api"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_pe_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.ai_foundry_hub_name}-api"
    private_connection_resource_id = azurerm_ai_foundry.hub[count.index].id
    is_manual_connection           = false
    subresource_names              = ["Hub"]
  }

  private_dns_zone_group {
    name = "dns-group-ai-foundry-api"
    private_dns_zone_ids = [
      var.private_dns_zone_aml_api_id,
      var.private_dns_zone_aml_notebooks_id,
    ]
  }
}

#================================================================
# AZURE AI SEARCH
#================================================================
module "ai_search" {
  count   = var.enable_ai_search ? 1 : 0
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "~> 0.1"

  name                = var.ai_search_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku                           = var.ai_search_sku
  replica_count                 = var.ai_search_replica_count
  partition_count               = var.ai_search_partition_count
  public_network_access_enabled = false
  local_authentication_enabled  = false  # Force Azure AD / managed identity auth

  semantic_search_sku = var.ai_search_sku == "free" ? null : "standard"

  private_endpoints = {
    searchService = {
      name                          = "pe-${var.ai_search_name}-searchService"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "searchService"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_search_id])
    }
  }

  diagnostic_settings = {
    workspace = local.diagnostic_setting
  }
}

#================================================================
# AZURE SPEECH SERVICE
#================================================================
module "speech_service" {
  count   = var.enable_speech ? 1 : 0
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "~> 0.6"

  name      = var.speech_service_name
  parent_id = var.resource_group_id
  location  = var.location
  tags                = var.tags

  kind     = "SpeechServices"
  sku_name = var.speech_sku

  public_network_access_enabled = false
  local_auth_enabled            = false  # Disable API key auth; require managed identity

  network_acls = {
    default_action = "Deny"
    ip_rules       = []
  }

  private_endpoints = {
    account = {
      name                          = "pe-${var.speech_service_name}-account"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "account"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_cognitive_services_id])
    }
  }

  diagnostic_settings = {
    workspace = local.diagnostic_setting
  }
}

#================================================================
# DOCUMENT INTELLIGENCE
#================================================================
module "document_intelligence" {
  count   = var.enable_document_intelligence ? 1 : 0
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "~> 0.6"

  name      = var.doc_intelligence_name
  parent_id = var.resource_group_id
  location  = var.location
  tags                = var.tags

  kind     = "FormRecognizer"
  sku_name = var.doc_intelligence_sku

  public_network_access_enabled = false
  local_auth_enabled            = false

  network_acls = {
    default_action = "Deny"
    ip_rules       = []
  }

  private_endpoints = {
    account = {
      name                          = "pe-${var.doc_intelligence_name}-account"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "account"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_cognitive_services_id])
    }
  }

  diagnostic_settings = {
    workspace = local.diagnostic_setting
  }
}

#================================================================
# COMPUTER VISION (IMAGE ANALYSIS)
#================================================================
module "computer_vision" {
  count   = var.enable_computer_vision ? 1 : 0
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "~> 0.6"

  name      = var.computer_vision_name
  parent_id = var.resource_group_id
  location  = var.location
  tags                = var.tags

  kind     = "ComputerVision"
  sku_name = var.computer_vision_sku

  public_network_access_enabled = false
  local_auth_enabled            = false

  network_acls = {
    default_action = "Deny"
    ip_rules       = []
  }

  private_endpoints = {
    account = {
      name                          = "pe-${var.computer_vision_name}-account"
      subnet_resource_id            = var.subnet_pe_id
      subresource_name              = "account"
      private_dns_zone_resource_ids = toset([var.private_dns_zone_cognitive_services_id])
    }
  }

  diagnostic_settings = {
    workspace = local.diagnostic_setting
  }
}

#================================================================
# BING SEARCH (Grounding with Bing Search)
# Uses azapi_resource — Microsoft.Bing/accounts is not yet in
# hashicorp/azurerm. The "Grounding" kind enables Bing Search
# grounding for Azure AI Foundry and Azure OpenAI.
#================================================================
resource "azapi_resource" "bing_search" {
  count     = var.enable_bing_search ? 1 : 0
  type      = "Microsoft.Bing/accounts@2020-06-10"
  name      = var.bing_search_name
  parent_id = var.resource_group_id
  location  = "global"
  tags      = var.tags

  body = jsonencode({
    kind = "Bing.Grounding"
    sku = {
      name = var.bing_search_sku
    }
  })

  response_export_values = ["*"]
}

#================================================================
# BING CUSTOM SEARCH (Grounding with Bing Custom Search)
#================================================================
resource "azapi_resource" "bing_custom_search" {
  count     = var.enable_bing_custom_search ? 1 : 0
  type      = "Microsoft.Bing/accounts@2020-06-10"
  name      = var.bing_custom_search_name
  parent_id = var.resource_group_id
  location  = "global"
  tags      = var.tags

  body = jsonencode({
    kind = "Bing.CustomSearch"
    sku = {
      name = var.bing_custom_search_sku
    }
  })

  response_export_values = ["*"]
}

#================================================================
# RBAC — Managed Identity access to AI services
# Grants the App Services system-assigned identity the
# Cognitive Services User role on each AI account.
#================================================================
resource "azurerm_role_assignment" "app_identity_speech" {
  count                = var.app_service_principal_id != "" && var.enable_speech ? 1 : 0
  scope                = module.speech_service[0].resource_id
  role_definition_name = "Cognitive Services User"
  principal_id         = var.app_service_principal_id
}

resource "azurerm_role_assignment" "app_identity_doc_intel" {
  count                = var.app_service_principal_id != "" && var.enable_document_intelligence ? 1 : 0
  scope                = module.document_intelligence[0].resource_id
  role_definition_name = "Cognitive Services User"
  principal_id         = var.app_service_principal_id
}

resource "azurerm_role_assignment" "app_identity_cv" {
  count                = var.app_service_principal_id != "" && var.enable_computer_vision ? 1 : 0
  scope                = module.computer_vision[0].resource_id
  role_definition_name = "Cognitive Services User"
  principal_id         = var.app_service_principal_id
}

resource "azurerm_role_assignment" "app_identity_search_reader" {
  count                = var.app_service_principal_id != "" && var.enable_ai_search ? 1 : 0
  scope                = module.ai_search[0].resource_id
  role_definition_name = "Search Index Data Reader"
  principal_id         = var.app_service_principal_id
}

resource "azurerm_role_assignment" "app_identity_search_contributor" {
  count                = var.app_service_principal_id != "" && var.enable_ai_search ? 1 : 0
  scope                = module.ai_search[0].resource_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = var.app_service_principal_id
}
