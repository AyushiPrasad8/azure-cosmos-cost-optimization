variable "resource_group_name" {
  default = "billing-rg"
}

variable "location" {
  default = "East US"
}

variable "storage_account_name" {
  default = "billingarchivestorage"
}

variable "cosmos_account_name" {
  default = "billingcosmosaccount"
}

variable "cosmos_database_name" {
  default = "billing-db"
}

variable "cosmos_container_name" {
  default = "billing-container"
}

variable "function_app_name" {
  default = "billing-archive-fn"
}
