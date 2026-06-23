# qbot-ai-lz — AI Landing Zone (Hub-Spoke, Multi-Region)

Terraform codebase for QBot's Azure AI Landing Zone built with [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/).  
Follows the [Azure Landing Zone conceptual architecture](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/) with hub-spoke topology and multi-region support across **australiaeast** (primary) and **australiasoutheast** (secondary/DR).

All AI services are secured with private endpoints, centralised private DNS zones, NSG micro-segmentation, and Azure Policy guardrails.

> **Important:** Bing Search APIs are retired for new deployments (`ApiSetDisabledForCreation`). The code retains legacy Bing resource definitions for backward compatibility, but they should remain disabled in `feature_flags`.

---

## Architecture Overview

```
                     ┌──────────────────────────────────────────────┐
                     │            platform/management               │
                     │      Log Analytics + Application Insights    │
                     │      Azure Policy (governance guardrails)   │
                     └──────────────────────┬───────────────────────┘
                                            │ diagnostics
            ┌───────────────────────────────┼───────────────────────────────┐
            │                               │                               │
┌───────────▼─────────────────┐   ┌─────────▼──────────────────┐           │
│ platform/connectivity       │   │ platform/connectivity      │           │
│ Hub (australiaeast)         │   │ Hub (australiasoutheast)   │           │
│ 10.100.0.0/16               │   │ 10.101.0.0/16              │           │
│ · Bastion (optional)        │   │ · Bastion (optional)       │           │
│ · Firewall (optional)       │   │ · Firewall (optional)      │           │
│ · VPN Gateway (optional)    │   │ · VPN Gateway (optional)   │           │
│ · Central Private DNS zones │   │ · Central Private DNS zones│           │
└──────────────┬──────────────┘   └────────────┬───────────────┘           │
               │ hub<->spoke peering            │ hub<->spoke peering       │
      ┌────────┴─────────┐            ┌─────────┴────────┐                  │
      │ landing-zones/ai │            │ landing-zones/ai │                  │
      │ Dev AUE Spoke    │            │ Dev AUSE Spoke   │                  │
      │ 10.110.0.0/16    │            │ 10.111.0.0/16    │                  │
      │ · AI Foundry     │            │ · AI Foundry     │                  │
      │ · AI Search      │            │ · AI Search      │                  │
      │ · Data services  │            │ · Data services  │                  │
      │   (KV/Storage/DB)│            │   (KV/Storage/DB)│                  │
      │ · App Gateway    │            │ · App Gateway    │                  │
      │   (WAF_v2)       │            │   (WAF_v2)       │                  │
      │ · App services   │            │ · App services   │                  │
      │ · Function App   │            │ · Function App   │                  │
      │ · SignalR        │            │ · SignalR        │                  │
      │ · Speech/Doc/CV* │            │ · Speech/Doc/CV* │                  
      └──────────────────┘            └──────────────────┘
      ┌──────────────────┐            ┌──────────────────┐
      │ landing-zones/ai │            │ landing-zones/ai │
      │ Prod AUE Spoke   │            │ Prod AUSE Spoke  │
      │ 10.120.0.0/16    │            │ 10.121.0.0/16    │
      └──────────────────┘            └──────────────────┘

* Optional by feature flags. Legacy Bing resources exist in code but remain disabled for new deployments.
```

---

## Directory Structure

```
qbot-ai-lz/
├── modules/
│   ├── ai-networking/          # NSGs, AI spoke VNet, subnets, bi-directional hub peering
│   ├── ai-services/            # AI Foundry Hub+Project, AI Search, Speech, Doc Intel,
│   │                           #   Computer Vision, legacy Bing resource definitions
│   ├── data-services/          # CosmosDB (NoSQL), Storage Account + private endpoints
│   ├── app-gateway/            # Spoke ingress: WAF_v2, TLS termination, path-based routing
│   ├── app-services/           # App Service Plan, WebApp (Node.js), WebAPI (.NET),
│   │                           #   Memory Pipeline (.NET), Azure Function (.NET)
│   └── realtime-services/      # SignalR Service + private endpoint
│
├── platform/
│   ├── connectivity/           # Hub VNet, Bastion, Firewall, VPN GW, centralised DNS zones
│   │   ├── australiaeast.tfvars        # Primary hub
│   │   └── australiasoutheast.tfvars   # Secondary hub
│   │
│   ├── management/             # Log Analytics Workspace, Application Insights
│   │   └── management.tfvars
│   │
│   └── policy/                 # Azure Policy definitions and assignments
│       ├── hub.tfvars                  # Hub subscription
│       ├── spoke-nonprod.tfvars        # Spoke non-production subscription
│       └── spoke-prod.tfvars           # Spoke production subscription
│
└── landing-zones/
    └── ai/                     # AI workload spoke (peered to hub)
        ├── dev-aue.tfvars              # Dev, australiaeast
        ├── dev-ause.tfvars             # Dev, australiasoutheast
        ├── prod-aue.tfvars             # Prod, australiaeast
        └── prod-ause.tfvars            # Prod, australiasoutheast
```

