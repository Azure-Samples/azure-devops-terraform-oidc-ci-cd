module "virtual_network" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.8.1"
  count               = var.use_self_hosted_agents ? 1 : 0
  name                = local.virtual_network_name
  location            = var.location
  resource_group_name = module.resource_group["state"].name
  address_space       = [var.address_space]
  subnets = { for subnet_key, subnet_address_space in local.subnets : subnet_key => {
    name             = subnet_key
    address_prefixes = [subnet_address_space]
  } }
}
