variable "resource_group_name" {
  description = "Resource group name for all data service resources"
  type        = string
}

variable "resource_group_id" {
  description = "Resource group resource ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "subnet_pe_id" {
  description = "Resource ID of the private endpoint subnet"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace for diagnostic settings"
  type        = string
}

variable "app_service_principal_id" {
  description = "Object ID of the App Services managed identity for RBAC assignments. Leave empty to skip."
  type        = string
  default     = ""
}

#--------------------------------------------------------------
# Private DNS Zone IDs
#--------------------------------------------------------------
variable "private_dns_zone_keyvault_id" {
  description = "Resource ID of the Key Vault private DNS zone"
  type        = string
}

variable "private_dns_zone_blob_id" {
  description = "Resource ID of the Blob Storage private DNS zone"
  type        = string
}

variable "private_dns_zone_file_id" {
  description = "Resource ID of the File Storage private DNS zone"
  type        = string
}

variable "private_dns_zone_cosmosdb_id" {
  description = "Resource ID of the Cosmos DB private DNS zone"
  type        = string
}

#--------------------------------------------------------------
# Key Vault
#--------------------------------------------------------------
variable "key_vault_name" {
  description = "Name for the Key Vault instance (3–24 chars, alphanumeric + hyphens)"
  type        = string
}

#--------------------------------------------------------------
# Storage Account
#--------------------------------------------------------------
variable "storage_account_name" {
  description = "Name for the Storage Account (3–24 chars, lowercase alphanumeric)"
  type        = string
}

variable "storage_replication_type" {
  description = "Storage replication type (LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS)"
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
  description = "Name of the Cosmos DB SQL database"
  type        = string
  default     = "qbot"
}

variable "cosmosdb_consistency_level" {
  description = "Cosmos DB consistency level (Eventual, ConsistentPrefix, Session, BoundedStaleness, Strong)"
  type        = string
  default     = "Session"
}

variable "cosmosdb_geo_locations" {
  description = "List of geo-location objects for Cosmos DB replication. First entry is primary."
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, false)
  }))
}

variable "cosmosdb_analytical_storage_enabled" {
  description = "Enable Cosmos DB analytical store (for Synapse integration)"
  type        = bool
  default     = false
}

variable "cosmosdb_container_max_throughput" {
  description = "Maximum autoscale throughput (RU/s) for Cosmos DB containers"
  type        = number
  default     = 4000
}

variable "cosmosdb_memory_ttl_seconds" {
  description = "TTL in seconds for items in the memory container (-1 to disable)"
  type        = number
  default     = 86400 # 24 hours
}

#--------------------------------------------------------------
# Feature Flags
#--------------------------------------------------------------
variable "enable_key_vault" {
  description = "Deploy the Key Vault instance. Set to false to bring your own Key Vault from outside this module."
  type        = bool
  default     = true
}

variable "enable_storage_account" {
  description = "Deploy the shared Storage Account. Set to false in environments that use an external storage account."
  type        = bool
  default     = true
}

variable "enable_cosmosdb" {
  description = "Deploy the Cosmos DB account, database and containers. Set to false in environments that do not require a NoSQL document store."
  type        = bool
  default     = true
}