---

## CIDR Allocation

| Layer                         | Range           | Notes                              |
|-------------------------------|-----------------|------------------------------------|
| Hub — australiaeast           | 10.100.0.0/16   | AzureFirewallSubnet /26            |
| Hub — australiasoutheast      | 10.101.0.0/16   | GatewaySubnet /27                  |
| AI Dev spoke — AUE            | 10.110.0.0/16   | 6 subnets carved from /16          |
| AI Dev spoke — AUSE           | 10.111.0.0/16   | DR mirror of dev-aue               |
| AI Prod spoke — AUE           | 10.120.0.0/16   | Production primary                 |
| AI Prod spoke — AUSE          | 10.121.0.0/16   | Production DR                      |

### Subnet Layout (per spoke)

The six default subnets are defined in each `.tfvars` file via the `subnets` map variable and can be extended with additional entries without any module changes:

| Map Key  | Default Name (Dev AUE)   | Prefix (Dev AUE)   | NSG Key | Purpose                                      |
|----------|--------------------------|--------------------|---------|----------------------------------------------|
| `app`    | `snet-aue-ai-app`        | 10.110.1.0/24      | `app`   | App Services VNet integration (delegated)    |
| `func`   | `snet-aue-ai-func`       | 10.110.2.0/24      | `func`  | Function App VNet integration (delegated)    |
| `data`   | `snet-aue-ai-data`       | 10.110.3.0/24      | `data`  | Data-tier (CosmosDB, Storage)                |
| `svc`    | `snet-aue-ai-svc`        | 10.110.4.0/24      | `pe`    | AI cognitive services traffic                |
| `agw`    | `snet-aue-ai-agw`        | 10.110.5.0/24      | `agw`   | Application Gateway (WAF_v2) dedicated subnet |
| `pe`     | `snet-aue-ai-pe`         | 10.110.10.0/23     | `pe`    | Private endpoints — all services             |
| `mgmt`   | `snet-aue-ai-mgmt`       | 10.110.20.0/24     | `mgmt`  | Jumpbox / management VMs                     |

To add a subnet, append an entry to the `subnets` map in the relevant `.tfvars` file:

```hcl
subnets = {
  # ... existing entries ...
  dmz = {
    name             = "snet-aue-ai-dmz"
    address_prefixes = ["10.110.30.0/24"]
    nsg_key          = "dmz"  # attach a custom NSG defined in network_security_groups
  }
}
```

The `nsg_key` field resolves to an NSG resource ID inside the module. It can reference any of the five built-in keys (`app`, `func`, `data`, `pe`, `mgmt`) or a custom key from `network_security_groups`. Set to `null` to attach no NSG. The subnet is accessible from any module output via `module.ai_networking.subnet_ids["dmz"]`.

### NSG Extensibility (hub and spoke)

Both the hub (`platform/connectivity`) and the spoke (`modules/ai-networking`) support user-defined NSGs via the `network_security_groups` variable. This lets you define additional NSGs — with any set of security rules — entirely in `.tfvars` files without modifying any module code.

**Built-in spoke NSGs** (always created by `modules/ai-networking`):  `app`, `func`, `data`, `pe`, `mgmt`

**Custom NSGs** are created via `network_security_groups` and are merged into the NSG lookup map, making them available as `nsg_key` targets for any subnet.

#### Spoke example (`landing-zones/ai/*.tfvars`)

```hcl
network_security_groups = {
  dmz = {
    name = "nsg-aue-ai-dmz-dev"
    security_rules = {
      allow_https_inbound = {
        name                       = "AllowHttpsInbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
    }
  }
}

subnets = {
  # ... existing entries ...
  dmz = {
    name             = "snet-aue-ai-dmz"
    address_prefixes = ["10.110.30.0/24"]
    nsg_key          = "dmz"   # ← references the custom NSG above
  }
}
```

#### Hub example (`platform/connectivity/*.tfvars`)

```hcl
network_security_groups = {
  mgmt = {
    name = "nsg-aue-hub-mgmt"
    security_rules = {
      allow_rdp_from_bastion = {
        name                       = "AllowRdpFromBastion"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "10.100.2.0/26"  # AzureBastionSubnet
        destination_address_prefix = "*"
      }
    }
  }
}

subnets = {
  # ... existing entries ...
  mgmt = {
    name             = "snet-aue-hub-mgmt"
    address_prefixes = ["10.100.10.0/24"]
    nsg_key          = "mgmt"   # ← references the custom hub NSG above
  }
}
```

