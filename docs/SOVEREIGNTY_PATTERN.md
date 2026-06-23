#--------------------------------------------------------------
# Sovereignty Landing Zone Pattern
#
# Comprehensive guide to implementing sovereign/regulated compliance
# controls on top of the qbot-ai-lz landing zone codebase.
#--------------------------------------------------------------

## Overview

The **Sovereignty Landing Zone Pattern** enables a **single reusable codebase** to support both regulated (sovereign) and non-regulated customer deployments without code duplication. Using **feature flags** and a dedicated `sovereignty` module, you can toggle granular compliance controls on-demand.

**Key Principle:** One codebase, unlimited compliance postures.

---

## Architecture

```
landing-zones/ai/
├── main.tf                          # Orchestrator (calls app services, sovereignty module, etc.)
├── variables.tf                     # Feature flags + sovereignty_profile
├── dev-aue.tfvars                   # Dev (non-regulated)
├── prod-aue.tfvars                  # Prod (non-regulated)
└── sovereign-aue.tfvars             # Sovereign (regulated) — fully compliant

modules/
├── app-services/                    # App Service Plan, WebApp, WebAPI
├── data-services/                   # Key Vault, Storage, Cosmos DB
├── ai-services/                     # AI Foundry, AI Search, Speech, etc.
├── realtime-services/               # SignalR
└── sovereignty/                     # NEW — Regulatory compliance controls
    ├── main.tf                      # Orchestrator for policies, network, encryption, identity
    ├── variables.tf                 # sovereignty_profile + input controls
    ├── outputs.tf                   # Compliance status, policy assignments
    ├── policies/
    │   ├── main.tf                  # Azure Policy assignments
    │   └── variables.tf
    ├── network/
    │   ├── main.tf                  # Private-only enforcement, NSG rules
    │   └── variables.tf
    ├── encryption/
    │   ├── main.tf                  # CMK enforcement, encryption policies
    │   └── variables.tf
    └── identity/
        ├── main.tf                  # Managed identity-only auth
        └── variables.tf
```

---

## Sovereignty Profile — Multi-Level Toggle

Instead of a simple boolean, the `sovereignty_profile` object provides **granular control** over individual compliance dimensions:

```hcl
variable "sovereignty_profile" {
  type = object({
    enabled              = bool  # Master toggle: enables all sovereignty features
    enforce_private_only = bool  # Deny all public endpoints (Key Vault, Storage, Cosmos DB, AI services)
    enforce_cmk          = bool  # Require customer-managed keys for encryption
    enforce_region_lock  = bool  # Restrict deployments to single region (data residency)
    enforce_identity     = bool  # Require managed identity-only auth (no shared keys)
  })

  default = {
    enabled              = false
    enforce_private_only = false
    enforce_cmk          = false
    enforce_region_lock  = false
    enforce_identity     = false
  }
}
```

### Control Dimensions

| Dimension | When Enabled | What It Enforces |
|-----------|--------------|-----------------|
| **enabled** | `true` | Master toggle; enables all sovereignty controls |
| **enforce_private_only** | `true` | Azure Policy: Deny public endpoints on KV, Storage, Cosmos DB, Cognitive Services; require Private Endpoints |
| **enforce_cmk** | `true` | Azure Policy: Require customer-managed keys for all encryption-at-rest; disable service-managed encryption |
| **enforce_region_lock** | `true` | Azure Policy: Restrict resource deployments to `allowed_regions` list (data residency, regulatory jurisdiction) |
| **enforce_identity** | `true` | Azure Policy: Require system-assigned managed identity on App Services; disable shared keys / connection strings |

---

## How It Works

### 1. **Non-Regulated Deployment (Standard)**

```bash
# Deploy non-regulated environment (e.g., dev, prod)
cd landing-zones/ai
terraform apply -var-file="dev-aue.tfvars"
```

**dev-aue.tfvars:**
```hcl
sovereignty_profile = {
  enabled              = false
  enforce_private_only = false
  enforce_cmk          = false
  enforce_region_lock  = false
  enforce_identity     = false
}
```

**Result:** Standard deployment with public endpoints, service-managed encryption, shared keys allowed.

---

### 2. **Regulated Deployment (Sovereign)**

```bash
# Deploy sovereign/regulated environment
cd landing-zones/ai
terraform apply -var-file="sovereign-aue.tfvars"
```

