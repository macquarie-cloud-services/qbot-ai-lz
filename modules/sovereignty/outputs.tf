#--------------------------------------------------------------
# Sovereignty Module — Outputs
#--------------------------------------------------------------

output "policies_assigned" {
  description = "Azure Policy assignments enforcing sovereignty controls"
  value = {
    deny_public_keyvault    = var.sovereignty_profile.enforce_private_only ? "Assigned" : "Skipped"
    deny_public_storage     = var.sovereignty_profile.enforce_private_only ? "Assigned" : "Skipped"
    deny_public_cosmosdb    = var.sovereignty_profile.enforce_private_only ? "Assigned" : "Skipped"
    require_cmk_storage     = var.sovereignty_profile.enforce_cmk ? "Assigned" : "Skipped"
    allowed_regions         = var.sovereignty_profile.enforce_region_lock ? "Assigned" : "Skipped"
    require_managed_identity = var.sovereignty_profile.enforce_identity ? "Assigned" : "Skipped"
  }
}

output "network_enforcement" {
  description = "Network-layer sovereignty enforcement status"
  value       = (local.sovereignty_enabled && var.sovereignty_profile.enforce_private_only) ? module.sovereignty_network[0].network_security_status : null
}

output "encryption_enforcement" {
  description = "Encryption-layer sovereignty enforcement status"
  value       = (local.sovereignty_enabled && var.sovereignty_profile.enforce_cmk) ? module.sovereignty_encryption[0].encryption_enforcement_status : null
}

output "identity_enforcement" {
  description = "Identity-layer sovereignty enforcement status"
  value       = (local.sovereignty_enabled && var.sovereignty_profile.enforce_identity) ? module.sovereignty_identity[0].identity_enforcement_status : null
}

output "sovereignty_status" {
  description = "Overall sovereignty compliance posture"
  value = {
    enabled                  = var.sovereignty_profile.enabled
    profile                  = var.sovereignty_profile
    deployment_region        = var.location
    management_group_scope   = var.management_group_id
    enforcement_timestamp    = timestamp()
  }
}
