resource "azurerm_user_assigned_identity" "example" {
  for_each            = var.use_managed_identity ? { for env in var.environments : env => env } : {}
  location            = var.location
  name                = "${var.prefix}-${each.value}"
  resource_group_name = azurerm_resource_group.identity.name
}

resource "azurerm_federated_identity_credential" "example" {
  for_each            = var.use_managed_identity ? { for env in var.environments : env => env } : {}
  name                = "${var.github_organisation_target}-${github_repository.example.name}-${each.value}"
  resource_group_name = azurerm_resource_group.identity.name
  audience            = [local.default_audience_name]
  issuer              = local.github_issuer_url
  parent_id           = azurerm_user_assigned_identity.example[each.value].id
  subject             = "repo:${var.github_organisation_target}/${github_repository.example.name}:environment:${each.value}"
}