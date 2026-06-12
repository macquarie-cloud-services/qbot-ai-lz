output "spoke_vnet_id" {
  description = "Resource ID of the AI spoke Virtual Network"
  value       = module.spoke_vnet.resource_id
}

output "spoke_vnet_name" {
  description = "Name of the AI spoke Virtual Network"
  value       = module.spoke_vnet.name
}

# Map of all NSG keys → resource IDs (both built-in and custom).
output "nsg_ids" {
  description = "Map of every NSG key to its resource ID. Includes the five built-in NSGs (app, func, data, pe, mgmt) and any custom NSGs defined via var.network_security_groups."
  value       = local._nsg_ids
}

# Map of all subnet keys → resource IDs. Use this to reference any extra subnets
# added via the subnets variable that are not covered by the named outputs below.
output "subnet_ids" {
  description = "Map of every subnet key to its resource ID. Useful for accessing custom subnets added via var.subnets."
  value       = { for k, s in module.spoke_vnet.subnets : k => s.resource_id }
}

output "subnet_app_id" {
  description = "Resource ID of the app services subnet (key 'app' in var.subnets)"
  value       = module.spoke_vnet.subnets["app"].resource_id
}

output "subnet_func_id" {
  description = "Resource ID of the function app subnet (key 'func' in var.subnets)"
  value       = module.spoke_vnet.subnets["func"].resource_id
}

output "subnet_data_id" {
  description = "Resource ID of the data-tier subnet (key 'data' in var.subnets)"
  value       = module.spoke_vnet.subnets["data"].resource_id
}

output "subnet_svc_id" {
  description = "Resource ID of the AI services subnet (key 'svc' in var.subnets)"
  value       = module.spoke_vnet.subnets["svc"].resource_id
}

output "subnet_pe_id" {
  description = "Resource ID of the private endpoints subnet (key 'pe' in var.subnets)"
  value       = module.spoke_vnet.subnets["pe"].resource_id
}

output "subnet_mgmt_id" {
  description = "Resource ID of the management subnet (key 'mgmt' in var.subnets)"
  value       = module.spoke_vnet.subnets["mgmt"].resource_id
}
