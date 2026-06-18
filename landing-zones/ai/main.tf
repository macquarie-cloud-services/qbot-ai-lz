#--------------------------------------------------------------
# AI Landing Zone — Main
#
# This configuration deploys a single environment+region AI spoke.
# Run with one of the four provided .tfvars files:
#   dev-aue.tfvars  | dev-ause.tfvars
#   prod-aue.tfvars | prod-ause.tfvars
#
# Architecture:
#   1. Remote state — reads hub VNet ID + DNS zone IDs from platform/connectivity
#   2. Remote state — reads Log Analytics + App Insights from platform/management
#   3. Landing zone resource group
#   4. ai-networking module — spoke VNet, NSGs, hub peering, DNS zone links
#   5. data-services module — Key Vault, Storage Account, Cosmos DB
#   6. ai-services module — AI Foundry, AI Search, Speech, Doc Intel,
#                           Computer Vision, Bing Search, Bing Custom Search
#   7. app-services module — App Service Plan, WebApp, WebAPI,
#                            Memory Pipeline, Function App
#   8. realtime-services module — SignalR Service
#--------------------------------------------------------------

data "azurerm_client_config" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Region      = var.location
    ManagedBy   = "Terraform-AVM"
    Layer       = "landing-zone-ai"
  })
}

#--------------------------------------------------------------
# Hub Connectivity Remote State
# Reads hub VNet ID and Private DNS Zone IDs from platform/connectivity.
#--------------------------------------------------------------
data "terraform_remote_state" "connectivity" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.hub_tfstate_resource_group_name
    storage_account_name = var.hub_tfstate_storage_account_name
    container_name       = var.hub_tfstate_container_name
    key                  = var.hub_tfstate_key
    use_azuread_auth     = true
  }
}

#--------------------------------------------------------------
# Management Remote State
# Reads Log Analytics workspace ID and App Insights connection string.
#--------------------------------------------------------------
data "terraform_remote_state" "management" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.mgmt_tfstate_resource_group_name
    storage_account_name = var.mgmt_tfstate_storage_account_name
    container_name       = var.mgmt_tfstate_container_name
    key                  = var.mgmt_tfstate_key
    use_azuread_auth     = true
  }
}

locals {
  # Hub connectivity outputs
  hub_vnet_id             = data.terraform_remote_state.connectivity.outputs.hub_vnet_id
  hub_vnet_name           = data.terraform_remote_state.connectivity.outputs.hub_vnet_name
  hub_resource_group_name = data.terraform_remote_state.connectivity.outputs.hub_resource_group_name
  dns_zone_ids            = data.terraform_remote_state.connectivity.outputs.private_dns_zone_ids

  # Management outputs
  log_analytics_workspace_id     = data.terraform_remote_state.management.outputs.log_analytics_workspace_id
  app_insights_connection_string = data.terraform_remote_state.management.outputs.app_insights_connection_string

  # Build DNS zone name map for spoke VNet link creation in ai-networking module
  dns_zone_name_map = {
    for key, zone_id in local.dns_zone_ids : key => {
      name        = regex("/privateDnsZones/([^/]+)$", zone_id)[0]
      resource_id = zone_id
    }
  }
}

#--------------------------------------------------------------
# Landing Zone Resource Group
#--------------------------------------------------------------
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"

  enable_telemetry = false   # disables modtm_telemetry

  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

#--------------------------------------------------------------
# AI Spoke Networking
# Creates NSGs, spoke VNet (6 subnets), hub peering, DNS zone links.
#--------------------------------------------------------------
module "ai_networking" {
  source = "../../modules/ai-networking"

  providers = {
    azurerm     = azurerm     # spoke resources (NSGs, spoke VNet, spoke→hub peering)
    azurerm.hub = azurerm.hub # hub resources (hub→spoke peering, DNS zone links)
  }

  resource_group_name = module.resource_group.name
  resource_group_id   = module.resource_group.resource_id
  location            = var.location
  location_code       = var.location_code
  environment         = var.environment

  vnet_name          = var.vnet_name
  vnet_address_space = var.vnet_address_space

  subnets                 = var.subnets
  network_security_groups = var.network_security_groups

  hub_vnet_id             = local.hub_vnet_id
  hub_vnet_name           = local.hub_vnet_name
  hub_resource_group_name = local.hub_resource_group_name
  use_remote_gateways     = var.use_remote_gateways
  enable_hub_peering      = var.feature_flags.enable_hub_peering

