#--------------------------------------------------------------
# Sovereignty Encryption — Main
#
# Enforces:
#   - Customer-managed keys (CMK) for Storage Account encryption
#   - CMK for Cosmos DB encryption
#   - CMK for AI Foundry storage
#   - Double encryption at rest where supported
#   - TLS 1.2+ for all data in transit
#--------------------------------------------------------------

# Placeholder: CMK enforcement policies
# These would be expanded to:
#   - Validate CMK key rotation policies (90+ day minimum)
#   - Enable double encryption on Storage Accounts
#   - Enforce TLS 1.2 minimum on all services
#   - Audit logging of encryption key usage

output "encryption_enforcement_status" {
  description = "Sovereignty encryption enforcement status"
  value       = "Placeholder - CMK enforcement not yet implemented"
#  value       = "Enabled - CMK enforcement active on ${var.cmk_key_vault_id}"
}
