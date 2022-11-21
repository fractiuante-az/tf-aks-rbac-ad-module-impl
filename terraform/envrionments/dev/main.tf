terraform {
  required_version = "1.3.5"
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> v3.32.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> v2.30.0"
    }
  }
}
provider "azurerm" {
  features {}
}

provider "azuread" {
}

data "azuread_user" "aad" {
  user_principal_name = var.admin_upn
}

resource "azuread_group" "k8sadmins" {
  display_name     = "Kubernetes Admins"
  security_enabled = true
  members = [
    data.azuread_user.aad.object_id,
  ]
}

module "rg" {
  source  = "bcochofel/resource-group/azurerm"
  version = "1.4.0"

  name     = "rg-aks-aad-example"
  location = "North Europe"
}

module "aks" {
  source = "../../modules/aks/"

  name                = "aksaadexample"
  resource_group_name = module.rg.name
  dns_prefix          = "demolab"

  default_pool_name = "default"

  enable_azure_active_directory   = true
  rbac_aad_managed                = true
  rbac_aad_admin_group_object_ids = [azuread_group.k8sadmins.object_id]

  depends_on = [module.rg]
}
