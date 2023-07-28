locals {
  azure_devops_organization_id = [for a in jsondecode(data.http.azdo_organizations.response_body).value : a.accountId if a.accountName == var.azure_devops_organisation_target][0]
}

data "http" "azdo_member" {
  url = "https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=7.1-preview.1"

  request_headers = {
    Accept        = "application/json"
    Authorization = "Bearer ${var.azure_devops_token}"
  }

  lifecycle {
    postcondition {
      condition     = tonumber(self.status_code) < 300
      error_message = "Could not retrieve member information"
    }
  }
}

data "http" "azdo_organizations" {
  url = "https://app.vssps.visualstudio.com/_apis/accounts?api-version=7.1-preview.1&memberId=${jsondecode(data.http.azdo_member.response_body).id}"
  request_headers = {
    Accept        = "application/json"
    Authorization = "Bearer ${var.azure_devops_token}"
  }

  lifecycle {
    postcondition {
      condition     = tonumber(self.status_code) < 300
      error_message = "Could not retrieve account information"
    }
  }
}