**sovereign-aue.tfvars:**
```hcl
# Enable all sovereignty controls
sovereignty_profile = {
  enabled              = true
  enforce_private_only = true
  enforce_cmk          = true
  enforce_region_lock  = true
  enforce_identity     = true
}

# Required for sovereignty enforcement
management_group_id  = "/subscriptions/YOUR_SUBSCRIPTION_ID"  # MG scope for policy assignments
cmk_key_vault_id     = "/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/kv-cmk"
allowed_regions      = ["australiaeast"]  # Data residency lock
```

**Result:** 
- ✓ All public endpoints denied (Private Endpoint-only)
- ✓ All encryption uses customer-managed keys
- ✓ Deployments restricted to australiaeast only
- ✓ Managed identity-only authentication enforced
- ✓ Azure Policy assignments active at subscription/MG level

---

## Implementation Details

### Module Invocation (landing-zones/ai/main.tf)

```hcl
module "sovereignty" {
  source = "../../modules/sovereignty"

  # Conditional instantiation: only runs if sovereignty_profile.enabled = true
  count = var.sovereignty_profile.enabled ? 1 : 0

  location             = var.location
  environment          = var.environment
  resource_group_id    = module.resource_group.resource_id
  management_group_id  = var.management_group_id
  cmk_key_vault_id     = var.cmk_key_vault_id
  allowed_regions      = var.allowed_regions
  sovereignty_profile  = var.sovereignty_profile
  tags                 = local.common_tags
}
```

**Key Points:**
- `count = var.sovereignty_profile.enabled ? 1 : 0` → Module only instantiated when enabled
- All sub-modules (policies, network, encryption, identity) are **conditionally instantiated** within the sovereignty module
- No code duplication in core modules (app-services, data-services, etc.)

---

### Sub-Module Conditional Logic (modules/sovereignty/main.tf)

```hcl
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

module "sovereignty_network" {
  count  = local.sovereignty_enabled && var.sovereignty_profile.enforce_private_only ? 1 : 0
  source = "./network"

  location            = var.location
  resource_group_id   = var.resource_group_id
  environment         = var.environment
  tags                = local.common_tags
}
```

Each sub-module only runs if its specific toggle is enabled. This provides **fine-grained compliance control**.

---

## Deployment Checklist

### Prerequisites (for Sovereign Deployments)

- [ ] **Azure Subscription** with appropriate permissions (Policy.Write at subscription/MG scope)
- [ ] **Management Group ID** where policies will be assigned
- [ ] **Customer-Managed Key Vault** (Premium SKU) with CMK for encryption
- [ ] **Private Endpoints configured** for Key Vault (policy will deny public access)
- [ ] **DNS private zones** for all services (policies enforce private-only)

### Deployment Steps

1. **Prepare tfvars file** (sovereign-aue.tfvars)
   ```bash
   cp dev-aue.tfvars sovereign-aue.tfvars
   # Edit and set sovereignty_profile.enabled = true
   ```

2. **Populate sovereignty parameters**
   ```hcl
   management_group_id  = "/subscriptions/YOUR_SUB_ID"  # Or /providers/Microsoft.Management/managementGroups/YOUR_MG_ID
   cmk_key_vault_id     = "/subscriptions/.../..."
   allowed_regions      = ["australiaeast"]
   ```

3. **Plan deployment**
   ```bash
   cd landing-zones/ai
   terraform plan -var-file="sovereign-aue.tfvars" -out=tfplan
   ```

4. **Review policy assignments**
   The plan will show Azure Policy assignments for:
   - Deny public network access (Key Vault, Storage, Cosmos DB)
   - Require managed identity (App Services)
   - Allowed locations (data residency)

5. **Apply**
   ```bash
   terraform apply tfplan
   ```

6. **Verify compliance**
   ```bash
   terraform output sovereignty_status
   ```

---

## Compliance Controls Summary

### 1. **Private-Only Network Access** (`enforce_private_only = true`)

**Azure Policies Assigned:**
- Deny public network access to Key Vault
- Deny public network access to Storage Accounts
- Deny public network access to Cosmos DB

**Implementation:**
- All KV, Storage, Cosmos DB must use **Private Endpoints** only
- Service Endpoints disabled (Private Endpoints preferred)
- Public network access: `Deny` on all data services

