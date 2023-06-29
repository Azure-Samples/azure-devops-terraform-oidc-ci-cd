resource "azurerm_user_assigned_identity" "example" {
  for_each            = var.use_managed_identity ? { for env in var.environments : env => env } : {}
  location            = var.location
  name                = "${var.prefix}-${each.value}"
  resource_group_name = azurerm_resource_group.identity.name
}

resource "azurerm_federated_identity_credential" "example" {
  for_each            = var.use_managed_identity ? { for env in var.environments : env => env } : {}
  name                = "${var.azure_devops_organisation_target}-${var.azure_devops_project_target}-${each.value}"
  resource_group_name = azurerm_resource_group.identity.name
  audience            = [local.default_audience_name]
  issuer              = local.github_issuer_url
  parent_id           = azurerm_user_assigned_identity.example[each.value].id
  subject             = "sc://${var.azure_devops_organisation_target}/${var.azure_devops_project_target}/service_connection_${each.value}"
}