> **Note:** For the spoke, reserved keys `app`, `func`, `data`, `pe`, `mgmt` must not be used in `network_security_groups` as they already map to built-in NSGs. Custom NSG IDs are also surfaced via the `nsg_ids` output on both hub and spoke for reference by downstream configurations.

---

## Private DNS Zones (centralised in hub)

| Service                        | Private DNS Zone                            |
|--------------------------------|---------------------------------------------|
| Key Vault                      | `privatelink.vaultcore.azure.net`           |
| Storage (Blob)                 | `privatelink.blob.core.windows.net`         |
| Storage (File)                 | `privatelink.file.core.windows.net`         |
| App Services / Function        | `privatelink.azurewebsites.net`             |
| Cosmos DB (NoSQL)              | `privatelink.documents.azure.com`           |
| AI Search                      | `privatelink.search.windows.net`            |
| Cognitive Services             | `privatelink.cognitiveservices.azure.com`   |
| Azure OpenAI (AI Foundry)      | `privatelink.openai.azure.com`              |
| AI Foundry / ML Workspace      | `privatelink.api.azureml.ms`               |
| AI Foundry Notebooks           | `privatelink.notebooks.azure.net`           |
| SignalR                        | `privatelink.service.signalr.net`           |
| Monitor / App Insights         | `privatelink.monitor.azure.com`             |
| OMS / Log Analytics Ingestion  | `privatelink.oms.opinsights.azure.com`      |
| ODS / Log Analytics Query      | `privatelink.ods.opinsights.azure.com`      |
| Automation Account             | `privatelink.agentsvc.azure-automation.net` |

---

## Deployment Order

The layers have explicit state dependencies. Always deploy in this order:

### 0. Bootstrap — tfstate storage (once, before anything else)

All layers share a single storage account for remote state. This must exist before any `terraform init` can succeed.

```bash
# Create the resource group that holds all tfstate storage accounts
az group create --name rg-tfstate-qbot --location australiaeast

# Create the storage account (name must be globally unique — change if taken)
az storage account create \
  --name qbottfstatenonprod \
  --resource-group rg-tfstate-qbot \
  --location australiaeast \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

# Create the two state containers
az storage container create --name tfstateqbotplatform \
  --account-name qbottfstatenonprod --auth-mode login
az storage container create --name tfstateqbotai \
  --account-name qbottfstatenonprod --auth-mode login
```

