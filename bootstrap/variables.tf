variable "postfix" {
  type = string
}

variable "location" {
  type    = string
  default = "UK South"
}

variable "azure_devops_token" {
  type      = string
  sensitive = true
}

variable "azure_devops_organization_prefix" {
  type    = string
  default = "https://dev.azure.com"
}

variable "azure_devops_organization" {
  type = string
}

variable "azure_devops_project" {
  type = string
}

variable "azure_devops_create_project" {
  type    = bool
  default = true
}

variable "use_self_hosted_agents" {
  type    = bool
  default = true
}

variable "environments" {
  type = map(object({
    display_name          = string
    has_approval          = optional(bool, false)
    dependent_environment = optional(string, "")
  }))
  default = {
    dev = {
      display_name = "Development"
    }
    test = {
      display_name          = "Test"
      dependent_environment = "dev"
    }
    prod = {
      display_name          = "Production"
      has_approval          = true
      dependent_environment = "test"
    }
  }
}

variable "address_space" {
  type        = string
  description = "The virtual network address space"
  default     = "10.0.0.0/24"
}

variable "subnets_and_sizes" {
  type        = map(number)
  description = "The size of the subnets"
  default = {
    agents = 26
  }
}

variable "approvers" {
  type    = map(string)
  default = {}
}