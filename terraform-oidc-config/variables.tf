variable "prefix" {
  type    = string
  default = "github-oidc-demo"
}

variable "location" {
  type    = string
  default = "UK South"
}

variable "azure_devops_token" {
  type      = string
  sensitive = true
}

variable "azure_devops_organisation_target" {
  type    = string
  default = "my_organisation"
}

variable "azure_devops_project_target" {
  type    = string
  default = "my_project"
}

variable "github_organisation_template" {
  type    = string
  default = "Azure-Samples"
}

variable "github_repository_template" {
  type    = string
  default = "azure-devops-terraform-oidc-ci-cd"
}

variable "environments" {
  type    = list(string)
  default = ["dev", "test", "prod"]
}

variable "use_managed_identity" {
  type    = bool
  default = true
  description = "If selected, this option will create and configure a user assigned managed identity in the subscription instead of an AzureAD service principal."
}