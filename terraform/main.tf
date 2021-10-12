terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.77.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
    name = var.rg_name
    location = var.location
}

resource "azurerm_app_service_plan" "asp" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_storage_account" "storage_account" {
    name                        = var.storage_account_name
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = azurerm_resource_group.rg.location
    account_tier                = "Standard"
    account_replication_type    = "GRS"
}

resource "azurerm_storage_container" "storage_container_deploy" {
    name                 = var.storage_container_name
    storage_account_name = azurerm_storage_account.storage_account.name
}

resource "azurerm_storage_blob" "storage_blob" {
  name = "${filesha256(var.function_app_zip_filename)}.zip"
  storage_account_name = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_deploy.name
  type = "Block"
  source = var.function_app_zip_filename
}

data "azurerm_storage_account_blob_container_sas" "storage_account_deploy_container_sas" {
  connection_string = azurerm_storage_account.storage_account.primary_connection_string
  container_name    = azurerm_storage_container.storage_container_deploy.name

  start = "2021-01-01T00:00:00Z"
  expiry = "2022-01-01T00:00:00Z"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

resource "azurerm_function_app" "function" {

  name                = var.function_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "linux"
  app_service_plan_id = azurerm_app_service_plan.asp.id
  version             = "~3"
  https_only          = true

  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key

    app_settings = {
        "WEBSITE_RUN_FROM_PACKAGE" = "https://${azurerm_storage_account.storage_account.name}.blob.core.windows.net/${azurerm_storage_container.storage_container_deploy.name}/${azurerm_storage_blob.storage_blob.name}${data.azurerm_storage_account_blob_container_sas.storage_account_deploy_container_sas.sas}"
    }

  site_config {
    linux_fx_version          = "PYTHON|3.9"
    use_32_bit_worker_process = false
    always_on                 = true
  }
}