  private_dns_zone_ids = local.dns_zone_name_map

  tags = local.common_tags
}

#--------------------------------------------------------------
# Data Services
# Key Vault, Storage Account, Cosmos DB (NoSQL)
#--------------------------------------------------------------
module "data_services" {
  source = "../../modules/data-services"

  resource_group_name = module.resource_group.name
  resource_group_id   = module.resource_group.resource_id
  location            = var.location

  subnet_pe_id               = module.ai_networking.subnet_pe_id
  log_analytics_workspace_id = local.log_analytics_workspace_id

  # RBAC — assigned after app-services creates managed identity
  # Pass principal IDs after first apply once they are known
  app_service_principal_id = var.app_service_principal_id

  # Private DNS Zone IDs from hub
  private_dns_zone_keyvault_id = local.dns_zone_ids["keyvault"]
  private_dns_zone_blob_id     = local.dns_zone_ids["blob"]
  private_dns_zone_file_id     = local.dns_zone_ids["file"]
  private_dns_zone_cosmosdb_id = local.dns_zone_ids["cosmosdb"]

  # Key Vault
  key_vault_name = var.key_vault_name

  # Storage Account
  storage_account_name     = var.storage_account_name
  storage_replication_type = var.storage_replication_type

  # Cosmos DB
  cosmosdb_account_name               = var.cosmosdb_account_name
  cosmosdb_database_name              = var.cosmosdb_database_name
  cosmosdb_consistency_level          = var.cosmosdb_consistency_level
  cosmosdb_geo_locations              = var.cosmosdb_geo_locations
  cosmosdb_analytical_storage_enabled = var.cosmosdb_analytical_storage_enabled
  cosmosdb_container_max_throughput   = var.cosmosdb_container_max_throughput
  cosmosdb_memory_ttl_seconds         = var.cosmosdb_memory_ttl_seconds

  # Feature flags
  enable_key_vault       = var.feature_flags.enable_key_vault
  enable_storage_account = var.feature_flags.enable_storage_account
  enable_cosmosdb        = var.feature_flags.enable_cosmosdb

  tags = local.common_tags
}

#--------------------------------------------------------------
# AI Services
# AI Foundry, AI Search, Speech, Doc Intel, Computer Vision, Bing
#--------------------------------------------------------------
module "ai_services" {
  source = "../../modules/ai-services"

  resource_group_name = module.resource_group.name
  resource_group_id   = module.resource_group.resource_id
  location            = var.location

  subnet_pe_id               = module.ai_networking.subnet_pe_id
  log_analytics_workspace_id = local.log_analytics_workspace_id

  app_service_principal_id = var.app_service_principal_id

  # Private DNS Zone IDs from hub
  private_dns_zone_blob_id               = local.dns_zone_ids["blob"]
  private_dns_zone_file_id               = local.dns_zone_ids["file"]
  private_dns_zone_keyvault_id           = local.dns_zone_ids["keyvault"]
  private_dns_zone_cognitive_services_id = local.dns_zone_ids["cognitive_services"]
  private_dns_zone_search_id             = local.dns_zone_ids["search"]
  private_dns_zone_aml_api_id            = local.dns_zone_ids["aml_api"]
  private_dns_zone_aml_notebooks_id      = local.dns_zone_ids["aml_notebooks"]

  # AI Foundry
  ai_foundry_hub_name      = var.ai_foundry_hub_name
  ai_foundry_project_name  = var.ai_foundry_project_name
  ai_foundry_storage_name  = var.ai_foundry_storage_name
  ai_foundry_keyvault_name = var.ai_foundry_keyvault_name

  # AI Search
  ai_search_name            = var.ai_search_name
  ai_search_sku             = var.ai_search_sku
  ai_search_replica_count   = var.ai_search_replica_count
  ai_search_partition_count = var.ai_search_partition_count

  # Cognitive Services
  speech_service_name   = var.speech_service_name
  speech_sku            = var.speech_sku
  doc_intelligence_name = var.doc_intelligence_name
  doc_intelligence_sku  = var.doc_intelligence_sku
  computer_vision_name  = var.computer_vision_name
  computer_vision_sku   = var.computer_vision_sku

