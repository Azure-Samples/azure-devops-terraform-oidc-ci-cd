---
page_type: sample
languages:
- terraform
- hcl
- yaml
name: Using GitHub Actions OpenID Connect (OIDC) with Azure for Terraform Deployments
description: A sample showing how to configure GitHub OpenID Connect (OIDC) connection to Azure with Terraform and then use that configuration to deploy resources with Terraform.
products:
- azure
- github
urlFragment: github-terraform-oidc-ci-cd
---

# Using OIDC to Authenticate from GitHub Actions to Azure for Terraform Deployments

This is a two part sample. The first part demonstrates how to configure Azure and GitHub for OIDC ready for Terraform deployments. The second part demonstrates an end to end Continuous Delivery Pipeline for Terraform.

## Content

| File/folder | Description |
|-------------|-------------|
| `terraform-example-deploy`       | Some Terraform with Azure Resources for the demo to deploy. |
| `terraform-oidc-config` | The Terraform to configure Azure and GitHub ready for OIDC authenticaton. |
| `.gitignore` | Define what to ignore at commit time. |
| `CHANGELOG.md` | List of changes to the sample. |
| `CONTRIBUTING.md` | Guidelines for contributing to the sample. |
| `README.md` | This README file. |
| `LICENSE.md` | The license for the sample. |

## Features

This sample includes the following features:

* Option 1: Setup 3 Azure User Assigned Managed Identities with Federation ready for GitHub OIDC.
* Option 2: Setup 3 Azure App Registrations (Service Principals) with Federation ready for GitHub OIDC.
* Setup an Azure Storage Account for State file management.
* Setup GitHub repository and environments ready to deploy Terraform with OIDC.
* Run a Continuous Delivery pipeline for Terraform using OIDC auth for state and deploying resources to Azure.
* Run a Pull Request workflow with some basic static analysis.

### Service Principal or Managed Identity

There are two approaches shown in the code for federating GitHub and Azure. The preferred method is to use a User Assigned Managed Identity since this does not require elevated permissions in Azure Active Directory and has a longer token timeout. However the code also shows the Service Principal approach for those that prefer that method. If you choose the Service Principal approach then the account creating the infrastructure will need permission to create Applications in Azure Active Directory.

## Getting Started

### Prerequisites