**Verification:**
```bash
# Check Key Vault settings
az keyvault show --resource-group rg-aue-qbot-ai-sovereign --name kv-aue-qbot-sov \
  --query "properties.publicNetworkAccess" # Should be "Disabled"
```

---

### 2. **Customer-Managed Keys** (`enforce_cmk = true`)

**Azure Policies Assigned:**
- Require customer-managed encryption keys on Storage Accounts

**Implementation:**
- All Storage Accounts use CMK from customer's Key Vault
- Cosmos DB: Double encryption (at-rest + in-transit)
- TLS 1.2+ enforced for all data in transit

**Verification:**
```bash
# Check Storage Account encryption
az storage account show --resource-group rg-aue-qbot-ai-sovereign \
  --name stqbotaisov --query "encryption.keySource" # Should be "Microsoft.Keyvault"
```

---

### 3. **Region Lock** (`enforce_region_lock = true`)

**Azure Policies Assigned:**
- Allowed Locations policy (restricts deployments to `allowed_regions`)

**Implementation:**
- Resources can only be deployed in approved regions (e.g., `["australiaeast"]`)
- Prevents accidental multi-region deployments
- Enforces data residency and regulatory jurisdiction

**Verification:**
```bash
# List Azure Policy assignments
az policy assignment list --scope /subscriptions/YOUR_SUB_ID \
  --query "[?displayName=='Allowed locations - Data residency enforcement']"
```

---

### 4. **Managed Identity-Only Auth** (`enforce_identity = true`)

**Azure Policies Assigned:**
- App Services require managed identity (system-assigned)

**Implementation:**
- All App Services have system-assigned managed identity
- No shared keys / connection strings allowed
- RBAC data-plane roles for service-to-service communication

**Verification:**
```bash
# Check App Service has managed identity
az webapp identity show --resource-group rg-aue-qbot-ai-sovereign \
  --name app-aue-qbot-web-sovereign # Should show "principalId"
```

---

## Example: Sovereign + Non-Regulated in Same Repo

```bash
# Deploy non-regulated dev environment
cd landing-zones/ai
terraform workspace new dev-nonreg
terraform apply -var-file="dev-aue.tfvars"

# Deploy sovereign prod environment
terraform workspace new prod-sovereign
terraform apply -var-file="sovereign-aue.tfvars"
```

**Result:** Two completely different deployments, one codebase, zero duplication.

---

## Extending the Pattern

To add new sovereignty controls (e.g., require service-to-service encryption):

1. **Add toggle to `sovereignty_profile` object**
   ```hcl
   variable "sovereignty_profile" {
     type = object({
       ...
       enforce_service_to_service_encryption = optional(bool, false)
     })
   }
   ```

2. **Create sub-module** (modules/sovereignty/service-mesh/)
   ```
   service-mesh/
   ├── main.tf       # Azure Policy for mTLS, service mesh enforcement
   └── variables.tf
   ```

3. **Wire into sovereignty/main.tf**
   ```hcl
   module "sovereignty_service_mesh" {
     count  = local.sovereignty_enabled && var.sovereignty_profile.enforce_service_to_service_encryption ? 1 : 0
     source = "./service-mesh"
     ...
   }
   ```

4. **Update sovereign-aue.tfvars**
   ```hcl
   sovereignty_profile = {
     ...
     enforce_service_to_service_encryption = true
   }
   ```

---

## Benefits

| Benefit | Value |
|---------|-------|
| **Single Codebase** | One repository for all customer types (regulated + non-regulated) |
| **Zero Duplication** | Feature flags + conditional modules eliminate code copying |
| **Compliance Speed** | Toggle sovereign controls instantly without re-architecture |
| **Auditability** | All policies tracked in source control; audit trail via Azure Policy |
| **Scalability** | Add new compliance dimensions (encrypt in-transit, data exfiltration controls, etc.) without core module changes |
| **Customer Value** | Enterprise customers get compliance-grade controls; SMBs get standard deployments — same codebase |

---

## References

- [Macquarie Cloud Services — Sovereign Landing Zone](https://www.macquariecloudservices.com/kb/article/sovereign-landing-zone/)
- [Azure Policy — Built-in Definitions](https://docs.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)
- [Well-Architected Framework — Security Pillar](https://docs.microsoft.com/en-us/azure/architecture/framework/security/)
