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
  value = local.security_option.oidc_with_app_registration ? { for env in var.environments : env => azuread_application.github_oidc[env].client_id } : { for env in var.environments : env => azurerm_user_assigned_identity.example[env].client_id }
}