  # Bing
  bing_search_name        = var.bing_search_name
  bing_search_sku         = var.bing_search_sku
  bing_custom_search_name = var.bing_custom_search_name
  bing_custom_search_sku  = var.bing_custom_search_sku

  # Feature flags
  enable_ai_foundry            = var.feature_flags.enable_ai_foundry
  enable_ai_search             = var.feature_flags.enable_ai_search
  enable_speech                = var.feature_flags.enable_speech
  enable_document_intelligence = var.feature_flags.enable_document_intelligence
  enable_computer_vision       = var.feature_flags.enable_computer_vision
  enable_bing_search           = var.feature_flags.enable_bing_search
  enable_bing_custom_search    = var.feature_flags.enable_bing_custom_search

  tags = local.common_tags
}

#--------------------------------------------------------------
# App Services
# App Service Plan, WebApp (Node.js), WebAPI (.NET),
# Memory Pipeline (.NET), Function App (.NET)
#--------------------------------------------------------------
module "app_services" {
  source = "../../modules/app-services"

  resource_group_name = module.resource_group.name
  resource_group_id   = module.resource_group.resource_id
  location            = var.location

  subnet_app_id  = module.ai_networking.subnet_app_id
  subnet_func_id = module.ai_networking.subnet_func_id
  subnet_pe_id   = module.ai_networking.subnet_pe_id

  private_dns_zone_web_id  = local.dns_zone_ids["web"]
  private_dns_zone_blob_id = local.dns_zone_ids["blob"]

  # App Service Plan
  app_service_plan_name  = var.app_service_plan_name
  app_service_plan_sku   = var.app_service_plan_sku
  enable_zone_redundancy = var.enable_zone_redundancy

  # Runtime versions
  webapp_node_version = var.webapp_node_version
  dotnet_version      = var.dotnet_version

  # App names
  webapp_nodejs_name    = var.webapp_nodejs_name
  webapi_dotnet_name    = var.webapi_dotnet_name
  memory_pipeline_name  = var.memory_pipeline_name
  function_app_name     = var.function_app_name
  func_storage_name     = var.func_storage_name

  # App configuration from upstream modules
  app_insights_connection_string = local.app_insights_connection_string
  key_vault_uri                  = module.data_services.key_vault_uri
  cosmosdb_endpoint              = module.data_services.cosmosdb_endpoint
  cosmosdb_database_name         = module.data_services.cosmosdb_database_name
  # Null-safe: ai_search_name is null when enable_ai_search = false
  ai_search_endpoint             = var.feature_flags.enable_ai_search ? "https://${module.ai_services.ai_search_name}.search.windows.net" : ""
  ai_foundry_endpoint            = "" # Set after AI Foundry deployment
  speech_endpoint                = module.ai_services.speech_service_endpoint
  doc_intelligence_endpoint      = module.ai_services.document_intelligence_endpoint
  computer_vision_endpoint       = module.ai_services.computer_vision_endpoint
  storage_account_name           = module.data_services.storage_account_name

  webapi_cors_origins = var.webapi_cors_origins

  # Feature flags
  enable_webapp_nodejs   = var.feature_flags.enable_webapp_nodejs
  enable_webapi_dotnet   = var.feature_flags.enable_webapi_dotnet
  enable_memory_pipeline = var.feature_flags.enable_memory_pipeline
  enable_function_app    = var.feature_flags.enable_function_app

  tags = local.common_tags
}

#--------------------------------------------------------------
# Realtime Services — SignalR
#--------------------------------------------------------------
module "realtime_services" {
  source = "../../modules/realtime-services"

  resource_group_name = module.resource_group.name
  location            = var.location

  subnet_pe_id                = module.ai_networking.subnet_pe_id
  private_dns_zone_signalr_id = local.dns_zone_ids["signalr"]
  log_analytics_workspace_id  = local.log_analytics_workspace_id

  # Store connection string in Key Vault
  key_vault_id = var.feature_flags.store_signalr_secret_in_key_vault ? module.data_services.key_vault_id : ""

  signalr_name         = var.signalr_name
  signalr_sku          = var.signalr_sku
  signalr_capacity     = var.signalr_capacity
  signalr_cors_origins = var.signalr_cors_origins

  # Feature flag
  enable_signalr = var.feature_flags.enable_signalr

  tags = local.common_tags

  depends_on = [module.data_services]
}
