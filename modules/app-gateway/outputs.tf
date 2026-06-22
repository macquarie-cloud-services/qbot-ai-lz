#--------------------------------------------------------------
# App Gateway Module — Outputs
#--------------------------------------------------------------

output "app_gateway_id" {
  description = "Resource ID of the Application Gateway"
  value       = azurerm_application_gateway.this.id
}

output "app_gateway_name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.this.name
}

output "public_ip_id" {
  description = "Resource ID of the Application Gateway public IP"
  value       = azurerm_public_ip.this.id
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.this.ip_address
}

output "public_fqdn" {
  description = "Azure-assigned FQDN for the Application Gateway public IP (e.g. xxx.australiaeast.cloudapp.azure.com)"
  value       = azurerm_public_ip.this.fqdn
}

output "waf_policy_id" {
  description = "Resource ID of the WAF policy"
  value       = azurerm_web_application_firewall_policy.this.id
}

output "identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity created for Key Vault cert access. Null when ssl_cert_key_vault_secret_id is not set."
  value       = local.use_kv_cert ? azurerm_user_assigned_identity.agw[0].principal_id : null
}
