output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "subscription_name" {
  value = data.azurerm_subscription.current.display_name
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "service_principal_client_ids" {
  value = { for env_key, env_value in local.environment_split : env_key => module.user_assigned_managed_identity[env_key].client_id }
}
