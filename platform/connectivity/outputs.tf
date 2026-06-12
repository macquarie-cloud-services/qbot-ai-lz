#--------------------------------------------------------------
# Platform Connectivity — Outputs
# Consumed by landing-zones/ai via terraform_remote_state.
#--------------------------------------------------------------

output "hub_resource_group_name" {
  description = "Name of the hub resource group"
  value       = module.resource_group_hub.name
}

output "hub_vnet_id" {
  description = "Resource ID of the hub Virtual Network"
  value       = module.hub_vnet.resource_id
}

output "hub_vnet_name" {
  description = "Name of the hub Virtual Network"
  value       = module.hub_vnet.name
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall (null if not deployed)"
  value       = var.enable_firewall ? module.firewall[0].private_ip_address : null
}

# --------------------------------------------------------------
# Private DNS Zone IDs
# Landing zones pass these into modules to register private endpoints
# with the centralised hub-managed DNS zones.
# --------------------------------------------------------------
# output "private_dns_zone_ids" {
#   description = "Map of private DNS zone keys to resource IDs"
#   value = {
#     for key, zone in module.private_dns_zones : key => zone.resource_id
#   }
# }

# output "private_dns_zone_keyvault_id" {
#   description = "Resource ID of the Key Vault private DNS zone"
#   value       = module.private_dns_zones["keyvault"].resource_id
# }

# output "private_dns_zone_blob_id" {
#   description = "Resource ID of the Blob Storage private DNS zone"
#   value       = module.private_dns_zones["blob"].resource_id
# }

# output "private_dns_zone_file_id" {
#   description = "Resource ID of the File Storage private DNS zone"
#   value       = module.private_dns_zones["file"].resource_id
# }

# output "private_dns_zone_web_id" {
#   description = "Resource ID of the App Services / Functions private DNS zone"
#   value       = module.private_dns_zones["web"].resource_id
# }

# output "private_dns_zone_cosmosdb_id" {
#   description = "Resource ID of the Cosmos DB (NoSQL) private DNS zone"
#   value       = module.private_dns_zones["cosmosdb"].resource_id
# }

# output "private_dns_zone_search_id" {
#   description = "Resource ID of the AI Search private DNS zone"
#   value       = module.private_dns_zones["search"].resource_id
# }

# output "private_dns_zone_cognitive_services_id" {
#   description = "Resource ID of the Cognitive Services (Speech, Doc Intelligence, Computer Vision) private DNS zone"
#   value       = module.private_dns_zones["cognitive_services"].resource_id
# }

# output "private_dns_zone_openai_id" {
#   description = "Resource ID of the Azure OpenAI private DNS zone"
#   value       = module.private_dns_zones["openai"].resource_id
# }

# output "private_dns_zone_aml_api_id" {
#   description = "Resource ID of the AI Foundry (AML) API private DNS zone"
#   value       = module.private_dns_zones["aml_api"].resource_id
# }

# output "private_dns_zone_aml_notebooks_id" {
#   description = "Resource ID of the AI Foundry Notebooks private DNS zone"
#   value       = module.private_dns_zones["aml_notebooks"].resource_id
# }

# output "private_dns_zone_signalr_id" {
#   description = "Resource ID of the SignalR private DNS zone"
#   value       = module.private_dns_zones["signalr"].resource_id
# }

# output "private_dns_zone_monitor_id" {
#   description = "Resource ID of the Azure Monitor private DNS zone"
#   value       = module.private_dns_zones["monitor"].resource_id
# }

output "hub_nsg_ids" {
  description = "Map of NSG key to resource ID for every custom NSG defined in var.network_security_groups. Use this in landing zone configurations that need to reference a hub NSG."
  value       = { for k, _ in var.network_security_groups : k => module.hub_nsgs[k].resource_id }
}
