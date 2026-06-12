output "signalr_id" {
  description = "Resource ID of the Azure SignalR Service. Null when enable_signalr = false."
  value       = var.enable_signalr ? module.signalr[0].resource_id : null
}

output "signalr_hostname" {
  description = "Hostname of the Azure SignalR Service. Null when enable_signalr = false."
  value       = var.enable_signalr ? module.signalr[0].hostname : null
}

output "signalr_primary_connection_string" {
  description = "Primary connection string for the Azure SignalR Service. Null when enable_signalr = false."
  value       = var.enable_signalr ? module.signalr[0].primary_connection_string : null
  sensitive   = true
}

output "signalr_principal_id" {
  description = "System-assigned managed identity principal ID of SignalR. Null when enable_signalr = false."
  value       = var.enable_signalr ? module.signalr[0].identity[0].principal_id : null
}
