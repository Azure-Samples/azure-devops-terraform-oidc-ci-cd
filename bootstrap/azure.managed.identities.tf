module "user_assigned_managed_identity" {
  source           = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version          = "0.3.3"
  enable_telemetry = false

  for_each            = local.environment_split
  location            = var.location
  name                = each.value.user_assigned_managed_identity_name
  resource_group_name = module.resource_group["identity"].name
}

resource "azurerm_federated_identity_credential" "this" {
  for_each            = local.environment_split
  parent_id           = module.user_assigned_managed_identity[each.key].resource_id
  name                = "${var.organization_name}-${local.azure_devops_project_name}-${each.key}"
  resource_group_name = module.resource_group["identity"].name
  audience            = [local.default_audience_name]
  issuer              = azuredevops_serviceendpoint_azurerm.this[each.key].workload_identity_federation_issuer
  subject             = azuredevops_serviceendpoint_azurerm.this[each.key].workload_identity_federation_subject
}
