variable "rg_name" {
    type        = string
    description = "The name of the Resource Group"
}

variable "location" {
    type        = string
    description = "The location of the Resource Group"
}

variable "app_service_plan_name" {
    type        = string
    description = "The name of the App Service Plan"
}

variable "storage_account_name" {
    type        = string
    description = "The name of the storage account"
}

variable "storage_container_name" {
    type        = string
    description = "The name of the storage container"
}


variable "function_app_name" {
  type = string
  description = "The name of the function app"
}

variable "function_app_zip_filename" {
  type = string
  description = "Filename of the function's zip"
}