> **Cross-subscription note:** If the hub (platform/connectivity) is in a different subscription to the spokes (landing-zones/ai), create the storage account in whichever subscription hosts the hub — or use two separate storage accounts and update the backend configs. See [Subscription Variables](#subscription-variables) below.

### Subscription Variables

Before deploying, update the subscription IDs in every `.tfvars` file:

**`platform/connectivity/*.tfvars` and `platform/management/management.tfvars`:**
```hcl
subscription_id = "<hub-subscription-id>"
```

**`landing-zones/ai/*.tfvars`:** (two separate variables since hub and spoke can be different subscriptions)
```hcl
spoke_subscription_id = "<spoke-subscription-id>"
hub_subscription_id   = "<hub-subscription-id>"  # same as spoke if sharing one subscription
```

The `hub_subscription_id` is used by the `azurerm.hub` provider alias to create hub-side resources from the spoke (VNet peering, DNS zone links). Set it equal to `spoke_subscription_id` when hub and spoke share the same subscription.

### 1. Platform Management (once, global)
```bash
cd platform/management
terraform init -backend-config="key=qbot-platform-management.tfstate"
terraform plan -var-file="management.tfvars"
terraform apply -var-file="management.tfvars"
```

### 2. Azure Policy (once per subscription)

Policy assignments are scoped to a single subscription, so this must be run separately for each subscription in use. Each tfvars file targets one subscription via its `subscription_id` variable.

```bash
cd platform/policy

# Hub subscription (platform/connectivity + platform/management resources)
terraform init -backend-config="key=qbot-platform-policy-hub.tfstate"
terraform plan -var-file="hub.tfvars"
terraform apply -var-file="hub.tfvars"

# Spoke non-production subscription (dev/test landing zones)
terraform init -reconfigure -backend-config="key=qbot-platform-policy-spoke-nonprod.tfstate"
terraform plan -var-file="spoke-nonprod.tfvars"
terraform apply -var-file="spoke-nonprod.tfvars"

# Spoke production subscription
terraform init -reconfigure -backend-config="key=qbot-platform-policy-spoke-prod.tfstate"
terraform plan -var-file="spoke-prod.tfvars"
terraform apply -var-file="spoke-prod.tfvars"
```

> **Single subscription:** If hub and all spokes share one subscription, only run the `hub.tfvars` deploy — it will cover everything.

### 3. Platform Connectivity (once per region)
```bash
cd platform/connectivity

# Primary region
terraform init -reconfigure -backend-config="key=qbot-platform-connectivity-aue.tfstate"
terraform plan -var-file="australiaeast.tfvars"
terraform apply -var-file="australiaeast.tfvars"

# Secondary region
terraform init -reconfigure -backend-config="key=qbot-platform-connectivity-ause.tfstate"
terraform plan -var-file="australiasoutheast.tfvars"
terraform apply -var-file="australiasoutheast.tfvars"
```

### 4. AI Landing Zone (per environment per region)
```bash
cd landing-zones/ai

# Dev — Primary
terraform init -backend-config="key=lz-ai-dev-aue.tfstate"
terraform plan -var-file="dev-aue.tfvars"
terraform apply -var-file="dev-aue.tfvars"

# Dev — Secondary (DR)
terraform init -reconfigure -backend-config="key=lz-ai-dev-ause.tfstate"
terraform plan -var-file="dev-ause.tfvars"
terraform apply -var-file="dev-ause.tfvars"

# Prod — Primary
terraform init -reconfigure -backend-config="key=lz-ai-prod-aue.tfstate"
terraform plan -var-file="prod-aue.tfvars"
terraform apply -var-file="prod-aue.tfvars"

# Prod — Secondary (DR)
terraform init -reconfigure -backend-config="key=lz-ai-prod-ause.tfstate"
terraform plan -var-file="prod-ause.tfvars"
terraform apply -var-file="prod-ause.tfvars"
```

> **Two-phase apply for landing zones:** On first apply the App Services managed identity does not exist yet, so RBAC assignments that reference it will fail. Keep `app_service_principal_id = ""` for the first apply, then set it to the Web App managed identity principal/object ID and apply again.

Example to fetch the principal ID after first apply:

```bash
az webapp identity show \
  --name app-aue-qbot-webapp-dev \
  --resource-group rg-aue-qbot-ai-dev \
  --query principalId -o tsv
```

---

## Required RBAC Permissions

When hub and spoke share a subscription, assign all roles to the same Terraform identity. When they are in separate subscriptions, the spoke Terraform identity needs roles in **both** subscriptions as shown below.

| Principal (Terraform identity)         | Scope                                    | Role                                    | Purpose                                              |
|----------------------------------------|------------------------------------------|-----------------------------------------|------------------------------------------------------|
| Spoke Terraform SP / MI                | Spoke subscription                       | Contributor                             | Create all spoke resources                           |
| Spoke Terraform SP / MI                | Hub VNet resource group                  | Network Contributor                     | Create hub→spoke VNet peering                        |
| Spoke Terraform SP / MI                | Hub DNS zones resource group             | Private DNS Zone Contributor            | Create spoke VNet links to hub private DNS zones     |
| Spoke Terraform SP / MI                | Hub tfstate storage account              | Storage Blob Data Reader                | Read hub connectivity remote state (cross-sub)       |
| Spoke Terraform SP / MI                | Spoke tfstate storage account            | Storage Blob Data Owner                 | Read/write spoke remote state                        |
| Hub Terraform SP / MI                  | Hub subscription                         | Contributor                             | Create all hub resources                             |
| Hub Terraform SP / MI                  | Hub tfstate storage account              | Storage Blob Data Owner                 | Read/write hub remote state                          |
| Spoke Terraform SP / MI                | Spoke subscription                       | Cognitive Services Contributor          | Create Cognitive Services accounts                   |
| Spoke Terraform SP / MI                | Spoke subscription                       | Key Vault Administrator                 | Manage Key Vault RBAC assignments                    |
| Managed Identity (App Services)        | Key Vault                                | Key Vault Secrets User                  | Read secrets at runtime                              |
| Managed Identity (App Services)        | AI Services                              | Cognitive Services User                 | Call AI APIs at runtime                              |
| Managed Identity (App Services)        | AI Search                                | Search Index Data Reader                | Query AI Search indexes                              |
| Managed Identity (App Services)        | CosmosDB                                 | Cosmos DB Built-in Data Contributor     | Read/write data at runtime                           |
| Managed Identity (App Services)        | Storage Account                          | Storage Blob Data Contributor           | Read/write blobs at runtime                          |

---

## AVM Modules Used

| Resource                     | Module                                                        | Version  |
|------------------------------|---------------------------------------------------------------|----------|
| Resource Group               | `Azure/avm-res-resources-resourcegroup/azurerm`               | ~> 0.2   |
| NSG                          | `Azure/avm-res-network-networksecuritygroup/azurerm`          | ~> 0.2   |
| Virtual Network              | `Azure/avm-res-network-virtualnetwork/azurerm`                | ~> 0.7   |
| Bastion                      | `Azure/avm-res-network-bastionhost/azurerm`                   | ~> 0.3   |
| Public IP                    | `Azure/avm-res-network-publicipaddress/azurerm`               | ~> 0.1   |
| Azure Firewall               | `Azure/avm-res-network-azurefirewall/azurerm`                 | ~> 0.3   |
| Firewall Policy              | `Azure/avm-res-network-firewallpolicy/azurerm`                | ~> 0.3   |
| VPN Gateway                  | `Azure/avm-res-network-virtualnetworkgateway/azurerm`         | ~> 0.3   |
| Private DNS Zone             | `Azure/avm-res-network-privatednszone/azurerm`                | ~> 0.3   |
| Log Analytics Workspace      | `Azure/avm-res-operationalinsights-workspace/azurerm`         | ~> 0.4   |
| Application Insights         | `Azure/avm-res-insights-component/azurerm`                    | ~> 0.4   |
| Key Vault                    | `Azure/avm-res-keyvault-vault/azurerm`                        | ~> 0.9   |
| Storage Account              | `Azure/avm-res-storage-storageaccount/azurerm`                | ~> 0.4   |
| Cosmos DB                    | `Azure/avm-res-documentdb-databaseaccount/azurerm`            | ~> 0.4   |
| AI Search                    | `Azure/avm-res-search-searchservice/azurerm`                  | ~> 0.1   |
| AI Foundry (ML Workspace)    | `Azure/avm-res-machinelearningservices-workspace/azurerm`     | ~> 0.1   |
| Cognitive Services (multi)   | `Azure/avm-res-cognitiveservices-account/azurerm`             | ~> 0.6   |
| Application Gateway          | native `azurerm_application_gateway`                           | n/a      |
| WAF Policy                   | native `azurerm_web_application_firewall_policy`               | n/a      |
| App Service Plan             | `Azure/avm-res-web-serverfarm/azurerm`                        | ~> 0.3   |
| App Service (Web/API)        | `Azure/avm-res-web-site/azurerm`                              | ~> 0.12  |
| SignalR Service              | native `azurerm_signalr_service` + `azurerm_private_endpoint` | n/a      |
| Bing Search / Custom Search  | `azapi_resource` (Microsoft.Bing/accounts, legacy/retired)    | azapi ~> 2.0 |

## Feature Flags

Feature flags are exposed via the `feature_flags` object in `landing-zones/ai/variables.tf`. Each field is optional and defaults are defined in code (not all are `true`). Flags are wired through `landing-zones/ai/variables.tf` → `landing-zones/ai/main.tf` → child modules.

### platform/connectivity

| Variable             | Default | Description                                                    |
|----------------------|---------|----------------------------------------------------------------|
| `enable_bastion`     | `true`  | Deploy Azure Bastion in the hub VNet                           |
| `enable_firewall`    | `false` | Deploy Azure Firewall (significant cost — disable in dev/test) |
| `enable_vpn_gateway` | `false` | Deploy VPN Gateway for on-premises connectivity                |

### platform/connectivity — Hub VNet subnets

The `subnets` map variable (replacing individual `subnet_*_prefix` variables) controls which subnets exist in the hub VNet. Add extra entries to the `subnets` map in `australiaeast.tfvars` / `australiasoutheast.tfvars` to provision additional hub subnets without any module changes.

### landing-zones/ai — ai-networking module

| Variable                   | Default | Description                                                                                                           |
|----------------------------|---------|-----------------------------------------------------------------------------------------------------------------------|
| `enable_hub_peering`       | `true`  | Create hub↔spoke VNet peering (both directions) and DNS zone links. Set `false` for isolated/sandbox environments.    |
| `network_security_groups`  | `{}`    | Map of custom NSGs (key → name + security_rules). Keys must match `nsg_key` values in `subnets`. Reserved keys `app`, `func`, `data`, `pe`, `mgmt` must not be used here. |

### landing-zones/ai — ai-services module

| Variable                      | Default | Description                                              |
|-------------------------------|---------|----------------------------------------------------------|
| `enable_ai_foundry`           | `false` | AI Foundry Hub + Project (incl. dedicated KV & Storage)  |
| `enable_ai_search`            | `false` | Azure AI Search service                                  |
| `enable_speech`               | `false` | Azure AI Speech Service                                  |
| `enable_document_intelligence`| `false` | Document Intelligence (Form Recognizer)                  |
| `enable_computer_vision`      | `false` | Computer Vision / Image Analysis                         |
| `enable_bing_search`          | `false` | Legacy Bing Search (Grounding); retired for new deployments |
| `enable_bing_custom_search`   | `false` | Legacy Bing Custom Search; retired for new deployments   |

### landing-zones/ai — data-services module

| Variable                | Default | Description                                         |
|-------------------------|---------|-----------------------------------------------------|
| `enable_key_vault`      | `true`  | Deploy the Key Vault instance                       |
| `enable_storage_account`| `true`  | Deploy the shared Storage Account                   |
| `enable_cosmosdb`       | `false` | Deploy Cosmos DB account, database, and containers  |

### landing-zones/ai — app-services module

| Variable                | Default | Description                                                     |
|-------------------------|---------|-----------------------------------------------------------------|
| `enable_webapp_nodejs`  | `true`  | Node.js WebApp (chat frontend / orchestration)                  |
| `enable_webapi_dotnet`  | `true`  | .NET WebAPI (REST backend)                                      |
| `enable_memory_pipeline`| `false` | .NET Memory Pipeline background service                         |
| `enable_function_app`   | `false` | .NET Function App + its dedicated storage account               |

### landing-zones/ai — realtime-services module

| Variable         | Default | Description                         |
|------------------|---------|-------------------------------------|
| `enable_signalr` | `false` | Deploy the Azure SignalR Service     |
| `store_signalr_secret_in_key_vault` | `true` | Write SignalR connection string to Key Vault; set `false` when Terraform cannot reach the vault data plane (private-only vault from non-private runner) |

### landing-zones/ai — app-gateway module

| Variable / Flag | Default | Description |
|-----------------|---------|-------------|
| `enable_app_gateway` | `false` | Deploy spoke-level Application Gateway (WAF_v2) as HTTPS entry point |
| `agw_waf_mode` | `Detection` | WAF mode (`Detection` for dev rollout, `Prevention` for prod) |
| `agw_ssl_cert_key_vault_secret_id` | `""` | Key Vault TLS certificate secret URI for HTTPS listener |
| `agw_capacity` / `agw_autoscale_*` | `1` / `null` | Fixed capacity for dev or autoscale for production |

### Example: environment-specific overrides

```hcl
# prod-aue.tfvars — disable services not needed in production
feature_flags = {
  enable_bing_search        = false  # retired + not approved for prod data
  enable_bing_custom_search = false  # retired
  enable_memory_pipeline    = false  # handled by an external pipeline
}
```

```hcl
# dev-aue.tfvars — private-only Key Vault with non-private Terraform runner
feature_flags = {
  enable_ai_foundry                  = true
  enable_hub_peering                 = true
  enable_cosmosdb                    = true
  enable_signalr                     = true
  store_signalr_secret_in_key_vault = false
}
```

Outputs from disabled services return `null` and downstream `app_settings` entries that reference them (e.g. `AI_SEARCH_ENDPOINT`) are set to an empty string, keeping the app configuration valid.

---



| Decision                        | Choice                                                   | Rationale                                                              |
|---------------------------------|----------------------------------------------------------|------------------------------------------------------------------------|
| State isolation                 | Separate state per layer per region                      | Reduces blast radius; independent lifecycle per team                   |
| Cross-stack references          | `terraform_remote_state` data source                     | Type-safe; no manual ID copy-paste                                     |
| Hub peering                     | Both directions created from landing zone                | Single-team deployment; requires Network Contributor on hub RG         |
| Private DNS Zones               | Centralised in hub connectivity layer, 15 zones          | Single management point; auto-resolves from all spokes                 |
| Private Endpoints               | All AI/data services use private endpoints only          | Zero public internet exposure for sensitive AI workloads               |
| AI Foundry                      | Hub + Project pattern (azurerm_ai_foundry)               | Supports project isolation, shared compute, and managed identities     |
| Cognitive Services              | Separate accounts per service kind                       | Least privilege; independent cost tracking; separate PE per service    |
| Bing Resources                  | azapi_resource (Microsoft.Bing/accounts)                 | Not yet in hashicorp/azurerm; azapi provides full ARM API access       |
| App Service auth                | System-assigned managed identity + RBAC                  | No secrets in app config; identity-based access to all Azure services  |
| CosmosDB                        | NoSQL API (SQL), RBAC data plane, no connection strings  | Modern auth; granular data-plane roles; cross-region consistency       |
| Key Vault                       | RBAC mode (not Access Policies), purge protection on     | Consistent Azure RBAC model; no accidental key deletion                |
| Azure Policy                    | Deny public endpoints, require HTTPS, require tags       | Proactive governance; prevents accidental exposure of AI models/data   |
| Multi-region                    | Separate tfvars per region; same config code             | Reuses all modules; region-specific tfvars handle naming/CIDR          |
| Optional hub services           | `enable_firewall`, `enable_bastion`, `enable_vpn_gateway`| Cost control in dev/test; enable selectively in prod                   |
| Optional spoke services         | `enable_*` flags on every module service                 | Per-environment cost control; enable only what each env needs          |
| Spoke ingress                   | Application Gateway (WAF_v2) in each spoke               | Security isolation and independent WAF policy tuning per workload       |
| Hub VNet subnets                | `subnets` map variable (replacing individual prefix vars)| Add/remove subnets per env without module changes; same pattern as spoke|
| Spoke VNet subnets              | `subnets` map variable with `nsg_key` field              | Extendable without module changes; NSG resolved from key inside module |
| NSG extensibility (hub & spoke) | `network_security_groups` map + `nsg_key` on subnets     | Define any number of custom NSGs in tfvars; merged with built-in NSGs at plan time |

---

## Security Controls

### Network Security
- All AI services exposed only via private endpoints — no public network access
- Application Gateway (WAF_v2) is implemented in each spoke as the HTTPS ingress tier with path-based routing to app services
- WAF policy enforces OWASP managed rules and bot protection for north-south traffic before it reaches backend services
- NSG micro-segmentation on every subnet with explicit deny-all as default
- Azure Firewall (optional, recommended for prod) for east-west inspection
- Service endpoints disabled in favour of private endpoints (more secure)

### Identity & Access
- All App Services / Functions use system-assigned managed identities
- RBAC data-plane roles for Cosmos DB, Key Vault, Storage, AI Search, Cognitive Services
- No connection strings or API keys stored in app configuration
- Key Vault stores only secrets needed at bootstrap (e.g., Cosmos DB primary key for seed scripts)

### Data Protection
- Storage Account: HTTPS-only, TLS 1.2 minimum, public access disabled
- Cosmos DB: IP firewall deny-all + private endpoint only
- Key Vault: purge protection enabled, soft-delete retention 90 days
- AI Foundry / Cognitive Services: outbound internet disabled where supported

### Azure Policy (platform/policy layer)
- `Deny` — Public network access on Key Vault
- `Deny` — Public network access on Cognitive Services
- `Deny` — Public network access on AI Search
- `Deny` — Public network access on Cosmos DB
- `Deny` — Public network access on Storage Accounts
- `Audit` — App Services must use managed identity
- `Audit` — App Services must use HTTPS only
- `DeployIfNotExists` — Diagnostic settings to Log Analytics on all AI services
- `Require` — Tag enforcement (Environment, CostCenter, TechOwner)

---

## Sovereignty Controls

The landing zone supports a **regulated/sovereign deployment mode** activated via the `sovereignty_profile` variable. It is entirely additive — the same codebase serves both standard and regulated customers through a single feature-flag object.

### How It Works

```
sovereignty_profile = { enabled, enforce_private_only, enforce_cmk, enforce_region_lock, enforce_identity }
        ↓
module "sovereignty" { count = sovereignty_profile.enabled ? 1 : 0 }
        ↓
    ├── module "sovereignty_policies"        (always, when sovereignty enabled)
    │       ├── Deny-Public-KV Policy        (enforce_private_only = true)
    │       ├── Deny-Public-Storage Policy   (enforce_private_only = true)
    │       ├── Allowed-Regions Policy       (enforce_region_lock = true)
    │       └── Require-ManagedIdentity      (enforce_identity = true)
    │
    ├── module "sovereignty_network"         (enforce_private_only = true)
    │       └── NSG micro-segmentation + private endpoint enforcement
    │
    ├── module "sovereignty_encryption"      (enforce_cmk = true)
    │       └── CMK validation, key rotation policy, double encryption
    │
    └── module "sovereignty_identity"        (enforce_identity = true)
                └── Managed identity enforcement, RBAC audit
```

Each sub-module instantiates only if its specific toggle is `true`. Disabling a control does not affect other controls.

### Sovereignty Profile Variable

```hcl
sovereignty_profile = {
  enabled              = true   # Master switch — false disables the entire module
  enforce_private_only = true   # Deny public endpoints via Azure Policy; NSG micro-segmentation
  enforce_cmk          = true   # Require customer-managed keys; deny service-managed encryption
  enforce_region_lock  = true   # Restrict deployments to allowed_regions only
  enforce_identity     = true   # Require managed identity authentication; deny shared keys
}
```

| Toggle                | Controls Activated                                                                |
|-----------------------|-----------------------------------------------------------------------------------|
| `enforce_private_only`| Policy: deny public KV, deny public storage, deny public Cosmos DB; network NSG rules |
| `enforce_cmk`         | Policy: require CMK on storage and Cosmos DB; encryption module with key rotation  |
| `enforce_region_lock` | Policy: `Deny` on deployments outside `allowed_regions`                            |
| `enforce_identity`    | Policy: require managed identity; identity module with RBAC audit                  |

### Supporting Variables

```hcl
# Management Group scope for Policy assignments
management_group_id = "/subscriptions/<id>"

# Key Vault resource ID containing the customer-managed encryption key
cmk_key_vault_id = "/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<name>"

# Data residency — list of permitted Azure regions
allowed_regions = ["australiaeast"]
```

### Deploying a Sovereign Environment

**Step 1 — Prerequisites**

```bash
# Create premium Key Vault with purge protection (required before first apply)
az keyvault create \
  --resource-group rg-aue-qbot-ai-sovereign \
  --name kv-aue-qbot-sov \
  --sku premium \
  --enable-purge-protection true

# Create the CMK
az keyvault key create \
  --vault-name kv-aue-qbot-sov \
  --name encryption-key \
  --kty RSA \
  --size 2048
```

**Step 2 — Deploy**

```bash
cd landing-zones/ai
terraform init -backend-config="key=lz-ai-sovereign-aue.tfstate"
terraform plan  -var-file="sovereign-aue.tfvars"
terraform apply -var-file="sovereign-aue.tfvars"
```

**Step 3 — Verify**

```bash
# Overall compliance posture
terraform output sovereignty_status

# Policy assignment status per control
terraform output policies_assigned

# Check Azure Policy compliance
az policy state summarize \
  --resource-group rg-aue-qbot-ai-sovereign \
  --query "results.policyAssignments[].{policy:policyAssignmentId,compliant:results.nonCompliantResources}"
```

### Sovereign vs Standard Comparison

| Capability                       | Standard (`dev-aue.tfvars`)        | Sovereign (`sovereign-aue.tfvars`)          |
|----------------------------------|------------------------------------|---------------------------------------------|
| Public endpoints                 | Allowed (configurable)             | Denied via Azure Policy                     |
| Encryption                       | Service-managed keys               | Customer-managed keys (CMK), double encryption |
| Deployment regions               | Any region                         | Locked to `allowed_regions`                 |
| Authentication                   | Keys or managed identity           | Managed identity only (shared keys denied)  |
| Cosmos DB consistency            | Session                            | BoundedStaleness (higher consistency)       |
| Storage replication              | ZRS                                | GRS (geo-redundant)                         |
| Key Vault SKU                    | Standard                           | Premium (HSM-backed, required for PE)       |
| App Gateway WAF mode             | Detection                          | Prevention                                  |
| Azure Policy assignments         | Audit only                         | Deny + audit via sovereignty module         |

### Extending Sovereignty Controls

New controls can be added to `modules/sovereignty/` without touching any landing zone or core module code:

1. Add a new toggle to the `sovereignty_profile` object in `variables.tf`
2. Create a sub-module under `modules/sovereignty/<control-name>/`
3. Wire it with `count = var.sovereignty_profile.<new_toggle> ? 1 : 0` in `modules/sovereignty/main.tf`
4. Expose status via `modules/sovereignty/outputs.tf`

### Troubleshooting

**`Insufficient Permissions` on policy assignment**

The Terraform identity needs `Microsoft.Authorization/policyAssignments/write` at Management Group or subscription scope:
```bash
az role assignment create \
  --assignee <terraform-sp-or-mi-object-id> \
  --role "Policy Contributor" \
  --scope /subscriptions/<spoke-subscription-id>
```

**`Forbidden: Public Network Access Disabled` on CMK Key Vault**

The CMK Key Vault blocks Terraform data-plane access when `enforce_private_only = true` and the runner is not on the private network. Temporarily re-enable public access for the apply, then disable it afterwards:
```bash
az keyvault update --name kv-aue-qbot-sov --public-network-access Enabled
terraform apply -var-file="sovereign-aue.tfvars"
az keyvault update --name kv-aue-qbot-sov --public-network-access Disabled
```

**`store_signalr_secret_in_key_vault` fails from non-private runner**

Set `store_signalr_secret_in_key_vault = false` in `sovereign-aue.tfvars` when the Terraform runner cannot reach the Key Vault data plane. The SignalR connection string will not be written to Key Vault automatically; inject it via a separate secrets pipeline after apply.

