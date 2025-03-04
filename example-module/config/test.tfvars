location                      = "uksouth"
resource_name_workload        = "demo"
resource_name_environment     = "test"
virtual_network_address_space = ["10.1.0.0/16"]
virtual_network_subnets = {
  example = {
    name             = "example"
    address_prefixes = ["10.1.0.0/24"]
  }
}
virtual_machine_sku = "Standard_B1ls"
tags = {
  deployed_by = "terraform"
  environment = "test"
}