- HashiCorp Terraform CLI: [Download](https://www.terraform.io/downloads)
- Azure CLI: [Download](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli#install-or-update)
- An Azure Subscription: [Free Account](https://azure.microsoft.com/en-gb/free/search/)
- A GitHub Organization: [Free Organization](https://github.com/organizations/plan)

### Installation

- Clone the repository locally and then follow the Demo / Lab.

### Quickstart

The instructions for this sample are in the form of a Lab. Follow along with them to get up and running.

## Demo / Lab

### Generate a PAT (Personal Access Token) in GitHub

1. Navigate to [github.com](https://github.com).
1. Login and select the account icon in the top right and then `Settings`.
1. Click `Developer settings`.
1. Click `Personal access tokens` and select `Tokens (classic)`.
1. Click `Generate new token` and select the `classic` option.
1. Type `Demo_OIDC` into the `Note` field.
1. Check these scopes:
   1. `repo`
   1. `delete_repo`
1. Click `Generate token`
1. > IMPORTANT: Copy the token and save it somewhere.

### Clone the repo and setup your variables

1. Clone this repository to your local machine.
1. Open the repo in Visual Studio Code. (Hint: In a terminal you can open Visual Studio Code by navigating to the folder and running `code .`).
1. Navigate to the `terraform-oidc-config` folder and create a new file called `terraform.tfvars`.
1. In the config file add the following:
``` 
prefix = "<your_initials>-<date_as_YYYYMMDD>"
github_organisation_target = "<your_github_organisation_name>"
```
e.g.
```
prefix = "JFH-20221208"
github_organisation_target = "my-organization"
```

> NOTE if you wish to use the Azure Active Directory Service Principal approach rather than a User Assigned Managed Identity, then also add this setting to `terraform.tfvars`:

```
use_managed_identity = false
```

### Apply the Terraform

1. Open the Visual Studio Code Terminal and navigate the `terraform-oidc-config` folder.
1. Run `az login` and follow the prompts to login to Azure with your Global Administrator account.
1. Run `terraform apply`.
1. You'll be prompted for the variable `var.github_token`. Paste in the PAT you generated earlier and hit enter.
1. The plan will complete. Review the plan and see what is going to be created.
1. Type `yes` and hit enter once you have reviewed the plan.
1. Wait for the apply to complete.

> NOTE: If you are a Microsoft employee you may get a 403 error here. If so, you need to grant your PAT SSO access to the Azure-Samples organisation. This does not affect non-Microsoft users.

### Check what has been created

#### Managed Identity or Service Principal

When deploying the example you will have selected to use the default Managed Identity approach or the Service Principal approach choose the relevant option below.

##### Option 1: Managed Identity

1. Login to the [Azure Portal](https://portal.azure.com) with your Global Administrator account.
1. Navigate to your Subscription and select `Resource groups`.
1. Click the resource group post-fixed `identity` (e.g. `JFH-20221208-dev`).
1. Look for a `Managed Identity` resource post-fixed with `dev` and click it.
1. Click on `Federated Credentials`.
1. There should only be one credential in the list, select that and take a look at the configuration.
1. Examine the `Subject identifier` and ensure you understand how it is built up.

##### Option 2: Service Principal

1. Login to the [Azure Portal](https://portal.azure.com) with your Global Administrator account.
1. Navigate to `Azure Active Directory` and select `App registrations`.
1. Select `All applications`, then find the one you just created post-fixed with `dev` (e.g. `JFH-20221208-dev`).
1. Select `Certificate & secrets`, then `Federated credentials`.
1. There should only be one credential in the list, select that and take a look at the configuration.
1. Examine the `Subject identifier` and ensure you understand how it is built up.

#### Resource Group and permissions

1. Navigate to your Subscription and select `Resource groups`.
1. You should see four newly created resource groups.
1. Click the resource group post-fixed `dev` (e.g. `JFH-20221208-dev`).
1. Select `Access control (IAM)` and select `Role assignments`.
1. Under the `Contributor` role, you should see that your `dev` Service Principal has been granted access directly to the resource group.

#### State storage account

1. Navigate to your Subscription and select `Resource groups`.
1. Click the resource group post-fixed `state` (e.g. `JFH-20221208-dev`).
1. You should see a single storage account in there, click on it.
1. Select `Containers`. You should see a `dev`, `test` and `prod` container.
1. Select the `dev` container.
1. Click `Access Control (IAM)` and select `Role assignments`.
1. Scroll down to `Storage Blob Data Contributor`. You should see your `dev` Service Principal has been assigned that role.

#### GitHub environments

1. Open github.com (login if you need to).
1. Navigate to your organisation and select `Repositories`.
1. You should see a newly created repository in there (e.g. `JFH-20221208-wild-dog`). Click on it.
1. You should see some files under source control.
1. Navigate to `Settings`, then select `Environments`.
1. You should see 3 environments called `dev`, `test` and `prod`.
1. Click on the `dev` environment.
1. You should see that the environment has 7 Environment secrets. These secrets are all used in the Action for deploying Terraform.

#### GitHub Action

1. Navigate to `Code`.
1. Select `.github`, `workflows` and open the `main.yml` file.
1. Examine the file and ensure you understand all the steps in there.

### Run the Action

1. Select `Actions`, then click on the `Run Terraform with OpenID Connect` action in the left menu.
1. Click the `Run workflow` drop-down and hit the `Run workflow` button.
1. Wait for the run to appear or refresh the screen, then click on the run to see the details.
1. You will see each environment being deployed one after the other. In a real world scenarios you may want to have a manual intervention on the environment for an approval to promote to the next stage.
1. You will also note that the `Analyse the Terraform` step was skipped.
1. Drill into the log for one of the environments and look at the `Terraform Apply` step. You should see the output of the plan and apply.
1. Run the workflow again and take a look at the log to compare what happens on the Day 2 run.

### Submit a PR
1. Clone your new repository and open it in Visual Studio Code.
1. Create a new branch, call it whatever you want.
1. Open the `terraform-example-deploy/virtual-machine.tf` file.
1. Rename the virtual machine to `example-machine-pr`.
1. Commit and push the change.
1. Raise a pull request.
1. You'll see the GitHub Action running in the pull request.
1. The `Terraform Fmt` step will fail for `main.tf`. Fix it, commit and push your change.
1. Wait for the Action to run again.
1. Look for the Pull Request comment that was added for the plan. Expand the `Show Plan` section and review.
1. Merge the Pull Request.
1. Navigate to `Actions` and watch the run.

## Resources

- [Automate Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [Terraform azurerm provider OIDC configuration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)
- [GitHub OIDC Docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers)
- [Azure External Identity Docs](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp)
