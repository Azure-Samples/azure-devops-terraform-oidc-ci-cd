locals {
  user_assigned_managed_identity_environments = local.security_option.self_hosted_agents_with_managed_identity || local.security_option.oidc_with_user_assigned_managed_identity ? { for env in var.environments : env => env } : {}
}

resource "azurerm_user_assigned_identity" "example" {
  for_each            = local.user_assigned_managed_identity_environments
  location            = var.location
  name                = "${var.prefix}-${each.value}"
  resource_group_name = azurerm_resource_group.identity.name
}

resource "azurerm_federated_identity_credential" "example" {
  for_each            = local.security_option.oidc_with_user_assigned_managed_identity ? local.user_assigned_managed_identity_environments : {}
  name                = "${var.azure_devops_organisation_target}-${var.azure_devops_project_target}-${each.value}"
  resource_group_name = azurerm_resource_group.identity.name
  audience            = [local.default_audience_name]
  issuer              = local.github_issuer_url
  parent_id           = azurerm_user_assigned_identity.example[each.value].id
  subject             = "sc://${var.azure_devops_organisation_target}/${var.azure_devops_project_target}/service_connection_${each.value}"
}