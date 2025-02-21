module "user_assigned_managed_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.3"

  for_each            = local.environment_split
  location            = var.location
  name                = "uami-${var.postfix}-${each.value.environment}-${each.value.type}"
  resource_group_name = module.resource_group["identity"].name
}

resource "azurerm_federated_identity_credential" "this" {
  for_each            = local.environment_split
  parent_id           = module.user_assigned_managed_identity[each.key].resource_id
  name                = "${var.azure_devops_organization}-${var.azure_devops_project}-${each.key}"
  resource_group_name = module.resource_group["identity"].name
  audience            = [local.default_audience_name]
  issuer              = azuredevops_serviceendpoint_azurerm.this[each.key].workload_identity_federation_issuer
  subject             = azuredevops_serviceendpoint_azurerm.this[each.key].workload_identity_federation_subject
}
