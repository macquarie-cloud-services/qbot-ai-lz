#--------------------------------------------------------------
# Platform Policy — Main
#
# Custom Azure Policy definitions and assignments scoped to the
# QBot AI Landing Zone subscription. Enforces:
#
#   SECURITY
#   · Deny public network access on Key Vault
#   · Deny public network access on Cognitive Services
#   · Deny public network access on AI Search
#   · Deny public network access on Cosmos DB
#   · Deny public network access on Storage Accounts
#
#   GOVERNANCE
#   · Require HTTPS-only on App Services
#   · Require managed identity on App Services
#   · Require tag enforcement (Environment, CostCenter, TechOwner)
#
#   OBSERVABILITY
#   · DeployIfNotExists — diagnostic settings → Log Analytics
#     for Cognitive Services, Key Vault, Storage, Cosmos DB, AI Search
#--------------------------------------------------------------

data "azurerm_subscription" "current" {}

locals {
  scope = data.azurerm_subscription.current.id
  common_tags = merge(var.tags, {
    Layer     = "platform-policy"
    ManagedBy = "Terraform-AVM"
  })
}

# --------------------------------------------------------------
# Policy Resource Group (for policy-related tracking resources)
# --------------------------------------------------------------
resource "azurerm_resource_group" "policy" {
  name     = "rg-qbot-policy"
  location = var.location
  tags     = local.common_tags
}

#================================================================
# CUSTOM POLICY DEFINITIONS
#================================================================

#--------------------------------------------------------------
# Deny Public Network Access — Key Vault
#--------------------------------------------------------------
resource "azurerm_policy_definition" "deny_keyvault_public_access" {
  name         = "qbot-deny-keyvault-public-access"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "QBot: Deny public network access on Key Vault"
  description  = "Ensures Key Vault instances do not have public network access enabled."

  metadata = jsonencode({
    category = "Key Vault"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.KeyVault/vaults"
        },
        {
          field  = "Microsoft.KeyVault/vaults/networkAcls.defaultAction"
          equals = "Allow"
        }
      ]
    }
    then = {
      effect = var.policy_effect_public_access
    }
  })
}

#--------------------------------------------------------------
# Deny Public Network Access — Cognitive Services
#--------------------------------------------------------------
resource "azurerm_policy_definition" "deny_cognitive_public_access" {
  name         = "qbot-deny-cognitive-public-access"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "QBot: Deny public network access on Cognitive Services"
  description  = "Ensures Cognitive Services accounts (AI Foundry, Speech, Doc Intelligence, Computer Vision) disable public network access."

  metadata = jsonencode({
    category = "Cognitive Services"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.CognitiveServices/accounts"
        },
        {
          field  = "Microsoft.CognitiveServices/accounts/publicNetworkAccess"
          equals = "Enabled"
        }
      ]
    }
    then = {
      effect = var.policy_effect_public_access
    }
  })
}

#--------------------------------------------------------------
# Deny Public Network Access — AI Search
#--------------------------------------------------------------
resource "azurerm_policy_definition" "deny_search_public_access" {
  name         = "qbot-deny-search-public-access"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "QBot: Deny public network access on AI Search"
  description  = "Ensures Azure AI Search services disable public network access."

  metadata = jsonencode({
    category = "AI + Machine Learning"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Search/searchServices"
        },
        {
          field  = "Microsoft.Search/searchServices/publicNetworkAccess"
          equals = "Enabled"
        }
      ]
    }
    then = {
      effect = var.policy_effect_public_access
    }
  })
}

#--------------------------------------------------------------
# Deny Public Network Access — Cosmos DB
#--------------------------------------------------------------
resource "azurerm_policy_definition" "deny_cosmosdb_public_access" {
  name         = "qbot-deny-cosmosdb-public-access"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "QBot: Deny public network access on Cosmos DB"
  description  = "Ensures Cosmos DB accounts disable public network access."

  metadata = jsonencode({
    category = "Cosmos DB"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.DocumentDB/databaseAccounts"
        },
        {
          field  = "Microsoft.DocumentDB/databaseAccounts/publicNetworkAccess"
          equals = "Enabled"
        }
      ]
    }
    then = {
      effect = var.policy_effect_public_access
    }
  })
}

#--------------------------------------------------------------
# Deny Public Network Access — Storage Accounts
#--------------------------------------------------------------
resource "azurerm_policy_definition" "deny_storage_public_access" {
  name         = "qbot-deny-storage-public-access"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "QBot: Deny public blob access on Storage Accounts"
  description  = "Ensures Storage Accounts have public blob access disabled."

  metadata = jsonencode({
    category = "Storage"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field  = "Microsoft.Storage/storageAccounts/allowBlobPublicAccess"
          equals = "true"
        }
      ]
    }
    then = {
      effect = var.policy_effect_public_access
    }
  })
}

