locals {
  address_space_split           = split("/", var.address_space)
  address_space_start_ip        = local.address_space_split[0]
  address_space_size            = tonumber(local.address_space_split[1])
  order_by_size                 = { for key, value in var.subnets_and_sizes : "${format("%03s", value)}||${key}" => value }
  virtual_network_address_space = "${local.address_space_start_ip}/${local.address_space_size}"
  subnet_keys                   = keys(local.order_by_size)
  subnet_new_bits               = [for size in values(local.order_by_size) : size - local.address_space_size]
  cidr_subnets                  = cidrsubnets(local.virtual_network_address_space, local.subnet_new_bits...)
  subnets                       = { for key, value in local.order_by_size : split("||", key)[1] => local.cidr_subnets[index(local.subnet_keys, key)] }

  subnet_delegation_type = var.self_hosted_agent_type == "azure_container_app" ? "Microsoft.App/environments" : "Microsoft.ContainerInstance/containerGroups"
  subnet_delegations = { for key, value in var.subnets_and_sizes : key => key == "agents" ? [
    {
      name = local.subnet_delegation_type
      service_delegation = {
        name = local.subnet_delegation_type
      }
    }
  ] : [] }
}

module "virtual_network" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.8.1"
  count               = var.use_self_hosted_agents ? 1 : 0
  name                = local.virtual_network_name
  location            = var.location
  resource_group_name = module.resource_group["agents"].name
  address_space       = [var.address_space]
  subnets = { for subnet_key, subnet_address_space in local.subnets : subnet_key => {
    name             = subnet_key
    address_prefixes = [subnet_address_space]
    delegation       = local.subnet_delegations[subnet_key]
  } }
}
