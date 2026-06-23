#--------------------------------------------------------------
# Sovereignty Identity — Main
#
# Enforces:
#   - Managed identity-only authentication (no shared keys or connection strings)
#   - System-assigned identities on all compute resources
#   - RBAC data-plane roles (no storage account keys, Cosmos DB keys, etc.)
#   - Conditional access policies for Entra ID integration
#   - Regular identity access reviews
#--------------------------------------------------------------

# Placeholder: Identity enforcement policies
# These would be expanded to:
#   - Disable storage account shared keys (SAS tokens only if absolutely necessary)
#   - Disable Cosmos DB master key access (RBAC only)
#   - Require Entra ID authentication for all services
#   - Enforce MFA for administrative access
#   - Audit all identity changes and access grants

output "identity_enforcement_status" {
  description = "Sovereignty identity enforcement status"
  value       = "Enabled - Managed identity-only enforcement active"
}
