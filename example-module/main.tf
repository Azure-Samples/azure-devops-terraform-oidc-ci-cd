module "resource_group" {
  count    = var.resource_group_create ? 1 : 0
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "0.2.1"
  location = var.location
  name     = local.resource_names.resource_group_name
  tags     = var.tags
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  resource_group_name = local.resource_group_name
  location = var.location
  name                = local.resource_names.virtual_network_name
  subnets             = var.virtual_network_subnets
  address_space       = var.virtual_network_address_space
  tags                = var.tags
}

module "virtual_machine" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.18.1"

  resource_group_name        = local.resource_group_name
  os_type                    = "linux"
  name                       = local.resource_names.virtual_machine_name
  sku_size                   = var.virtual_machine_sku
  location                   = var.location
  zone                       = "1"
  encryption_at_host_enabled = false

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  network_interfaces = {
    private = {
      name = local.resource_names.network_interface_name
      ip_configurations = {
        private = {
          name                          = local.resource_names.network_interface_name
          private_ip_subnet_resource_id = module.virtual_network.subnets["example"].resource_id
        }
      }
    }
  }

  tags = var.tags
}
