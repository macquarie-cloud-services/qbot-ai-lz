#--------------------------------------------------------------
# AI Landing Zone — Variables
#--------------------------------------------------------------

variable "spoke_subscription_id" {
  description = "Azure subscription ID for this landing zone (spoke) deployment"
  type        = string
}

variable "hub_subscription_id" {
  description = "Azure subscription ID where the hub (platform/connectivity) is deployed. Set equal to spoke_subscription_id when hub and spoke share the same subscription."
  type        = string
}

variable "location" {
  description = "Azure region for this landing zone deployment"
  type        = string
}

variable "location_code" {
  description = "Short location code (e.g. 'aue' for australiaeast, 'ause' for australiasoutheast)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "Name for the AI landing zone resource group"
  type        = string
}

variable "app_service_principal_id" {
  description = "Object ID of the App Services managed identity for RBAC. Populate after first apply."
  type        = string
  default     = ""
}

#--------------------------------------------------------------
# Hub Connectivity Remote State
#--------------------------------------------------------------
variable "hub_tfstate_resource_group_name" {
  description = "Resource group of the tfstate storage account (hub connectivity state)"
  type        = string
}

variable "hub_tfstate_storage_account_name" {
  description = "Storage account name for hub connectivity tfstate"
  type        = string
}

variable "hub_tfstate_container_name" {
  description = "Container name for hub connectivity tfstate"
  type        = string
}

variable "hub_tfstate_key" {
  description = "State file key for the hub connectivity layer (e.g. qbot-platform-connectivity-aue.tfstate)"
  type        = string
}

#--------------------------------------------------------------
# Management Remote State
#--------------------------------------------------------------
variable "mgmt_tfstate_resource_group_name" {
  description = "Resource group of the tfstate storage account (management state)"
  type        = string
}

variable "mgmt_tfstate_storage_account_name" {
  description = "Storage account name for management tfstate"
  type        = string
}

variable "mgmt_tfstate_container_name" {
  description = "Container name for management tfstate"
  type        = string
}

variable "mgmt_tfstate_key" {
  description = "State file key for the management layer"
  type        = string
}

#--------------------------------------------------------------
# Networking
#--------------------------------------------------------------
variable "vnet_name" {
  description = "Name for the AI spoke Virtual Network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the AI spoke Virtual Network"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets for the AI spoke VNet. Passed directly to the ai-networking module. See modules/ai-networking/variables.tf for field documentation."
  type = map(object({
    name                              = string
    address_prefixes                  = list(string)
    nsg_key                           = optional(string)
    private_endpoint_network_policies = optional(string)
    delegation = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })))
  }))
}

variable "network_security_groups" {
  description = "Map of custom NSGs to create in the spoke in addition to the five module-managed NSGs. Keys must match nsg_key values used in var.subnets. Reserved keys app, func, data, pe, mgmt must not be used."
  type = map(object({
    name = string
    security_rules = optional(map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
  }))
  default = {}
}

variable "use_remote_gateways" {
  description = "Use hub VPN/ExpressRoute gateways. Set true only if VPN gateway deployed."
  type        = bool
  default     = false
}

#--------------------------------------------------------------
# Key Vault
#--------------------------------------------------------------
variable "key_vault_name" {
  description = "Name for the Key Vault"
  type        = string
}

#--------------------------------------------------------------
# Storage Account
#--------------------------------------------------------------
variable "storage_account_name" {
  description = "Name for the main Storage Account"
  type        = string
}

variable "storage_replication_type" {
  description = "Storage replication type (LRS, ZRS, GRS)"
  type        = string
  default     = "ZRS"
}

#--------------------------------------------------------------
# Cosmos DB
#--------------------------------------------------------------
variable "cosmosdb_account_name" {
  description = "Name for the Cosmos DB account"
  type        = string
}

variable "cosmosdb_database_name" {
  description = "Cosmos DB SQL database name"
  type        = string
  default     = "qbot"
}

variable "cosmosdb_consistency_level" {
  description = "Cosmos DB consistency level"
  type        = string
  default     = "Session"
}

variable "cosmosdb_geo_locations" {
  description = "Geo-replication locations for Cosmos DB"
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, false)
  }))
}

variable "cosmosdb_analytical_storage_enabled" {
  description = "Enable Cosmos DB analytical store"
  type        = bool
  default     = false
}

variable "cosmosdb_container_max_throughput" {
  description = "Max autoscale RU/s for Cosmos DB containers"
  type        = number
  default     = 4000
}

variable "cosmosdb_memory_ttl_seconds" {
  description = "TTL in seconds for memory container items"
  type        = number
  default     = 86400
}

#--------------------------------------------------------------
# AI Foundry
#--------------------------------------------------------------
variable "ai_foundry_hub_name" {
  description = "Name for the AI Foundry Hub"
  type        = string
}

variable "ai_foundry_project_name" {
  description = "Name for the AI Foundry Project"
  type        = string
}

variable "ai_foundry_storage_name" {
  description = "Storage account name for AI Foundry Hub"
  type        = string
}

variable "ai_foundry_keyvault_name" {
  description = "Key Vault name for AI Foundry Hub"
  type        = string
}

#--------------------------------------------------------------
# AI Search
#--------------------------------------------------------------
variable "ai_search_name" {
  description = "Name for the AI Search service"
  type        = string
}

