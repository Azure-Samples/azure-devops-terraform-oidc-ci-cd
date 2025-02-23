module "private_dns_zone_storage_account" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.3.2"

  count = var.use_self_hosted_agents ? 1 : 0

  resource_group_name = module.resource_group["state"].name
  domain_name         = "privatelink.blob.core.windows.net"

  virtual_network_links = {
    vnet_link = {
      vnetlinkname = "storage-account"
      vnetid       = module.virtual_network[0].resource_id
    }
  }
}

module "storage_account" {
  source                        = "Azure/avm-res-storage-storageaccount/azurerm"
  version                       = "0.5.0"
  name                          = local.storage_account_name
  location                      = var.location
  resource_group_name           = module.resource_group["state"].name
  account_tier                  = "Standard"
  account_replication_type      = "ZRS"
  public_network_access_enabled = !var.use_self_hosted_agents

  containers = { for env_key, env_value in var.environments : env_key => {
    name          = env_key
    public_access = "None"
    role_assignments = {
      user_assignment_managed_identity-plan = {
        role_definition_id_or_name = "Storage Blob Data Owner"
        principal_id               = module.user_assigned_managed_identity["${env_key}-plan"].principal_id
      }
      user_assignment_managed_identity-apply = {
        role_definition_id_or_name = "Storage Blob Data Owner"
        principal_id               = module.user_assigned_managed_identity["${env_key}-apply"].principal_id
      }
    }
    }
  }

  private_endpoints_manage_dns_zone_group = true
  private_endpoints = var.use_self_hosted_agents ? { blob = {
    name                          = "pe-blob-${var.postfix}"
    subnet_resource_id            = module.virtual_network[0].subnets["private_endpoints"].resource_id
    subresource_name              = "blob"
    private_dns_zone_resource_ids = [module.private_dns_zone_storage_account[0].resource_id]
    }
  } : {}
}
