location                      = "uksouth"
resource_name_workload        = "demo"
resource_name_environment     = "dev"
virtual_network_address_space = ["10.0.0.0/16"]
virtual_network_subnets = {
  example = {
    name             = "example"
    address_prefixes = ["10.0.0.0/24"]
  }
}
virtual_machine_sku = "Standard_B1ls"
tags = {
  deployed_by = "terraform"
  environment = "dev"
}
