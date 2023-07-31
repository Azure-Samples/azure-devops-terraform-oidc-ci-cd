resource "azurerm_storage_account" "example" {
  name                     = "${lower(replace(var.prefix, "-", ""))}tfstate"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "example" {
  for_each              = { for env in var.environments : env => env }
  name                  = each.value
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_role_assignment" "storage_container" {
  for_each             = { for env in var.environments : env => env }
  scope                = azurerm_storage_container.example[each.value].resource_manager_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = local.security_option.oidc_with_user_assigned_managed_identity || local.security_option.self_hosted_agents_with_managed_identity ? azurerm_user_assigned_identity.example[each.value].principal_id : azuread_service_principal.github_oidc[each.value].id
}