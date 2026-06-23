#--------------------------------------------------------------
# Sovereignty Module — Main
#
# Orchestrates sovereign/regulated compliance controls.
# Conditionally applies policies, network isolation, encryption, and identity controls.
#--------------------------------------------------------------

locals {
  sovereignty_enabled = var.sovereignty_profile.enabled

  common_tags = merge(var.tags, {
    Sovereignty = "Enabled"
    ManagedBy   = "Terraform-Sovereignty-Module"
  })
}

#--------------------------------------------------------------
# Sovereignty Policies (Azure Policy assignments for compliance)
#--------------------------------------------------------------
module "sovereignty_policies" {
  count  = local.sovereignty_enabled ? 1 : 0
  source = "./policies"

  management_group_id      = var.management_group_id
  enforce_private_only     = var.sovereignty_profile.enforce_private_only
  enforce_cmk              = var.sovereignty_profile.enforce_cmk
  enforce_region_lock      = var.sovereignty_profile.enforce_region_lock
  enforce_identity         = var.sovereignty_profile.enforce_identity
  allowed_regions          = var.allowed_regions
  environment              = var.environment
  tags                     = local.common_tags
}

#--------------------------------------------------------------
# Sovereignty Network Controls
# Enforces private-only networking and NSG micro-segmentation.
#--------------------------------------------------------------
module "sovereignty_network" {
  count  = local.sovereignty_enabled && var.sovereignty_profile.enforce_private_only ? 1 : 0
  source = "./network"

  location            = var.location
  resource_group_id   = var.resource_group_id
  environment         = var.environment
  tags                = local.common_tags
}

#--------------------------------------------------------------
# Sovereignty Encryption (CMK enforcement)
# Enforces customer-managed keys for all data at rest.
#--------------------------------------------------------------
module "sovereignty_encryption" {
  count  = local.sovereignty_enabled && var.sovereignty_profile.enforce_cmk ? 1 : 0
  source = "./encryption"

  location              = var.location
  resource_group_id     = var.resource_group_id
  cmk_key_vault_id      = var.cmk_key_vault_id
  environment           = var.environment
  tags                  = local.common_tags
}

#--------------------------------------------------------------
# Sovereignty Identity (Managed identity-only auth)
# Enforces system-assigned identities and disables shared keys.
#--------------------------------------------------------------
module "sovereignty_identity" {
  count  = local.sovereignty_enabled && var.sovereignty_profile.enforce_identity ? 1 : 0
  source = "./identity"

  location            = var.location
  resource_group_id   = var.resource_group_id
  environment         = var.environment
  tags                = local.common_tags
}
