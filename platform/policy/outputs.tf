output "policy_initiative_id" {
  description = "Resource ID of the QBot AI Security Baseline policy initiative"
  value       = azurerm_policy_set_definition.qbot_ai_security_baseline.id
}

output "policy_assignment_id" {
  description = "Resource ID of the subscription-level policy assignment"
  value       = azurerm_subscription_policy_assignment.qbot_ai_security_baseline.id
}