variable "ai_search_sku" {
  description = "SKU for AI Search (basic, standard, standard2, standard3)"
  type        = string
  default     = "basic"
}

variable "ai_search_replica_count" {
  description = "Number of AI Search replicas"
  type        = number
  default     = 1
}

variable "ai_search_partition_count" {
  description = "Number of AI Search partitions"
  type        = number
  default     = 1
}

#--------------------------------------------------------------
# Cognitive Services
#--------------------------------------------------------------
variable "speech_service_name" {
  description = "Name for the Speech Service"
  type        = string
}

variable "speech_sku" {
  description = "SKU for Speech Service (F0, S0)"
  type        = string
  default     = "S0"
}

variable "doc_intelligence_name" {
  description = "Name for the Document Intelligence service"
  type        = string
}

variable "doc_intelligence_sku" {
  description = "SKU for Document Intelligence (F0, S0)"
  type        = string
  default     = "S0"
}

variable "computer_vision_name" {
  description = "Name for the Computer Vision service"
  type        = string
}

variable "computer_vision_sku" {
  description = "SKU for Computer Vision (F0, S1)"
  type        = string
  default     = "S1"
}

#--------------------------------------------------------------
# Bing
#--------------------------------------------------------------
variable "bing_search_name" {
  description = "Name for the Bing Search (Grounding) resource. Required when enable_bing_search = true."
  type        = string
  default     = ""
}

variable "bing_search_sku" {
  description = "SKU for Bing Search grounding"
  type        = string
  default     = "G1"
}

variable "bing_custom_search_name" {
  description = "Name for the Bing Custom Search resource. Required when enable_bing_custom_search = true."
  type        = string
  default     = ""
}

variable "bing_custom_search_sku" {
  description = "SKU for Bing Custom Search"
  type        = string
  default     = "S1"
}

#--------------------------------------------------------------
# App Services
#--------------------------------------------------------------
variable "app_service_plan_name" {
  description = "Name for the App Service Plan"
  type        = string
}

variable "app_service_plan_sku" {
  description = "SKU for the App Service Plan (P1v3, P2v3, P3v3)"
  type        = string
  default     = "P1v3"
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for App Service Plan"
  type        = bool
  default     = false
}

variable "webapp_node_version" {
  description = "Node.js version for the WebApp"
  type        = string
  default     = "20-lts"
}

variable "dotnet_version" {
  description = ".NET version for WebAPI, Memory Pipeline, and Function App"
  type        = string
  default     = "8.0"
}

variable "webapp_nodejs_name" {
  description = "Name for the Node.js WebApp"
  type        = string
}

variable "webapi_dotnet_name" {
  description = "Name for the .NET WebAPI"
  type        = string
}

variable "memory_pipeline_name" {
  description = "Name for the .NET Memory Pipeline App Service"
  type        = string
}

variable "function_app_name" {
  description = "Name for the .NET Function App"
  type        = string
}

variable "func_storage_name" {
  description = "Name for the Function App storage account"
  type        = string
}

variable "webapi_cors_origins" {
  description = "CORS allowed origins for WebAPI"
  type        = list(string)
  default     = []
}

#--------------------------------------------------------------
# SignalR
#--------------------------------------------------------------
variable "signalr_name" {
  description = "Name for the Azure SignalR Service"
  type        = string
}

variable "signalr_sku" {
  description = "SKU for SignalR Service"
  type        = string
  default     = "Standard_S1"
}

variable "signalr_capacity" {
  description = "Number of SignalR units"
  type        = number
  default     = 1
}

variable "signalr_cors_origins" {
  description = "CORS allowed origins for SignalR"
  type        = list(string)
  default     = []
}

#--------------------------------------------------------------
# Feature Flags
#
# Single object that controls which services are deployed in this
# landing zone. All defaults are defined here — the authoritative
# source of truth for the landing zone. Override specific flags in
# the environment .tfvars file without touching module code.
#
# Usage in .tfvars:
#   feature_flags = {
#     enable_cosmosdb   = true
#     enable_ai_foundry = true
#   }
#--------------------------------------------------------------
variable "feature_flags" {
  description = "Feature toggles controlling which services are deployed. All fields are optional — unset fields use the defaults defined here."
  type = object({
    # Networking
    enable_hub_peering = optional(bool, true)

    # Data services
    enable_key_vault       = optional(bool, true)
    enable_storage_account = optional(bool, true)
    enable_cosmosdb        = optional(bool, false)

    # AI services
    enable_ai_foundry            = optional(bool, false)
    enable_ai_search             = optional(bool, false)
    enable_speech                = optional(bool, false)
    enable_document_intelligence = optional(bool, false)
    enable_computer_vision       = optional(bool, false)
    enable_bing_search           = optional(bool, false)
    enable_bing_custom_search    = optional(bool, false)

    # App services
    enable_webapp_nodejs   = optional(bool, true)
    enable_webapi_dotnet   = optional(bool, true)
    enable_memory_pipeline = optional(bool, false)
    enable_function_app    = optional(bool, false)

    # Realtime services
    enable_signalr                      = optional(bool, false)
    store_signalr_secret_in_key_vault  = optional(bool, true)
  })
  default = {}
}
