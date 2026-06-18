output "key_vault_id" {
  description = "Resource ID of the Key Vault. Null when enable_key_vault = false."
  value       = var.enable_key_vault ? module.key_vault[0].resource_id : null
}

output "key_vault_uri" {
  description = "URI of the Key Vault. Null when enable_key_vault = false."
  value       = var.enable_key_vault ? module.key_vault[0].uri : null
}

output "storage_account_id" {
  description = "Resource ID of the Storage Account. Null when enable_storage_account = false."
  value       = var.enable_storage_account ? module.storage_account[0].resource_id : null
}

output "storage_account_name" {
  description = "Name of the Storage Account. Null when enable_storage_account = false."
  value       = var.enable_storage_account ? module.storage_account[0].name : null
}

output "cosmosdb_id" {
  description = "Resource ID of the Cosmos DB account. Null when enable_cosmosdb = false."
  value       = var.enable_cosmosdb ? module.cosmosdb[0].resource_id : null
}

output "cosmosdb_endpoint" {
  description = "Endpoint URL of the Cosmos DB account. Null when enable_cosmosdb = false."
  value       = var.enable_cosmosdb ? module.cosmosdb[0].endpoint : null
}

output "cosmosdb_database_name" {
  description = "Name of the Cosmos DB SQL database. Null when enable_cosmosdb = false."
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_sql_database.main[0].name : null
}
