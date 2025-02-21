# NOTE: We are only applying this network rule to the storage account for demo purposes, this is not recommended for production scenarios
resource "azurerm_storage_account_network_rules" "this" {
  count              = var.use_self_hosted_agents ? 1 : 0
  storage_account_id = module.storage_account.resource_id
  default_action     = "Deny"
  ip_rules           = [local.my_cidr_slash_24]
  bypass             = ["None"]
}

# NOTE: We are only applying this role assignment to the storage account for demo purposes, this is not recommended for production scenarios
resource "azurerm_role_assignment" "storage_owner" {
  scope                = module.storage_account.resource_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}