#--------------------------------------------------------------
# Require HTTPS-only on App Services
#--------------------------------------------------------------
resource "azurerm_policy_definition" "require_https_app_service" {
  name         = "qbot-require-https-app-service"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "QBot: Require HTTPS-only on App Services"
  description  = "Ensures all App Services (web apps, APIs, function apps) enforce HTTPS-only."

  metadata = jsonencode({
    category = "App Service"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Web/sites"
        },
        {
          field  = "Microsoft.Web/sites/httpsOnly"
          equals = "false"
        }
      ]
    }
    then = {
      effect = "Audit"
    }
  })
}

#--------------------------------------------------------------
# Require Minimum TLS 1.2 on Storage Accounts
#--------------------------------------------------------------
resource "azurerm_policy_definition" "require_storage_tls12" {
  name         = "qbot-require-storage-tls12"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "QBot: Require TLS 1.2 minimum on Storage Accounts"
  description  = "Ensures Storage Accounts enforce a minimum TLS version of 1.2."

  metadata = jsonencode({
    category = "Storage"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field  = "Microsoft.Storage/storageAccounts/minimumTlsVersion"
          notEquals = "TLS1_2"
        }
      ]
    }
    then = {
      effect = var.policy_effect_public_access
    }
  })
}

#================================================================
# POLICY INITIATIVE (Policy Set) — QBot AI Security Baseline
#================================================================
resource "azurerm_policy_set_definition" "qbot_ai_security_baseline" {
  name         = "qbot-ai-security-baseline"
  policy_type  = "Custom"
  display_name = "QBot AI Security Baseline"
  description  = "Combined security policy initiative for the QBot AI Landing Zone. Enforces private networking, encryption in transit, and governance controls."

  metadata = jsonencode({
    category = "QBot AI Landing Zone"
    version  = "1.0.0"
  })

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_keyvault_public_access.id
    reference_id         = "deny-keyvault-public-access"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_cognitive_public_access.id
    reference_id         = "deny-cognitive-public-access"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_search_public_access.id
    reference_id         = "deny-search-public-access"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_cosmosdb_public_access.id
    reference_id         = "deny-cosmosdb-public-access"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_storage_public_access.id
    reference_id         = "deny-storage-public-access"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_https_app_service.id
    reference_id         = "require-https-app-service"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_storage_tls12.id
    reference_id         = "require-storage-tls12"
  }

  # Built-in: Require managed identity on App Services
  # https://www.azadvertizer.net/azpolicyadvertizer/2b9ad585-36bc-4615-b300-fd4435808332.html; Default effect is AuditIfNotExists, can be overridden to Disabled if desired.
  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2b9ad585-36bc-4615-b300-fd4435808332"
    reference_id         = "require-app-service-managed-identity"
  }

  # Built-in: Azure Cosmos DB should use customer-managed keys
  # https://www.azadvertizer.net/azpolicyadvertizer/1f905d99-2ab7-462c-a6b0-f709acca6c8f.html; Default effect is Audit, can be overridden to Deny after proper testing.
  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1f905d99-2ab7-462c-a6b0-f709acca6c8f"
    reference_id         = "cosmosdb-customer-managed-keys-audit" 
  }
}

# ================================================================
# POLICY ASSIGNMENTS — Subscription Scope
# ================================================================

resource "azurerm_subscription_policy_assignment" "qbot_ai_security_baseline" {
  name                 = "qbot-ai-security-baseline"
  display_name         = "QBot AI Security Baseline"
  subscription_id      = local.scope
  policy_definition_id = azurerm_policy_set_definition.qbot_ai_security_baseline.id
  description          = "Assigns the QBot AI Security Baseline initiative to the subscription"

  identity {
    type = "SystemAssigned"
  }

  location = var.location
}

# --------------------------------------------------------------
# Tag enforcement — built-in policy for each required tag
# Built-in: Require a tag on resources (policy ID: 871b6d14-10aa-478d-b590-94f262ecfa99)
# --------------------------------------------------------------
resource "azurerm_subscription_policy_assignment" "require_environment_tag" {
  name                 = "qbot-require-environment-tag"
  display_name         = "QBot: Require Environment tag on resources"
  subscription_id      = local.scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"

  parameters = jsonencode({
    tagName = { value = "Environment" }
  })
}

resource "azurerm_subscription_policy_assignment" "require_costcenter_tag" {
  name                 = "qbot-require-costcenter-tag"
  display_name         = "QBot: Require CostCenter tag on resources"
  subscription_id      = local.scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"

  parameters = jsonencode({
    tagName = { value = "CostCenter" }
  })
}

resource "azurerm_subscription_policy_assignment" "require_techowner_tag" {
  name                 = "qbot-require-techowner-tag"
  display_name         = "QBot: Require TechOwner tag on resources"
  subscription_id      = local.scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"

  parameters = jsonencode({
    tagName = { value = "TechOwner" }
  })
}
