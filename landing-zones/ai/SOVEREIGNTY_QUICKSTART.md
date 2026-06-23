#--------------------------------------------------------------
# Quick Start — Sovereignty Landing Zone
#--------------------------------------------------------------

## Deploy Non-Regulated (Standard)

```bash
cd landing-zones/ai
terraform init
terraform plan -var-file="dev-aue.tfvars"
terraform apply -var-file="dev-aue.tfvars"
```

**Result:** Standard deployment, public endpoints allowed, service-managed encryption.

---

## Deploy Regulated (Sovereign)

### Step 1: Prepare CMK Key Vault

```bash
# Create premium Key Vault with purge protection
az keyvault create \
  --resource-group rg-aue-qbot-ai-sovereign \
  --name kv-aue-qbot-sov \
  --sku premium \
  --enable-purge-protection true

# Create CMK for encryption
az keyvault key create \
  --vault-name kv-aue-qbot-sov \
  --name encryption-key \
  --kty RSA \
  --size 2048

# Store the Key Vault ID
export CMK_KV_ID=$(az keyvault show --name kv-aue-qbot-sov \
  --query id --output tsv)
echo "CMK_KV_ID=$CMK_KV_ID"
```

### Step 2: Update sovereign-aue.tfvars

```hcl
sovereignty_profile = {
  enabled              = true
  enforce_private_only = true
  enforce_cmk          = true
  enforce_region_lock  = true
  enforce_identity     = true
}

management_group_id  = "/subscriptions/42851abe-8e57-4fec-9cf0-6c5afbb1b167"
cmk_key_vault_id     = "/subscriptions/42851abe-8e57-4fec-9cf0-6c5afbb1b167/resourceGroups/rg-aue-qbot-ai-sovereign/providers/Microsoft.KeyVault/vaults/kv-aue-qbot-sov"
allowed_regions      = ["australiaeast"]
```

### Step 3: Deploy

```bash
cd landing-zones/ai
terraform plan -var-file="sovereign-aue.tfvars"
terraform apply -var-file="sovereign-aue.tfvars"
```

### Step 4: Verify Compliance

```bash
# Check sovereignty status
terraform output sovereignty_status

# Verify policies assigned
terraform output sovereignty_policies

# Check Policy Compliance
az policy compliance list --query "[?resourceName=='rg-aue-qbot-ai-sovereign']"
```

**Result:**
- ✓ Private Endpoints required for KV, Storage, Cosmos DB
- ✓ CMK enforced (service-managed encryption denied)
- ✓ Region-locked to australiaeast
- ✓ Managed identity-only authentication

---

## Toggle Individual Controls

If you don't want all controls, customize the profile:

```hcl
# Example: Only enforce private-only access
sovereignty_profile = {
  enabled              = true
  enforce_private_only = true   # ← Enable this
  enforce_cmk          = false  # ← Disable
  enforce_region_lock  = false  # ← Disable
  enforce_identity     = false  # ← Disable
}
```

Each sub-module (policies, network, encryption, identity) will only instantiate if its specific toggle is true.

---

## Troubleshooting

### Policy Assignment Fails — "Insufficient Permissions"

**Cause:** User doesn't have `Microsoft.Authorization/policyAssignments/write` at Management Group scope.

**Fix:**
```bash
# Assign Policy Contributor role at MG/Subscription level
az role assignment create \
  --assignee $USER_ID \
  --role "Policy Contributor" \
  --scope /subscriptions/YOUR_SUB_ID
```

### CMK Key Vault Error — "Forbidden: Public Network Access Disabled"

**Cause:** CMK Key Vault uses private-endpoint-only access; policies can't write to it.

**Workaround:**
```bash
# Temporarily enable public access
az keyvault update --name kv-aue-qbot-sov \
  --public-network-access Enabled

# Run terraform apply
terraform apply -var-file="sovereign-aue.tfvars"

# Disable public access
az keyvault update --name kv-aue-qbot-sov \
  --public-network-access Disabled
```

---

## Architecture Diagram

```
Subscriber Input (Terraform Variables)
        ↓
sovereignty_profile = { enabled, enforce_private_only, enforce_cmk, enforce_region_lock, enforce_identity }
        ↓
module "sovereignty" { count = sovereignty_profile.enabled ? 1 : 0 }
        ↓
    ├── module "sovereignty_policies"        (if enabled)
    │       ├── Deny-Public-KV Policy       (if enforce_private_only)
    │       ├── Deny-Public-Storage Policy  (if enforce_private_only)
    │       ├── Allowed-Regions Policy      (if enforce_region_lock)
    │       └── Require-ManagedIdentity     (if enforce_identity)
    │
    ├── module "sovereignty_network"        (if enforce_private_only)
    │       └── NSG micro-segmentation, private endpoint enforcement
    │
    ├── module "sovereignty_encryption"     (if enforce_cmk)
    │       └── CMK validation, key rotation, double encryption
    │
    └── module "sovereignty_identity"       (if enforce_identity)
            └── Managed identity enforcement, RBAC audit
```

---

## Files Created/Modified

**Created:**
- ✓ `/modules/sovereignty/` — Full module with policies, network, encryption, identity sub-modules
- ✓ `/landing-zones/ai/sovereign-aue.tfvars` — Example sovereign deployment
- ✓ `/docs/SOVEREIGNTY_PATTERN.md` — Comprehensive documentation

**Modified:**
- ✓ `/landing-zones/ai/variables.tf` — Added `sovereignty_profile` object + management_group_id, cmk_key_vault_id, allowed_regions
- ✓ `/landing-zones/ai/main.tf` — Added sovereignty module call with count conditional
- ✓ `/landing-zones/ai/outputs.tf` — Added sovereignty_status outputs
- ✓ `/landing-zones/ai/dev-aue.tfvars` — Added sovereignty_profile (disabled by default)
- ✓ `/landing-zones/ai/prod-aue.tfvars` — Added sovereignty_profile (disabled by default)
- ✓ `/landing-zones/ai/dev-ause.tfvars` — Added sovereignty_profile (disabled by default)
- ✓ `/landing-zones/ai/prod-ause.tfvars` — Added sovereignty_profile (disabled by default)

---

## Next Steps

1. **Test sovereign deployment** (once CMK Key Vault is set up)
   ```bash
   terraform plan -var-file="sovereign-aue.tfvars"
   ```

2. **Verify policy assignments**
   ```bash
   terraform output sovereignty_policies
   ```

3. **Extend pattern** — Add new controls (e.g., service-to-service encryption, data exfiltration prevention) to `/modules/sovereignty/`

4. **Customer deployment** — Copy `sovereign-aue.tfvars`, customize for customer region/compliance requirements

---

## Key Advantages

✓ **Single Codebase** — One repository for all customer types  
✓ **Zero Duplication** — Feature flags eliminate code copying  
✓ **Compliance Speed** — Toggle controls instantly  
✓ **Auditability** — All policies in source control  
✓ **Extensibility** — Add new controls without touching core modules  

---

## References

- [Full Documentation](./docs/SOVEREIGNTY_PATTERN.md)
- [Module: /modules/sovereignty](../../modules/sovereignty)
- [Macquarie Cloud Services — Sovereign Landing Zone](https://www.macquariecloudservices.com/kb/article/sovereign-landing-zone/)
