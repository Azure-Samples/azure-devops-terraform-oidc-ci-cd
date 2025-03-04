locals {
  resource_groups = merge({
    state = {
      name = local.resource_names.resource_group_state_name
    }
    identity = {
      name = local.resource_names.resource_group_identity_name
    }
    }, var.use_self_hosted_agents ? {
    agents = {
      name = local.resource_names.resource_group_agents_name
    }
  } : {})

  resource_groups_environments = { for env_key, env_value in local.environments : env_key => {
    name = env_value.resource_group_name
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Reader"
        principal_id               = module.user_assigned_managed_identity["${env_key}-plan"].principal_id
      }
      contributor = {
        role_definition_id_or_name = "Contributor"
        principal_id               = module.user_assigned_managed_identity["${env_key}-apply"].principal_id
      }
    }
    }
  }
}

module "resource_group" {
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "0.2.1"
  for_each = local.resource_groups
  location = var.location
  name     = each.value.name
}

module "resource_group_environments" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "0.2.1"
  for_each         = local.resource_groups_environments
  location         = var.location
  name             = each.value.name
  role_assignments = each.value.role_assignments
}
